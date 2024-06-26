import argparse
import boto3
import json
import logging
import os
import yaml
import sys
import tempfile

import common
import backend


def configure_parser():
    parser = argparse.ArgumentParser(
        prog="secrets-finder-initializer",
        description="This script initializes the instance where a secrets detection scan should be performed.",
        epilog="This script has been developed by Thomson Reuters. For issues, comments or help, you can contact the maintainers on the official GitHub repository: https://github.com/thomsonreuters/secrets-finder",
    )

    parser.add_argument("--debug", action="store_true", help="store debug information")
    parser.add_argument(
        "--scm",
        help="the source code management system to use",
        type=common.non_empty_string,
        choices=["github", "azure_devops", "custom"],
        required=os.environ.get("SECRETS_FINDER_SCM") is None,
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
        help="the folder where the scan files will be downloaded",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCAN_FOLDER") is None,
        default=os.environ.get("SECRETS_FINDER_SCAN_FOLDER"),
    )
    parser.add_argument(
        "--scanner-folder",
        help="the folder where the scanner files will be downloaded",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCANNER_FOLDER") is None,
        default=os.environ.get("SECRETS_FINDER_SCANNER_FOLDER"),
    )
    parser.add_argument(
        "--s3-bucket-name",
        help="the name of the S3 bucket where the scan files are stored",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_S3_BUCKET_NAME") is None,
        default=os.environ.get("SECRETS_FINDER_S3_BUCKET_NAME"),
    )
    parser.add_argument(
        "--trufflehog-installation-path",
        help="the path where trufflehog should be installed",
        type=common.non_empty_string,
        default=os.environ.get(
            "SECRETS_FINDER_TRUFFLEHOG_INSTALLATION_PATH", "/usr/bin"
        ),
    )
    parser.add_argument(
        "--trufflehog-version",
        help="the version of TruffleHog to install",
        type=common.non_empty_string,
        default=os.environ.get("SECRETS_FINDER_TRUFFLEHOG_VERSION"),
    )
    parser.add_argument(
        "--user",
        help="the user running the scan on the instance",
        type=common.non_empty_string,
        default=os.environ.get("SECRETS_FINDER_SCAN_INSTANCE_USER", "secrets-finder"),
    )
    parser.add_argument(
        "--credentials-reference",
        help="the reference stored AWS Secrets Manager and holding the credentials to use for authentication",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_CREDENTIALS_REFERENCE") is None,
        default=os.environ.get("SECRETS_FINDER_CREDENTIALS_REFERENCE"),
    )
    parser.add_argument(
        "--aws-region",
        help="the AWS region to use",
        type=common.non_empty_string,
        required=os.environ.get("AWS_REGION") is None,
        default=os.environ.get("AWS_REGION"),
    )
    parser.add_argument(
        "--datadog-api-key-reference",
        help="the reference stored in AWS Secrets Manager and holding the Datadog API key",
        type=common.non_empty_string,
        default=os.environ.get("SECRETS_FINDER_DATADOG_API_KEY_REFERENCE"),
    )
    parser.add_argument(
        "--sns-topic-arn",
        help="the name of the SNS topic to use for important notifications",
        type=common.non_empty_string,
        default=os.environ.get("SECRETS_FINDER_SNS_TOPIC_ARN"),
    )
    parser.add_argument(
        "--terminate-on-error",
        help="whether to terminate the instance if an error occurs",
        action="store_true",
        default=os.environ.get("SECRETS_FINDER_TERMINATE_ON_ERROR", "true").lower()
        == "true",
    )

    return parser.parse_args()


def configure_datadog(datadog_api_key_reference):
    if datadog_api_key_reference:
        try:
            common.log("INFO", "INITIALIZER", f"Configuring Datadog...")
            common.log(
                "DEBUG",
                "INITIALIZER",
                f"Datadog API key reference {datadog_api_key_reference}",
            )
            token = backend.get_imdsv2_token()
            headers = {"X-aws-ec2-metadata-token": token}
            response = common.make_api_request(
                method="GET",
                url="http://169.254.169.254/latest/meta-data/instance-id",
                headers=headers,
            )
            instance_id = response.text
            execution_output = common.run_command(
                f"aws ec2 describe-tags --filters 'Name=resource-id,Values={instance_id}' 'Name=key,Values=Name' --query 'Tags[].Value' --output text"
            )
            instance_name = execution_output[0]
            common.log(
                "DEBUG",
                "INITIALIZER",
                f"Instance name to configure for Datadog: {instance_name}",
            )

            api_token = get_datadog_api_token(datadog_api_key_reference)

            agent_configuration = {
                "api_key": api_token,
                "hostname": instance_name,
                "expvar_port": 47477,
                "logs_enabled": True,
                "process_config": {
                    "process_collection": {"enabled": True},
                    "scrub_args": True,
                    "custom_sensitive_words": ["token"],
                },
            }

            log_configuration = {
                "logs": [{"type": "journald", "include_units": ["scanner.service"]}]
            }

            common.log(
                "DEBUG",
                "INITIALIZER",
                f"Datadog agent configuration: {agent_configuration}",
            )
            common.log(
                "DEBUG",
                "INITIALIZER",
                f"Datadog log configuration: {log_configuration}",
            )

            common.create_directory(
                os.path.join("etc", "datadog-agent", "conf.d", "journald.d")
            )

            with open(
                os.path.join("etc", "datadog-agent", "datadog.yaml"), "w"
            ) as file:
                yaml.dump(agent_configuration, file)

            with open(
                os.path.join(
                    "etc", "datadog-agent", "conf.d", "journald.d", "conf.yaml"
                ),
                "w",
            ) as file:
                yaml.dump(log_configuration, file)

            common.log(
                "DEBUG", "INITIALIZER", "Setting permissions for dd-agent user..."
            )
            common.run_command("usermod -a -G systemd-journal dd-agent")

            common.log("DEBUG", "INITIALIZER", "Enabling Datadog...")
            common.run_command("systemctl enable datadog-agent-trace")
            common.run_command("systemctl enable datadog-agent-process")
            common.run_command("systemctl enable datadog-agent")
            common.run_command("systemctl start datadog-agent")

            common.log(
                "INFO", "INITIALIZER", "Datadog has been configured successfully."
            )
        except Exception as e:
            common.log(
                "WARNING",
                "INITIALIZER",
                f"An error occurred while configuring Datadog: {e}",
            )


def get_datadog_api_token(reference):
    common.log("INFO", "INITIALIZER", f"Retrieving Datadog API token: {reference}")
    secrets_manager = boto3.client("secretsmanager")
    secret_string = backend.get_secret_value_from_secrets_manager(
        secrets_manager, reference
    )
    common.log(
        "DEBUG", "INITIALIZER", f"Datadog API token loaded: {secret_string[:4]}..."
    )
    return secret_string


def download_scan_files(s3_bucket_name, scan_identifier, secrets_finder_scan_folder):
    common.log("INFO", "INITIALIZER", "Downloading scan files...")
    s3 = boto3.client("s3")
    backend.download_s3_bucket_directory(
        s3,
        s3_bucket_name,
        f"secrets-finder/scheduled-scans/scans/{scan_identifier}/files",
        secrets_finder_scan_folder,
    )


def download_scanner_files(
    s3_bucket_name, scan_identifier, secrets_finder_scanner_folder
):
    common.log("INFO", "INITIALIZER", "Downloading scanner files...")

    s3 = boto3.client("s3")
    backend.download_s3_bucket_directory(
        s3,
        s3_bucket_name,
        f"secrets-finder/scheduled-scans/scans/{scan_identifier}/setup",
        secrets_finder_scanner_folder,
    )
    backend.download_s3_file(
        s3_client=s3,
        s3_bucket_name=s3_bucket_name,
        s3_file_path=f"secrets-finder/scheduled-scans/scanner/git-credentials-helper.sh",
        local_file_path=os.path.join(
            secrets_finder_scanner_folder, "git-credentials-helper.sh"
        ),
        accept_missing=False,
    )
    backend.download_s3_file(
        s3_client=s3,
        s3_bucket_name=s3_bucket_name,
        s3_file_path=f"secrets-finder/scheduled-scans/scanner/scan-configuration.schema.json",
        local_file_path=os.path.join(
            secrets_finder_scanner_folder, "scan-configuration.schema.json"
        ),
        accept_missing=False,
    )
    backend.download_s3_file(
        s3_client=s3,
        s3_bucket_name=s3_bucket_name,
        s3_file_path=f"secrets-finder/scheduled-scans/scanner/scanner.py",
        local_file_path=os.path.join(secrets_finder_scanner_folder, "scanner.py"),
        accept_missing=False,
    )
    backend.download_s3_file(
        s3_client=s3,
        s3_bucket_name=s3_bucket_name,
        s3_file_path=f"secrets-finder/scheduled-scans/scanner/configuration.yaml",
        local_file_path=os.path.join(
            secrets_finder_scanner_folder, "configuration.yaml"
        ),
        accept_missing=True,
    )


def set_system_locale(locale):
    common.log("INFO", "INITIALIZER", f"Setting system locale to: {locale}")
    common.run_command(f"localectl set-locale {locale}")


def install_packages(packages):
    common.log("INFO", "INITIALIZER", f"Installing packages: {packages}")
    package_manager = common.detect_package_manager()
    common.attempt_operation_with_retry(
        lambda: common.run_command(f"{package_manager} install -y {packages}")
    )


def get_secrets_finder_credentials(reference):
    common.log(
        "INFO", "INITIALIZER", f"Retrieving credentials used for scan: {reference}"
    )
    secrets_manager = boto3.client("secretsmanager")
    secret_string = backend.get_secret_value_from_secrets_manager(
        secrets_manager, reference
    )
    secret = json.loads(secret_string)
    return secret["username"], secret["token"]


def configure_git_credential_helper(user, helper):
    common.log("INFO", "INITIALIZER", f"Configuring Git credential helper: {helper}")
    command = f"git config --global credential.helper '{helper}'"
    common.run_command(command, env={"HOME": os.path.join("home", user)})


def make_script_executable(file):
    command = f"chmod +x '{file}'"
    common.run_command(command)


def write_environment_variables_to_file(variables, file_path):
    common.log(
        "INFO",
        "INITIALIZER",
        f"Persisting environment variables for service: {file_path}",
    )
    with open(file_path, "w") as f:
        for key, value in variables.items():
            f.write(f"{key}={value}\n")


def set_permissions(path, permissions):
    common.log("INFO", "INITIALIZER", f"Setting permissions for file: {path}")
    common.log("DEBUG", "INITIALIZER", f"Permissions: {permissions}")
    os.chmod(path, permissions)


def enable_service(service):
    common.log("INFO", "INITIALIZER", f"Enabling service: {service}")
    command = f"systemctl enable {service}"
    common.run_command(command)


def install_trufflehog(trufflehog_installation_path, trufflehog_version):
    common.log("INFO", "INITIALIZER", "Installing TruffleHog...")
    common.log(
        "DEBUG",
        "INITIALIZER",
        f"TruffleHog installation path: {trufflehog_installation_path}",
    )
    common.log("DEBUG", "INITIALIZER", f"TruffleHog version: {trufflehog_version}")

    if not os.path.isdir(trufflehog_installation_path):
        os.makedirs(trufflehog_installation_path)

    with tempfile.NamedTemporaryFile(delete=True) as temporary_file:
        download_command = f"curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh -o {temporary_file.name}"
        common.attempt_operation_with_retry(
            lambda: common.run_command(download_command)
        )

        install_command = (
            f"sh {temporary_file.name} -b '{trufflehog_installation_path}'"
        )
        if trufflehog_version:
            install_command += f" 'v{trufflehog_version}'"
        common.run_command(install_command)

    make_script_executable(os.path.join(trufflehog_installation_path, "trufflehog"))

    common.log("INFO", "INITIALIZER", "TruffleHog has been installed successfully.")


def configure_instance():
    common.log("INFO", "INITIALIZER", "Configuring instance...")

    token = backend.get_imdsv2_token()
    headers = {"X-aws-ec2-metadata-token": token}
    response = common.make_api_request(
        method="GET",
        url="http://169.254.169.254/latest/meta-data/instance-type",
        headers=headers,
    )
    if response.text == "i4i.2xlarge":
        common.run_command("mkfs.ext4 /dev/nvme1n1 -O ^has_journal")
        with open("/etc/fstab", "a") as file:
            file.write(
                "/dev/nvme1n1 /tmp ext4 defaults,noatime,discard,barrier=0 1 2\n"
            )
        common.run_command("mount -a")
        common.run_command("chmod 777 /tmp")
        common.run_command("dd if=/dev/zero of=/tmp/swapfile bs=128M count=1024")
        common.run_command("chmod 0600 /tmp/swapfile")
        common.run_command("mkswap /tmp/swapfile")
        common.run_command("swapon /tmp/swapfile")
        with open("/etc/fstab", "a") as file:
            file.write("/tmp/swapfile swap swap defaults 0 0\n")
        common.run_command("mount -a")

    common.run_command("echo 1", output_file="/sys/module/zswap/parameters/enabled")


def set_owner_permissions(user, folder):
    common.log("INFO", "INITIALIZER", f"Setting owner permissions for folder: {folder}")
    command = f"chown -R {user}:{user} '{folder}'"
    common.run_command(command)


def start_service(service):
    common.log("INFO", "INITIALIZER", f"Starting service: {service}")
    command = f"systemctl start {service}"
    common.run_command(command)


def upload_log_files_to_s3(s3_bucket_name, s3_directory, local_directory):
    s3 = boto3.client("s3")
    for file in os.listdir(local_directory):
        if file.endswith(".log") and os.path.isfile(
            os.path.join(local_directory, file)
        ):
            backend.upload_file_to_s3_using_local_directory_structure(
                s3, s3_bucket_name, s3_directory, local_directory, file
            )


def main():
    try:
        common.load_environment_variables(
            folder=os.path.dirname(os.path.abspath(__file__)),
            environment_file="backend.env",
        )
        common.load_environment_variables(
            folder=os.path.dirname(os.path.abspath(__file__)),
            environment_file="scanner.env",
        )
        arguments = configure_parser()
        common.configure_logging(
            destination_folder=os.path.join(
                os.path.dirname(os.path.abspath(__file__)), "logs"
            ),
            log_file="initializer.log",
            level=logging.INFO if not arguments.debug else logging.DEBUG,
        )
    except Exception as exception:
        print(
            f"FATAL ERROR: An unexpected error occurred during initialization: {str(exception)}"
        )
        sys.exit(2)

    try:
        configure_datadog(arguments.datadog_api_key_reference)

        download_scan_files(
            arguments.s3_bucket_name, arguments.scan_identifier, arguments.scan_folder
        )
        download_scanner_files(
            arguments.s3_bucket_name,
            arguments.scan_identifier,
            arguments.scanner_folder,
        )

        set_system_locale("LANG=en_US.UTF-8")
        install_packages("jq git glibc-langpack-en")

        username, token = get_secrets_finder_credentials(
            arguments.credentials_reference
        )

        environment_variables = os.environ.copy()
        environment_variables["SECRETS_FINDER_SCAN_USERNAME"] = username
        environment_variables["SECRETS_FINDER_SCAN_TOKEN"] = token

        configure_git_credential_helper(
            arguments.user,
            os.path.join(arguments.scanner_folder, "git-credentials-helper.sh"),
        )

        make_script_executable(
            os.path.join(arguments.scanner_folder, "git-credentials-helper.sh")
        )

        service_environment_variables = {
            "SECRETS_FINDER_SCAN_USERNAME": username,
            "SECRETS_FINDER_SCAN_TOKEN": token,
        }

        service_environment_variables_file = os.path.join("etc", "secrets-finder.env")
        write_environment_variables_to_file(
            service_environment_variables, service_environment_variables_file
        )
        set_permissions(service_environment_variables_file, 0o400)

        common.run_command(
            f"mv {os.path.join(arguments.scanner_folder, 'scanner.service')} {os.path.join('usr', 'lib', 'systemd', 'system', 'secrets-finder.service')}"
        )
        enable_service("secrets-finder.service")

        install_trufflehog(
            arguments.trufflehog_installation_path, arguments.trufflehog_version
        )

        configure_instance()

        set_owner_permissions(arguments.user, arguments.scan_folder)
        set_owner_permissions(arguments.user, arguments.scanner_folder)

        start_service("secrets-finder.service")
    except Exception as e:
        try:
            common.log(
                "ERROR", "INITIALIZER", f"An error occurred during initialization: {e}"
            )
            upload_log_files_to_s3(
                arguments.s3_bucket_name,
                os.path.join(
                    "secrets-finder", "scheduled-scans", "logs", arguments.scan_uuid
                ),
                os.path.join(arguments.scanner_folder, "logs"),
            )
        finally:
            token = backend.get_imdsv2_token()
            headers = {"X-aws-ec2-metadata-token": token}
            response = common.make_api_request(
                method="GET",
                url="http://169.254.169.254/latest/meta-data/instance-id",
                headers=headers,
            )
            instance_id = response.text
            if arguments.sns_topic_arn:
                sns = boto3.client("sns")
                backend.send_sns_message(
                    sns,
                    arguments.sns_topic_arn,
                    "[SECRETS FINDER]",
                    f"An error occurred during initializationfor instance '{instance_id}': {e}",
                )
            if arguments.terminate_on_error:
                try:
                    ec2 = boto3.client("ec2")
                    backend.terminate_instance(ec2)
                except Exception as e:
                    if arguments.sns_topic_arn:
                        backend.send_sns_message(
                            sns,
                            arguments.sns_topic_arn,
                            "[SECRETS FINDER]",
                            f"Instance '{instance_id}' was expected to be terminated because of an error during initialization, but an error occurred while trying to terminate it: {e}",
                        )
                    common.shutdown()
            else:
                sys.exit(1)


if __name__ == "__main__":
    main()
