import argparse
import concurrent.futures
import datetime
import json
import jsonschema
import logging
import logging.config
import os
import sys
import tempfile
import threading
import uuid

import common


def configure_parser():
    parser = argparse.ArgumentParser(
        prog="secrets-finder-scanner",
        description="This script performs secrets detection scanning on source code repositories managed by git.",
        epilog="This script has been developed by Thomson Reuters. For issues, comments or help, you can contact the maintainers on the official GitHub repository: https://github.com/thomsonreuters/secrets-finder",
    )

    parser.add_argument("--debug", action="store_true", help="store debug information")
    parser.add_argument(
        "--scm",
        help="the source code management system to use",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCM") is None,
        choices=["github", "azure_devops", "custom"],
        default=os.environ.get("SECRETS_FINDER_SCM"),
    )
    parser.add_argument(
        "--scan-identifier",
        help="the identifier for the scan",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCAN_IDENTIFIER") is None,
        default=os.environ.get("SECRETS_FINDER_SCAN_IDENTIFIER"),
    )
    parser.add_argument(
        "--scan-uuid",
        help="the UUID associated to the scan",
        type=common.valid_uuid4,
        required=os.environ.get("SECRETS_FINDER_SCAN_UUID") is None,
        default=os.environ.get("SECRETS_FINDER_SCAN_UUID"),
    )
    parser.add_argument(
        "--scan-folder",
        help="the folder dedicated to the scan",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCAN_FOLDER") is None,
        default=os.environ.get("SECRETS_FINDER_SCAN_FOLDER"),
    )
    parser.add_argument(
        "--scanner-folder",
        help="the folder dedicated to the scanner",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCANNER_FOLDER") is None,
        default=os.environ.get("SECRETS_FINDER_SCANNER_FOLDER"),
    )
    parser.add_argument(
        "--trufflehog-installation-path",
        help="the path where trufflehog is installed",
        type=common.non_empty_string,
        default=os.environ.get(
            "SECRETS_FINDER_TRUFFLEHOG_INSTALLATION_PATH", "/usr/bin"
        ),
    )
    parser.add_argument(
        "--trufflehog-executable-name",
        help="the name of the trufflehog executable",
        type=common.non_empty_string,
        default=os.environ.get(
            "SECRETS_FINDER_TRUFFLEHOG_EXECUTABLE_NAME", "trufflehog"
        ),
    )
    parser.add_argument(
        "--report-only-verified",
        action="store_true",
        help="report only verified secrets",
        default=common.str_to_bool(
            os.environ.get("SECRETS_FINDER_REPORT_ONLY_VERIFIED", "false")
        ),
    )
    parser.add_argument(
        "--exit-on-error-pre",
        action="store_true",
        help="exit on error in pre-scan scripts",
        default=os.environ.get("SECRETS_FINDER_EXIT_ON_ERROR_PRE"),
    )
    parser.add_argument(
        "--exit-on-error-post",
        action="store_true",
        help="exit on error in post-scan scripts",
        default=os.environ.get("SECRETS_FINDER_EXIT_ON_ERROR_POST"),
    )

    return parser.parse_args()


class SecretsFinder:
    def __init__(
        self,
        scanner_folder,
        scan_uuid,
        scan_identifier,
        scm,
        scan_configuration_schema_filename="scan-configuration.schema.json",
        trufflehog_installation_path=os.path.join("usr", "bin"),
        trufflehog_executable_name="trufflehog",
        report_only_verified=False,
        concurrency=20,
    ):
        self.scanner_folder = scanner_folder
        self.scan_identifier = scan_identifier
        self.scan_uuid = scan_uuid
        self.scm = scm
        self.scan_results = []
        self.scan_results_lock = threading.Lock()
        self.trufflehog_installation_path = trufflehog_installation_path
        self.trufflehog_executable_name = trufflehog_executable_name
        self.report_only_verified = report_only_verified
        self.concurrency = concurrency
        self.status = "ready"

        scan_configuration_schema_path = os.path.join(
            self.scanner_folder, scan_configuration_schema_filename
        )
        if not os.path.isfile(scan_configuration_schema_path):
            raise FileNotFoundError(
                f"Scan configuration schema not found: {scan_configuration_schema_path}"
            )

        with open(scan_configuration_schema_path, "r") as file:
            self.scan_configuration_schema = json.load(file)

        common.log(
            "INFO", "SECRETS-FINDER (main)", f"Scanner initialized: {scan_identifier}"
        )
        common.log(
            "INFO",
            "SECRETS-FINDER (main)",
            f"Source code management system to scan: {scm}",
        )
        common.log(
            "DEBUG", "SECRETS-FINDER (main)", f"Concurrency level: {concurrency}"
        )
        common.log(
            "DEBUG",
            "SECRETS-FINDER (main)",
            f"Scan configuration schema: {scan_configuration_schema_path}",
        )

    def scan(self):
        try:
            common.log(
                "INFO",
                "SECRETS-FINDER (main)",
                f"Starting scan: {self.scan_identifier}",
            )
            self.local_data = threading.local()
            self.status = "running"
            self.start = datetime.datetime.now().isoformat()
            self._check_for_credentials()
            configuration = self._load_and_validate_configuration(
                configuration_file="repositories_to_scan.json",
                location=self.scanner_folder,
            )
            self._scan_repositories(configuration)
            self.status = "success"
            common.log(
                "INFO",
                "SECRETS-FINDER (main)",
                f"Scan completed: {self.scan_identifier}",
            )
        except Exception as e:
            self.status = "failure"
            common.log(
                "ERROR",
                "SECRETS-FINDER (main)",
                f"Scan failed: {self.scan_identifier}. Error: {str(e)}",
            )
        finally:
            self.end = datetime.datetime.now().isoformat()
            self._save_all_results_to_file(location=self.scanner_folder)

        return self.status

    def _check_for_credentials(self):
        if not os.environ.get("SECRETS_FINDER_SCAN_USERNAME") or not os.environ.get(
            "SECRETS_FINDER_SCAN_TOKEN"
        ):
            raise ValueError(
                "Credentials not found in environment variables: SECRETS_FINDER_SCAN_USERNAME, SECRETS_FINDER_SCAN_TOKEN"
            )

    def _load_and_validate_configuration(self, configuration_file, location):
        try:
            configuration_file_path = os.path.join(location, configuration_file)

            common.log(
                "INFO",
                "SECRETS-FINDER (main)",
                f"Loading and validating configuration file: {configuration_file_path}",
            )
            if not os.path.isfile(configuration_file_path):
                raise FileNotFoundError(
                    f"Configuration file not found: {configuration_file_path}"
                )

            with open(f"{configuration_file_path}", "r") as file:
                configuration = json.load(file)

            jsonschema.validate(
                instance=configuration, schema=self.scan_configuration_schema
            )

            common.log(
                "INFO",
                "SECRETS-FINDER (main)",
                f"Configuration file loaded and validated successfully: {configuration_file_path}",
            )
            return configuration
        except jsonschema.exceptions.ValidationError as validation_error:
            raise ValueError(
                f"Configuration file does not strictly conform to the schema: {str(validation_error)}"
            )
        except Exception:
            raise

    def _scan_repositories(self, configuration):
        endpoint = configuration.get("endpoint")
        repositories = configuration.get("repositories")

        common.log(
            "INFO",
            "SECRETS-FINDER (main)",
            f"Scanning {len(repositories)} repositor{'ies' if len(repositories) > 1 else 'y'} with {self.concurrency} worker{'s' if self.concurrency > 1 else ''}...",
        )
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=self.concurrency
        ) as executor:
            for repository in repositories:
                executor.submit(self._scan_repository, endpoint, repository)
            executor.shutdown(wait=True)
        common.log(
            "INFO", "SECRETS-FINDER (main)", "All repositories scanned successfully."
        )

    def _scan_repository(self, endpoint, repository):
        try:
            self.local_data.execution_id = str(uuid.uuid4())[:8]
            self.local_data.start = datetime.datetime.now().isoformat()
            repository_scan_identifier = common.generate_unique_identifier()
            repository_organization = repository.get("organization")
            repository_name = repository.get("name")

            common.log(
                "INFO",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Scanning repository: {repository_name} (organization: {repository_organization})",
            )

            local_directory = self._clone_repository(endpoint, repository)

            trufflehog_results = self._scan_local_git_repository(
                local_directory, repository
            )

            self.local_data.end = datetime.datetime.now().isoformat()
            self._save_scan_results(
                repository_scan_identifier, repository, "findings", trufflehog_results
            )

            common.log(
                "INFO",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Repository scanned successfully: {repository_name} (organization: {repository_organization})",
            )
        except Exception as exception:
            common.log(
                "ERROR",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"An error occurred while processing repository {repository_name}: {str(exception)}",
            )
            self.local_data.end = datetime.datetime.now().isoformat()
            self._save_error(repository_scan_identifier, repository)

    def _clone_repository(self, endpoint, repository):
        repository_organization = repository.get("organization")
        repository_name = repository.get("name")
        git_repository_url = endpoint.format(
            organization=repository_organization, repository=repository_name
        )

        common.log(
            "DEBUG",
            f"SECRETS-FINDER ({self.local_data.execution_id})",
            f"Cloning repository: {git_repository_url}",
        )

        env = os.environ.copy()
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_ASKPASS"] = os.path.join(
            self.scanner_folder, "git-credentials-helper.sh"
        )
        env["SECRETS_FINDER_SCAN_USERNAME"] = os.environ.get(
            "SECRETS_FINDER_SCAN_USERNAME"
        )
        env["SECRETS_FINDER_SCAN_TOKEN"] = os.environ.get("SECRETS_FINDER_SCAN_TOKEN")

        temporary_directory = tempfile.mkdtemp()
        common.log(
            "DEBUG",
            f"SECRETS-FINDER ({self.local_data.execution_id})",
            f"Temporary directory created: {temporary_directory}",
        )

        try:
            common.log(
                "DEBUG",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Cloning repository: {git_repository_url}",
            )
            common.run_command(
                f"git clone '{git_repository_url}' '{temporary_directory}'", env=env
            )
            common.log(
                "DEBUG",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Repository cloned: {git_repository_url}",
            )
            return temporary_directory
        except Exception:
            self._delete_local_git_repository(temporary_directory)
            raise

    def _scan_local_git_repository(self, local_directory, repository):
        try:
            repository_since_commit = repository.get("since-commit")
            repository_branch = repository.get("branch")
            repository_max_depth = repository.get("max-depth")

            trufflehog_command = f"{os.path.join(self.trufflehog_installation_path, self.trufflehog_executable_name)} git --no-update --json"
            if self.report_only_verified:
                trufflehog_command += " --only-verified"
            if repository_since_commit:
                trufflehog_command += f" --since-commit={repository_since_commit}"
            if repository_branch:
                trufflehog_command += f" --branch={repository_branch}"
            if repository_max_depth:
                trufflehog_command += f" --max-depth={repository_max_depth}"
            if os.path.isfile(os.path.join(self.scanner_folder, "configuration.yaml")):
                trufflehog_command += f" --config={os.path.join(self.scanner_folder, 'configuration.yaml')}"
            trufflehog_command += f" file://{local_directory}"

            common.log(
                "DEBUG",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Scanning command to execute: {trufflehog_command}",
            )

            try:
                execution_output = common.run_command(trufflehog_command)
            except Exception as e:
                raise Exception(str(e))

            trufflehog_logs = (
                execution_output[1].splitlines() if execution_output[1] else []
            )
            for line in trufflehog_logs:
                try:
                    if line:
                        common.log(
                            "DEBUG",
                            f"TRUFFLEHOG ({self.local_data.execution_id})",
                            line,
                        )
                except Exception as e:
                    continue

            trufflehog_results = (
                execution_output[0].splitlines() if execution_output[0] else []
            )
            return trufflehog_results
        finally:
            self._delete_local_git_repository(local_directory)

    def _delete_local_git_repository(self, local_directory):
        try:
            common.log(
                "DEBUG",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Deleting local repository: {local_directory}",
            )
            delete_command = f"rm -rf '{local_directory}'"
            common.run_command(delete_command)
            common.log(
                "DEBUG",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"Local repository deleted: {local_directory}",
            )
        except Exception as exception:
            common.log(
                "ERROR",
                f"SECRETS-FINDER ({self.local_data.execution_id})",
                f"An error occurred while deleting local repository {local_directory}: {str(exception)}",
            )

    def _save_scan_results(
        self, repository_scan_identifier, repository, results_key, results_to_process
    ):
        repository_organization = repository.get("organization")
        repository_name = repository.get("name")

        common.log(
            "DEBUG",
            f"SECRETS-FINDER ({self.local_data.execution_id})",
            f"Saving scan results for repository: {repository_name} (organization: {repository_organization})",
        )

        context = {
            "scan_uuid": repository_scan_identifier,
            "organization": repository_organization,
            "repository": repository_name,
            "start": self.local_data.start,
            "end": self.local_data.end,
        }
        if "metadata" in repository:
            context.update({"metadata": repository.get("metadata")})

        scan_results = []
        nb_secrets_found = 0
        for line in results_to_process:
            try:
                if line:
                    nb_secrets_found += 1
                    scan_results.append(json.loads(line))
            except Exception:
                continue

        with self.scan_results_lock:
            self.scan_results.append(
                {**context, **{results_key: scan_results, "status": "success"}}
            )

        common.log(
            "INFO",
            f"SECRETS-FINDER ({self.local_data.execution_id})",
            f"Number of secrets found in repository {repository_name} (organization: {repository_organization}): {nb_secrets_found}",
        )

    def _save_error(self, repository_scan_identifier, repository):
        repository_organization = repository.get("organization")
        repository_name = repository.get("name")

        common.log(
            "DEBUG",
            f"SECRETS-FINDER ({self.local_data.execution_id})",
            f"Saving error for repository: {repository_name} (organization: {repository_organization})",
        )

        context = {
            "scan_uuid": repository_scan_identifier,
            "organization": repository_organization,
            "repository": repository_name,
            "start": self.local_data.start,
            "end": self.local_data.end,
        }
        if "metadata" in repository:
            context.update({"metadata": repository.get("metadata")})

        with self.scan_results_lock:
            self.scan_results.append(
                {**context, **{"findings": [], "status": "failure"}}
            )

    def _save_all_results_to_file(self, location):
        filename = f"{self.scan_uuid}.json"
        file_path = os.path.join(location, filename)

        common.log(
            "INFO",
            "SECRETS-FINDER (main)",
            f"Saving all scan results to file: {file_path}",
        )

        with open(file_path, "w") as file:
            json.dump(
                {
                    "scan_type": "detection",
                    "scan_mode": "verified" if self.report_only_verified else "all",
                    "scan_uuid": self.scan_uuid,
                    "scan_identifier": self.scan_identifier,
                    "scm": self.scm,
                    "start": self.start,
                    "end": self.end,
                    "status": self.status,
                    "scan_context": "repository",
                    "results": self.scan_results if self.status == "success" else [],
                },
                file,
            )
            file.write("\n")

        common.log(
            "INFO",
            "SECRETS-FINDER (main)",
            f"All scan results saved to file:{file_path}",
        )


def run_python_scripts_provided_by_user(lifecycle, folder, raise_on_error):
    try:
        accepted_lifefycles = ["pre", "post"]
        if lifecycle not in accepted_lifefycles:
            raise ValueError(
                f"Invalid lifecycle found while executing python scripts provided by user: {lifecycle} (should be one of: {str(accepted_lifefycles)})"
            )

        common.log(
            "INFO",
            "SECRETS-FINDER (main)",
            f"Executing {lifecycle}-scan scripts provided by user...",
        )
        common.run_python_scripts(folder, f"{lifecycle}_*.py")
        common.log(
            "INFO",
            "SECRETS-FINDER (main)",
            f"{lifecycle}-scan scripts provided by user executed successfully.",
        )
    except Exception:
        common.log(
            "ERROR",
            "SECRETS-FINDER (main)",
            f"An error occurred while executing {lifecycle}-scan scripts. {'Operation aborted.' if raise_on_error else 'User asked to continue operation.'}",
        )
        if raise_on_error:
            raise
        else:
            pass


def main():
    try:
        common.load_environment_variables(
            folder=os.path.dirname(os.path.abspath(__file__)),
            environment_file="scanner.env",
        )
        arguments = configure_parser()
        common.configure_logging(
            destination_folder=os.path.join(arguments.scanner_folder, "logs"),
            log_file="secrets-finder.log",
            level=logging.INFO if not arguments.debug else logging.DEBUG,
        )
    except Exception as exception:
        print(
            f"FATAL ERROR: An unexpected error occurred during initialization: {str(exception)}"
        )
        sys.exit(2)

    try:
        run_python_scripts_provided_by_user(
            "pre", arguments.scan_folder, arguments.exit_on_error_pre
        )
        finder = SecretsFinder(
            scanner_folder=arguments.scanner_folder,
            scan_uuid=arguments.scan_uuid,
            scan_identifier=arguments.scan_identifier,
            scm=arguments.scm,
            trufflehog_installation_path=arguments.trufflehog_installation_path,
            trufflehog_executable_name=arguments.trufflehog_executable_name,
            report_only_verified=arguments.report_only_verified,
        )
        finder.scan()
        run_python_scripts_provided_by_user(
            "post", arguments.scan_folder, arguments.exit_on_error_post
        )
        sys.exit(0)
    except Exception as exception:
        common.log(
            "ERROR",
            "SECRETS-FINDER (main)",
            f"A fatal error occurred during scan: {str(exception)}. Operation aborted.",
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
