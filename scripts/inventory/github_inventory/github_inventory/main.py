from __future__ import annotations
import argparse
import requests
import json
import time
import sys
import logging
from pathlib import Path
from github_inventory.config import settings
from dynaconf.validator import ValidationError

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("github_inventory.log"), logging.StreamHandler()],
)


# https://docs.github.com/en/rest/rate-limit/rate-limit?apiVersion=2022-11-28
# https://docs.github.com/en/rest/guides/best-practices-for-integrators?apiVersion=2022-11-28#dealing-with-secondary-rate-limits
def handle_rate_limit(session, client_response):
    retry_after = client_response.headers.get("Retry-After")
    rate_limit_remaining = client_response.headers.get("x-ratelimit-remaining")
    rate_limit_type = client_response.headers.get("x-ratelimit-resource")

    if rate_limit_remaining and rate_limit_remaining == 0:
        logging.error(
            "First rate limit hit, waiting for limit reset before continuing."
        )
        response = session.get("https://api.github.com/rate_limit")
        if not (200 <= response.status_code <= 299):
            logging.error("Error occurred while checking rate limit.")
            return None
        rate_limit_details = response.json()["resources"][
            rate_limit_type if rate_limit_type else "graphql"
        ]
        reset_in_minutes = (rate_limit_details["reset"] - int(time.time())) / 60
        logging.info(
            f"Current rate limit of {rate_limit_details['limit']} hit, waiting for limit to expires in {round(reset_in_minutes,0)} minutes."
        )
        while int(time.time()) <= int(client_response.headers.get("x-ratelimit-reset")):
            time.sleep(60)
        return True
    if retry_after:
        logging.error(
            f'Second rate limit hit, waiting {retry_after} seconds before retrying (based on "Retry-After" header).'
        )
        time.sleep(int(retry_after))
        return True
    return False


def run_query(session, query, variables=None, retry_count=5):
    response = session.post(
        "https://api.github.com/graphql", json={"query": query, "variables": variables}
    )
    if not (200 <= response.status_code <= 299):
        if handle_rate_limit(session, response) and retry_count > 0:
            logging.info(
                f"Rate limit hit, retrying request. Retries left: {retry_count - 1}"
            )
            return run_query(session, query, variables, retry_count - 1)
        elif response.status_code in (502, 504) and retry_count > 0:
            logging.error(
                f"GraphQL returned a 502 or 504, this may be caused by a timeout, retrying {retry_count + 1} more times before failing"
            )
            return run_query(session, query, variables, retry_count - 1)
        elif response.status_code in (401, 403):
            logging.error(
                "Unauthorized access, please check your GitHub access token and organization name."
            )
            sys.exit(1)
        else:
            logging.error(
                f"Received HTTP Response Status code {response.status_code} while performing request. Response: {response.text}."
            )
        return None
    json_response = response.json()
    if "errors" in json_response:
        logging.error(
            f"Error occurred while performing request: {json_response['errors']}"
        )
        logging.error(f"Query: {query}")
        logging.error(f"Variables: {variables}")
        return None
    return json_response


def get_repository_details(session, repository, query):
    filter_pr, filter_issues = settings.pr_labels, settings.issues_labels
    # Let's first to try to fetch the repository with 100 pull requests and 100 issues, if there are more we'll handle pagination
    repository_variables = {
        "org": settings.org,
        "repositoryName": repository["name"],
        "pullRequestCursor": "",
        "issueCursor": "",
        "pullRequestStep": 100 if settings.pr else 0,
        "issueStep": 100 if settings.issues else 0,
        "pullRequestsLabel": filter_pr,
        "issuesLabel": filter_issues,
    }
    repository = run_query(session, query, repository_variables)["data"]["repository"]

    pr_page_info = (
        repository["pullRequests"]["pageInfo"]
        if settings.pr
        else {"hasNextPage": False}
    )
    while pr_page_info["hasNextPage"]:
        # We don't want to fetch issues here, so setting issueStep to 0 to reduce the cost of the query by one
        pr_variables = repository_variables.copy()
        pr_variables.update(
            {
                "pullRequestCursor": pr_page_info["endCursor"],
                "pullRequestStep": 100,
                "issueStep": 0,
                "pullRequestsLabel": filter_pr,
                "issuesLabel": "",
            }
        )

        pr_result = run_query(session, query, pr_variables)
        repository["pullRequests"]["nodes"].extend(
            pr_result["data"]["repository"]["pullRequests"]["nodes"]
        )
        pr_page_info = pr_result["data"]["repository"]["pullRequests"]["pageInfo"]

    # Handle pagination for issues
    issue_page_info = (
        repository["issues"]["pageInfo"] if settings.issues else {"hasNextPage": False}
    )
    while issue_page_info["hasNextPage"]:
        # We don't want to fetch pull requests, so in this case we're setting the pullRequestStep to 0
        issues_variables = repository_variables.copy()
        issues_variables.update(
            {
                "issueCursor": issue_page_info["endCursor"],
                "pullRequestStep": 0,
                "issueStep": 100,
                "pullRequestsLabel": "",
                "issuesLabel": filter_issues,
            }
        )
        issue_result = run_query(session, query, issues_variables)
        repository["issues"]["nodes"].extend(
            issue_result["data"]["repository"]["issues"]["nodes"]
        )
        issue_page_info = issue_result["data"]["repository"]["issues"]["pageInfo"]
    yield repository


def get_repositories(session, queries):
    org_cursor = ""
    totalCount = None
    organization_variables = {"org": settings.org, "organizationCursor": org_cursor}
    while True:
        organization_variables.update({"organizationCursor": org_cursor})
        result = run_query(session, queries["org"], organization_variables)
        if not totalCount:
            totalCount = {
                "initialCount": result["data"]["organization"]["repositories"][
                    "totalCount"
                ],
                "currentCount": 0,
            }

        totalCount["currentCount"] += len(
            result["data"]["organization"]["repositories"]["nodes"]
        )

        logging.info(
            f"Progress: {totalCount['currentCount']} / {totalCount['initialCount']} - Total repositories left to fetch: {totalCount['initialCount'] - totalCount['currentCount']}."
        )
        for repository in result["data"]["organization"]["repositories"]["nodes"]:
            if settings.pr or settings.issues:
                yield from get_repository_details(
                    session,
                    repository,
                    queries["repository"],
                )
            else:
                yield repository

        page_info = result["data"]["organization"]["repositories"]["pageInfo"]
        if page_info["hasNextPage"]:
            org_cursor = page_info["endCursor"]
        else:
            break


def clean_up(object):
    result = {}
    for k, v in object.items():
        if isinstance(v, (str, int, bool, list)) or v is None:
            result[k] = v
        elif isinstance(v, dict):
            if "login" in v:
                result[k] = v["login"]
            elif "name" in v:
                result[k] = v["name"]
            elif "edges" in v and v["edges"]:
                result[k] = {
                    "totalCount": v["totalCount"],
                    "totalSize": v["totalSize"],
                    "edges": [
                        {"name": edge["node"]["name"], "size": edge["size"]}
                        for edge in v["edges"]
                    ],
                }
            elif "nodes" in v:

                result[k] = [clean_up(node) for node in v["nodes"]]
        else:
            pass
    return result


def main(argv=None):
    current_script_directory = Path(__file__).parent.__str__() + "/"
    parser = argparse.ArgumentParser(description="GitHub inventory script")

    try:
        parser.add_argument(
            "--env",
            default=settings.get("dotenv_path", ".env"),
            help="Path to .env file",
        )
        parser.add_argument(
            "--org", default=settings.get("org"), help="GitHub organization name"
        )
        parser.add_argument(
            "--pr",
            default=settings.get("pr"),
            action="store_true",
            help="Fetch pull requests",
        )
        parser.add_argument(
            "--issues",
            default=settings.get("issues"),
            action="store_true",
            help="Fetch issues",
        )
        parser.add_argument("--pr-labels", help="Filter pull requests by label")
        parser.add_argument("--issues-labels", help="Filter issues by label")
        parser.add_argument(
            "--gql-query-org",
            default=settings.get(
                "gql_query_org",
                current_script_directory
                + "graphql_queries/organization_repositories.graphql",
            ),
            help="Path to custom GraphQL query for fetching organization repositories",
        )
        parser.add_argument(
            "--gql-query-repo",
            default=settings.get(
                "gql_query_repo",
                current_script_directory + "graphql_queries/repository_details.graphql",
            ),
            help="Path to custom GraphQL query for fetching repository details",
        )
    except argparse.ArgumentError as e:
        logging.error(f"Error occurred while parsing arguments: {e}")
        sys.exit(1)
    except AttributeError as e:
        logging.error(f"Required argument is missing: {e}")
        sys.exit(1)
    options, args = parser.parse_known_args(argv)

    settings.setenv(options.env)
    github_token = settings.token

    # Updates the dynaconfig settings
    try:
        settings.update(vars(options))
    except ValidationError as e:
        logging.error(f"One of the parameters provided is invalid: {e}")
        sys.exit(1)

    queries = {}
    with open(settings.gql_query_org, "r") as f:
        queries["org"] = f.read()
    with open(settings.gql_query_repo, "r") as f:
        queries["repository"] = f.read()

    organization_name = settings.org

    session = requests.Session()
    headers = {
        "Authorization": f"Bearer {github_token}",
        "Content-Type": "application/json",
    }
    session.headers.update(headers)

    inventory = []
    for repo in get_repositories(session, queries):
        repo = clean_up(repo)
        inventory.append(repo)

    session.close()
    with open(f"inventory-{organization_name}.json", "w") as f:
        json.dump(inventory, f, indent=4)
    logging.info(f"Inventory saved to inventory-{organization_name}.json")


if __name__ == "__main__":
    main(argv=None)
