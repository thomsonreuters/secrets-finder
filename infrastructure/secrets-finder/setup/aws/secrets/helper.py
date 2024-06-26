import argparse
import os
import shlex
import subprocess
import sys


def run_command(
    command,
    accepted_nonzero_return_codes=None,
    env=None,
    output_file=None,
    error_file=None,
    append_output=False,
    append_error=False,
):
    if env is None:
        env = os.environ.copy()
    else:
        env = {**os.environ.copy(), **env}

    args = shlex.split(command)

    output_mode = "a" if append_output else "w"
    error_mode = "a" if append_error else "w"

    out = open(output_file, output_mode) if output_file else None
    err = open(error_file, error_mode) if error_file else None

    process = subprocess.Popen(args, stdout=out, stderr=err, env=env)
    stdout, stderr = process.communicate()

    if output_file:
        out.close()
    if error_file:
        err.close()

    if process.returncode != 0 and (
        accepted_nonzero_return_codes is None
        or process.returncode not in accepted_nonzero_return_codes
    ):
        error_message = f"Command '{command}' failed"
        if stderr:
            error_message += f" with error: {stderr.decode()}"
        raise Exception(error_message)

    return stdout.decode() if stdout else None, stderr.decode() if stderr else None


def configure_parser():
    parser = argparse.ArgumentParser(
        prog="secrets-finder-helper",
        description="This script offers a wrapper to create secrets in Secrets Manager using a file encrypted with SOPS.",
        epilog="This script has been developed by Thomson Reuters. For issues, comments or help, you can contact the maintainers on the official GitHub repository: https://github.com/thomsonreuters/secrets-finder",
    )

    parser.add_argument(
        "--preserve-decrypted-file",
        help="whether to preserve the decrypted file at the end of execution",
        action="store_true",
        default=os.environ.get(
            "SECRETS_FINDER_PRESERVE_DECRYPTED_FILE", "false"
        ).lower()
        == "true",
    )
    parser.add_argument(
        "--ignore-warning",
        help="whether to ignore warning",
        action="store_true",
        default=os.environ.get("SECRETS_FINDER_IGNORE_WARNING", "false").lower()
        == "true",
    )
    parser.add_argument(
        "--sops-binary-path",
        help="the path to the SOPS binary",
        default=os.environ.get("SECRETS_FINDER_SOPS_BINARY_PATH", "sops"),
    )
    parser.add_argument(
        "--terraform-command",
        help="terraform command to run ('plan', 'apply', 'destroy')",
        required=True,
        choices=["plan", "apply", "destroy"],
    )
    parser.add_argument(
        "--terraform-options",
        help="additional options to pass to the terraform command",
        default="",
    )
    parser.add_argument(
        "--aws-profile",
        help="AWS profile to use",
        default=os.environ.get("AWS_PROFILE", "default"),
    )

    return parser.parse_args()


def main():
    try:
        arguments = configure_parser()
    except Exception:
        sys.exit(1)

    try:
        if arguments.preserve_decrypted_file and not arguments.ignore_warning:
            print(
                "WARNING: The decrypted file will be preserved at the end of the execution. Make sure to remove it manually."
            )
            confirmation = input("Type 'yes' to continue, or any other key to abort: ")
            if confirmation.lower() != "yes" and confirmation.lower() != "y":
                print("Operation aborted.")
                sys.exit()

        run_command(
            f"{arguments.sops_binary_path} -d secrets.enc.json --aws-profile {arguments.aws_profile}",
            output_file="secrets.json",
        )

        try:
            terraform_command = (
                f"terraform {arguments.terraform_command} {arguments.terraform_options}"
            )
            return run_command(terraform_command)
        except:
            pass
    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        if not arguments.preserve_decrypted_file:
            os.remove("secrets.json")


if __name__ == "__main__":
    main()
