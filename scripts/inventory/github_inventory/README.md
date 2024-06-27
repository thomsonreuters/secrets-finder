# GitHub Inventory

This directory contains scripts for interacting with the GitHub GraphQL API to fetch information about a GitHub organization's repositories, pull requests, and issues, including labels for each issue and pull request. It also allows to filter on the issues and pull requests fetched based on the labels.

The script support configuration, in order of priority through command line arguments, environment variables when prefixed by GITHUB_INVENTORY_<PARAMETER> or through a TOML configuration file.

## Files

- `github_inventory/main.py`: This is the main script. It uses the GitHub GraphQL API to fetch all repositories and optionnally their pull requests, issues, topics and languages for a specified GitHub organization, handling pagination to fetch all results even if there are more than the API's maximum limit per request.

- `.env.example`: This is an example of the .env file that could be used to set up environment variables. This will override manually set environment variables, rename it to .env with your values.

- `settings.toml`: This is a configuration file that can be used to specify the organization to fetch data from, the labels to filter on, and the fields to fetch for each repository, pull request, and issue. The script will use first the command line arguments, then the environment variables, then the values in this file.

- `pyproject.toml`: This is the configuration file for the `poetry` package manager, which is used to manage dependencies for the script.


- `github_inventory/graphql_queries/*`: Contains the GraphQL queries used to fetch the data. These can be copied and modified befgore being passed as a custom gql query.

## Requirements

- Python 3.9 or higher
- [`poetry` package manager](https://python-poetry.org/docs/#installation)

## Dependencies

- dynaconf = "^3.2.5"
- requests = "^2.32.3"
- python-dotenv = "^1.0.1"

## Usage

### Examples

1. To run, setup the two environment variables
```bash
read GITHUB_INVENTORY_TOKEN
<YOUR TOKEN>
export GITHUB_INVENTORY_TOKEN=$GITHUB_INVENTORY_TOKEN
export GITHUB_ORG=<your org> # You can also pass this directly throigh
```

2. Setup the poetry environment
```bash
poetry install
```

3. Run the script with Python:

```bash
poetry run python -m github_inventory
```

OR

```bash
poetry run python -m github_inventory --organization <organization> --issues --pr --issues_labels my-issue-label1 --pr_labels my-pr-label

```

4. The script will write the fetched data to a JSON file `inventory-<organization>.json`.

### Supported parameters

> All parameters are supported as environment variables, the module expects them to be set with the `GITHUB_INVENTORY_` prefix

The following parameters are supported
| Parameter            | CLI                    | settings.toml          | Environment variable               | Default |
|----------------------|------------------------|------------------------|------------------------------------|---------|
| GitHub Organization  | `--org <ORG>`          | org = "<ORG>"        | `GITHUB_INVENTORY_ORG`             | ""    |
| Dot Env file         | `--env <FILE>`         | dotenv_path = "<PATH>" | `GITHUB_INVENTORY_DOTENV_PATH`   | .env  |
| Pull Issues          | `--issues`             | issues = false       | `GITHUB_INVENTORY_ISSUES`          | false |
| Pull PRs             | `--pr`                 | pr = false           | `GITHUB_INVENTORY_PR`              | false |
| Custom Org GQL Query | `--gql-query-org <FILE>` | gql_query_org = ""  | `GITHUB_INVENTORY_GQL_QUERY_ORG`   | ""    |
| Custom Repo GQL Query| `--gql-query-repo <FILE>` | gql_query_repo = "" | `GITHUB_INVENTORY_GQL_QUERY_REPO` | ""    |



# Notes about the current GraphQL queries

We had to compromise on the data we fetch from GitHub to avoid hitting the API rate limit with costly queries. For example, fetching the first 100 repositories of an organization is a cheap query, fetching the first 100 repositories with their issues and pull requests doesn't cost that much either. But the GitHub GraphQL API may take too long to return the data in cases where all the repos had 100 issues and 100 pull requests, and that each had labels.

This is why we decided to fetch only the first 100 repositories of an organization, and then fetch their issues and pull requests through a separate query, doing so also allows to keep the cost of fetching labels for each issue low. Fetching objects that are three level deep causes expensive queries, and sometimes are not allowed as they could result in millions of objects being pulled. For example fetching a 100 repository page at the org level and for each 100 PRs and Issues pages, each with the first 10 assignee and labels costs 404 requests on the rate limit.

For similar reasons, we don't fetch the bodyText of issues and pull requests, as this has resulted in many timeouts or errors on large test organization. While this means that fetching the repositories list, their issues, pull requests, topics, and languages takes a while, it ensures that we stay within the API rate limits and avoid unnecessary delays and errors.

The script is designed to be flexible and configurable to meet the needs of different organizations and use cases. By adjusting the command line arguments, environment variables, or configuration file settings, users can tailor the script to fetch exactly the data they need.
