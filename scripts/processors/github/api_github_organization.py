import argparse
import datetime
import dotenv
import glob
import json
import logging
import logging.config
import os
import requests
import requests.exceptions
import sys
import urllib.parse
from time import sleep, time


LOG_FUNCTIONS = {
    "INFO": logging.info,
    "WARNING": logging.warning,
    "ERROR": logging.error,
    "DEBUG": logging.debug,
}


def load_environment_variables(folder=os.getenv("SECRETS_FINDER_SCAN_FOLDER")):
    if not folder:
        dotenv.load_dotenv(override=True)
    else:
        dotenv_files = glob.glob(os.path.join(folder, "*.env"))
        for file in dotenv_files:
            if os.path.isfile(file):
                dotenv.load_dotenv(dotenv_path=file, override=True)


def positive_int(value):
    ivalue = int(value)
    if ivalue <= 0:
        raise argparse.ArgumentTypeError(f"{value} is an invalid positive int value")
    return ivalue


def non_empty_string(value):
    svalue = str(value)
    if svalue == "":
        raise argparse.ArgumentTypeError("value cannot be an empty string")
    return svalue


# This validation is used to reject common malformed URLs. It does not aim to strictly validate URLs.
# More information: https://docs.python.org/3/library/urllib.parse.html#url-parsing-security
def valid_uri(value):
    try:
        result = urllib.parse.urlparse(value)
        return value if all([result.scheme, result.netloc]) else None
    except ValueError:
        pass
    raise argparse.ArgumentTypeError(f"Invalid URI: {value}")


def configure_parser():
    parser = argparse.ArgumentParser(
        prog="github-organization-processor",
        description="This script fetches all the repositories of a GitHub organization using the standard GitHub API. This script supports both GitHub Enterprise Cloud and GitHub Enterprise Server.",
        epilog="This script has been developed by Thomson Reuters. For issues, comments or help, you can contact the maintainers on the official GitHub repository: https://github.com/thomsonreuters/secrets-finder",
    )

    parser.add_argument(
        "--debug",
        action="store_true",
        help="show debug information",
        default=os.environ.get("GITHUB_ORGANIZATION_PROCESSOR_DEBUG", False),
    )
    parser.add_argument(
        "--api",
        help="base URL of the API",
        type=valid_uri,
        default=os.environ.get(
            "GITHUB_ORGANIZATION_PROCESSOR_API", "https://api.github.com"
        ),
    )
    parser.add_argument(
        "--clone-url-template",
        help="template for the clone URL",
        type=non_empty_string,
        default=os.environ.get(
            "GITHUB_ORGANIZATION_PROCESSOR_CLONE_URL_TEMPLATE",
            "https://github.com/{organization}/{repository}",
        ),
    )
    parser.add_argument(
        "--organization",
        help="GitHub organization for which repositories should be fetched",
        type=non_empty_string,
        required=os.environ.get("GITHUB_ORGANIZATION_PROCESSOR_ORGANIZATION") is None,
        default=os.environ.get("GITHUB_ORGANIZATION_PROCESSOR_ORGANIZATION"),
    )
    parser.add_argument(
        "--max-retries",
        help="maximum number of retries for rate limiting",
        type=positive_int,
        default=os.environ.get("GITHUB_ORGANIZATION_PROCESSOR_MAX_RETRIES", 10),
    )
    parser.add_argument(
        "--backoff-factor",
        help="backoff factor for rate limiting",
        type=positive_int,
        default=os.environ.get("GITHUB_ORGANIZATION_PROCESSOR_BACKOFF_FACTOR", 1),
    )

    return parser


def configure_logging(destination_folder, level=logging.INFO):
    log_file = "github-organization-processor.log"
    logging.config.dictConfig({"version": 1, "disable_existing_loggers": True})
    logging.basicConfig(
        format="%(message)s", filename=f"{destination_folder}/{log_file}", level=level
    )


def log(level, context, message):
    current_time = str(datetime.datetime.now())

    log_string = json.dumps(
        {"time": current_time, "level": level, "context": context, "message": message},
        separators=(",", ":"),
    )

    return LOG_FUNCTIONS[level]("%s", log_string)


class MaxRetriesExceededError(Exception):
    """Exception raised when the maximum number of retries is exceeded."""

    pass


class GitHubClient:
    def __init__(self, api, token, max_retries=10, backoff_factor=1):
        log("INFO", "GITHUB-ORGANIZATION-PROCESSOR", "Configuring GitHub client...")

        self.api = api
        self.token = token
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "Accept: application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor

        log(
            "INFO",
            "GITHUB-ORGANIZATION-PROCESSOR",
            f"GitHub client configured successfully for API: {api}",
        )
        log(
            "DEBUG",
            "GITHUB-ORGANIZATION-PROCESSOR",
            f"GitHub client configured with token starting with: {token[:8]}",
        )

    def make_api_request(self, method, url, **kwargs):
        valid_methods = ["GET", "OPTIONS", "HEAD", "POST", "PUT", "PATCH", "DELETE"]
        if method not in valid_methods:
            raise ValueError(
                f"Invalid HTTP method: {method}. Must be one of {valid_methods}."
            )

        max_retries = self.max_retries
        backoff_factor = self.backoff_factor
        rate_limit_retry_count = 0

        while True:
            try:
                log("DEBUG", "GITHUB-CLIENT", f"{method} request to {url}")
                response = requests.request(method, url, headers=self.headers, **kwargs)

                if 200 <= response.status_code < 300:
                    log(
                        "DEBUG",
                        "GITHUB-CLIENT",
                        f"Status code returned by {url}: {response.status_code}",
                    )
                    log(
                        "DEBUG",
                        "GITHUB-CLIENT",
                        f"Response returned by {url}: {response.json()}",
                    )
                    return response
                elif (
                    response.status_code == 403
                    and "X-RateLimit-Reset" in response.headers
                ):
                    if rate_limit_retry_count >= max_retries:
                        raise MaxRetriesExceededError(
                            f"Rate limit retry count exceeded for {url}"
                        )

                    reset_timestamp = int(response.headers["X-RateLimit-Reset"])
                    current_timestamp = int(time())

                    if reset_timestamp <= current_timestamp:
                        continue

                    sleep_time = reset_timestamp - current_timestamp + 1
                    log(
                        "WARNING",
                        "GITHUB-CLIENT",
                        f"Rate limit hit. Sleeping for {sleep_time} seconds.",
                    )
                    sleep(sleep_time)
                    rate_limit_retry_count += 1
                elif response.status_code == 429:
                    if rate_limit_retry_count >= max_retries:
                        raise MaxRetriesExceededError(
                            f"Rate limit retry count exceeded for {url}"
                        )

                    sleep_time = backoff_factor
                    log(
                        "WARNING",
                        "GITHUB-CLIENT",
                        f"Too many requests. Sleeping for {sleep_time} seconds.",
                    )
                    sleep(sleep_time)
                    backoff_factor *= 2
                    rate_limit_retry_count += 1
                else:
                    response.raise_for_status()

            except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
                log(
                    "WARNING",
                    "GITHUB-CLIENT",
                    "Request timed out or connection error occurred. Waiting to retry...",
                )
                sleep(10)
            except requests.exceptions.RequestException as e:
                log(
                    "DEBUG",
                    "GITHUB-CLIENT",
                    f"An error occurred while executing a {method} request to {url}: {e}",
                    custom_color="red",
                )
                raise e

    def get_repositories(self, organization):
        url = f"{self.api}/orgs/{organization}/repos"
        repositories = []
        while url:
            response = self.make_api_request(method="GET", url=url)
            repositories.extend(response.json())
            url = response.links.get("next", {}).get("url")

        log(
            "DEBUG",
            "GITHUB-CLIENT",
            f"Number of repositories found for organization {organization}: {len(repositories)}",
        )
        return repositories


def persist_repositories_information(
    organization,
    repositories,
    location=os.environ.get("SECRETS_FINDER_SCAN_FOLDER", "."),
    filename="repositories.json",
):
    log(
        "INFO",
        "GITHUB-ORGANIZATION-PROCESSOR",
        f"Persisting list of repositories for organization {organization} to: {location}/{filename}",
    )

    formatted_list_of_repositories = {
        "organization": organization,
        "repositories": repositories,
    }

    with open(f"{location}/{filename}", "w") as file:
        json.dump(formatted_list_of_repositories, file, indent=4)

    log(
        "INFO",
        "GITHUB-ORGANIZATION-PROCESSOR",
        f"List of repositories for organization {organization} persisted successfully to: {location}/{filename}",
    )


def persist_repositories_for_scan(
    organization,
    repositories,
    clone_url_template,
    location=os.environ.get("SECRETS_FINDER_SCAN_FOLDER", "."),
    filename="repositories_to_scan.json",
):
    log(
        "INFO",
        "GITHUB-ORGANIZATION-PROCESSOR",
        f"Persisting list of repositories for organization {organization} to: {location}/{filename}",
    )

    formatted_list_of_repositories = {
        "scm": "github",
        "endpoint": clone_url_template,
        "repositories": [],
    }

    for repository in repositories:
        formatted_list_of_repositories.get("repositories").append(
            {"organization": organization, "name": repository.get("name")}
        )

    with open(f"{location}/{filename}", "w") as file:
        json.dump(formatted_list_of_repositories, file, indent=4)

    log(
        "INFO",
        "GITHUB-ORGANIZATION-PROCESSOR",
        f"List of repositories for organization {organization} persisted successfully to: {location}/{filename}",
    )


def main():
    try:
        load_environment_variables()
        parser = configure_parser()
        arguments = parser.parse_args()
        configure_logging(".", logging.INFO if not arguments.debug else logging.DEBUG)
    except Exception as exception:
        print(
            f"FATAL ERROR: An unexpected error occurred during initialization: {str(exception)}"
        )
        sys.exit(1)

    try:
        if not os.environ.get("SECRETS_FINDER_SCAN_TOKEN") and not os.environ.get(
            "GITHUB_TOKEN"
        ):
            log(
                "ERROR",
                "GITHUB-ORGANIZATION-PROCESSOR",
                "No token provided: SECRETS_FINDER_SCAN_TOKEN and GITHUB_TOKEN environment variables are both missing. Operation aborted.",
            )
            sys.exit(1)

        github_client = GitHubClient(
            api=arguments.api,
            token=os.environ.get(
                "SECRETS_FINDER_SCAN_TOKEN", os.environ.get("GITHUB_TOKEN")
            ),
            max_retries=arguments.max_retries,
            backoff_factor=arguments.backoff_factor,
        )
        repositories = github_client.get_repositories(
            organization=arguments.organization
        )
        persist_repositories_information(
            organization=arguments.organization, repositories=repositories
        )
        persist_repositories_for_scan(
            organization=arguments.organization,
            repositories=repositories,
            api=arguments.clone_url_template,
        )

        sys.exit(0)
    except Exception as exception:
        log(
            "ERROR",
            "GITHUB-ORGANIZATION-PROCESSOR",
            f"A fatal error occurred during scan: {str(exception)}. Operation aborted.",
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
