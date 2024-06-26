import argparse
import boto3
import logging
import os
import sys

import common
import backend


def configure_parser():
    parser = argparse.ArgumentParser(
        prog="secrets-finder-finalizer",
        description="This script performs post-scan operations on the instance where a secrets detection scan has been launched..",
        epilog="This script has been developed by Thomson Reuters. For issues, comments or help, you can contact the maintainers on the official GitHub repository: https://github.com/thomsonreuters/secrets-finder",
    )

    parser.add_argument("--debug", action="store_true", help="store debug information")
    parser.add_argument(
        "--scan-identifier",
        help="the identifier of the scan performed",
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
        help="the folder where the scan files are located on the instance",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCAN_FOLDER") is None,
        default=os.environ.get("SECRETS_FINDER_SCAN_FOLDER"),
    )
    parser.add_argument(
        "--scanner-folder",
        help="the folder where the scanner files are located on the instance",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_SCANNER_FOLDER") is None,
        default=os.environ.get("SECRETS_FINDER_SCANNER_FOLDER"),
    )
    parser.add_argument(
        "--s3-bucket-name",
        help="the name of the S3 bucket where the scan results should be reported",
        type=common.non_empty_string,
        required=os.environ.get("SECRETS_FINDER_S3_BUCKET_NAME") is None,
        default=os.environ.get("SECRETS_FINDER_S3_BUCKET_NAME"),
    )
    parser.add_argument(
        "--sns-topic-arn",
        help="the name of the SNS topic to use for important notifications",
        type=common.non_empty_string,
        default=os.environ.get("SECRETS_FINDER_SNS_TOPIC_ARN"),
    )
    parser.add_argument(
        "--terminate-instance-after-scan",
        help="whether to terminate the instance at the end of operations",
        action="store_true",
        default=common.str_to_bool(
            os.environ.get("SECRETS_FINDER_TERMINATE_AFTER_SCAN", "true")
        ),
    )
    parser.add_argument(
        "--terminate-on-error",
        help="whether to terminate the instance if an error occurs",
        action="store_true",
        default=common.str_to_bool(
            os.environ.get("SECRETS_FINDER_TERMINATE_ON_ERROR", "true")
        ),
    )

    return parser.parse_args()


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
            log_file="finalizer.log",
            level=logging.INFO if not arguments.debug else logging.DEBUG,
        )
    except Exception as exception:
        print(
            f"FATAL ERROR: An unexpected error occurred during initialization: {str(exception)}"
        )
        sys.exit(2)

    try:
        s3 = boto3.client("s3")

        common.log(
            "INFO",
            "FINALIZER",
            f"Uploading results to S3 bucket: {arguments.s3_bucket_name}",
        )
        backend.upload_file_to_s3_using_local_directory_structure(
            s3,
            arguments.s3_bucket_name,
            f"secrets-finder/scheduled-scans/results",
            arguments.scanner_folder,
            f"{arguments.scan_uuid}.json",
        )
        common.log(
            "INFO",
            "FINALIZER",
            f"Uploading logs from scan folder to S3 bucket: {arguments.s3_bucket_name}",
        )
        backend.upload_files_to_s3(
            s3,
            arguments.s3_bucket_name,
            f"secrets-finder/scheduled-scans/logs/{arguments.scan_uuid}",
            os.path.join(arguments.scan_folder, "logs"),
        )
        common.log(
            "INFO",
            "FINALIZER",
            f"Uploading logs from scanner folder to S3 bucket: {arguments.s3_bucket_name}",
        )
        backend.upload_files_to_s3(
            s3,
            arguments.s3_bucket_name,
            f"secrets-finder/scheduled-scans/logs/{arguments.scan_uuid}",
            os.path.join(arguments.scanner_folder, "logs"),
        )

        if arguments.terminate_instance_after_scan:
            common.log("INFO", "FINALIZER", "Terminating instance...")
            ec2 = boto3.client("ec2")
            backend.terminate_instance(ec2)
        else:
            sys.exit(0)
    except Exception as e:
        common.log(
            "ERROR", "FINALIZER", f"An error occurred during finalization of scan: {e}"
        )
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
                f"An error occurred during finalization of scan on instance '{instance_id}': {e}",
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
                        f"Instance '{instance_id}' was expected to be terminated because of an error during finalization, but an error occurred while trying to terminate it: {e}",
                    )
                common.shutdown()
        else:
            sys.exit(1)


if __name__ == "__main__":
    main()
