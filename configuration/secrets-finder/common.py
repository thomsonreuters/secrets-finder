import argparse
import datetime
import dotenv
import glob
import json
import logging
import logging.config
import os
import requests
import shlex
import subprocess
import time
import uuid


def valid_uuid4(value):
    try:
        uuid_obj = uuid.UUID(value, version=4)
    except ValueError:
        raise argparse.ArgumentTypeError(f"{value} is not a valid UUID v4")

    if uuid_obj.version != 4:
        raise argparse.ArgumentTypeError(f"{value} is not a UUID v4")

    return str(uuid_obj)


def str_to_bool(s):
    return s.lower() in ["true", "1", "t", "y", "yes"]


def non_empty_string(value):
    svalue = str(value)
    if svalue == "":
        raise argparse.ArgumentTypeError("value cannot be an empty string")
    return svalue


def generate_unique_identifier():
    return str(uuid.uuid4())


def configure_logging(destination_folder, log_file, level=logging.INFO):
    create_directory(destination_folder)
    logging.config.dictConfig({"version": 1, "disable_existing_loggers": True})
    logging.basicConfig(
        format="%(message)s",
        filename=os.path.join(destination_folder, log_file),
        level=level,
    )


def log(
    level,
    context,
    message,
    levels={
        "INFO": logging.info,
        "WARNING": logging.warning,
        "ERROR": logging.error,
        "DEBUG": logging.debug,
    },
):
    current_time = str(datetime.datetime.now())

    log_string = json.dumps(
        {"time": current_time, "level": level, "context": context, "message": message},
        separators=(",", ":"),
    )

    return levels[level]("%s", log_string)


def load_environment_variables(folder, environment_file):
    environment_file_path = os.path.join(folder, environment_file)
    if os.path.isfile(environment_file_path):
        dotenv.load_dotenv(dotenv_path=environment_file_path, override=True)


def attempt_operation_with_retry(operation, max_retries=3, backoff_factor=1):
    for i in range(max_retries):
        try:
            return operation()
        except Exception:
            if i == max_retries - 1:
                raise
            else:
                time.sleep(backoff_factor * (2**i))


def shutdown():
    os.system("shutdown -h now")


def run_command(
    command,
    accepted_nonzero_return_codes=None,
    env=None,
    output_file=None,
    error_file=None,
    append_output=False,
    append_error=False,
    working_directory=None,
):
    if env is None:
        env = os.environ.copy()
    else:
        env = {**os.environ.copy(), **env}

    args = shlex.split(command)

    output_mode = "a" if append_output else "w"
    error_mode = "a" if append_error else "w"

    out = open(output_file, output_mode) if output_file else subprocess.PIPE
    err = open(error_file, error_mode) if error_file else subprocess.PIPE

    process = subprocess.Popen(
        args, stdout=out, stderr=err, env=env, cwd=working_directory
    )
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

    return stdout.decode().rstrip() if stdout else None, (
        stderr.decode().rstrip() if stderr else None
    )


def create_virtual_environment(folder, virtual_environment="virtual_environment"):
    command = f"python3 -m venv '{os.path.join(folder, virtual_environment)}'"
    run_command(command)


def install_requirements_using_file(folder, file, virtual_environment=None):
    virtual_environment_path = (
        os.path.join(folder, virtual_environment) if virtual_environment else None
    )
    if virtual_environment_path and os.path.isdir(virtual_environment_path):
        pip_bin = os.path.join(virtual_environment_path, "bin", "pip")
        pip_command = f"{pip_bin} install -r '{file}'"
    else:
        pip_command = f"pip3 install -r '{file}'"

    attempt_operation_with_retry(
        lambda: run_command(pip_command, env=os.environ.copy())
    )


def get_python_files(folder, pattern):
    files = glob.glob(os.path.join(folder, pattern))
    files.sort()
    return [file for file in files if file.endswith(".py") and os.path.isfile(file)]


def get_requirements_file(folder, filename):
    requirements_file = os.path.join(folder, filename)
    return requirements_file if os.path.isfile(requirements_file) else None


def get_env_file(folder, filename):
    env_file = os.path.join(folder, filename)
    return env_file if os.path.isfile(env_file) else None


def run_python_script(file, requirements_file, env_file, folder):
    python_command = f"python3 '{file}'"
    environment_variables_to_pass = os.environ.copy()

    if requirements_file:
        virtual_environment_folder_name = (
            f"{os.path.splitext(os.path.basename(file))[0]}-venv"
        )
        if not os.path.isdir(os.path.join(folder, virtual_environment_folder_name)):
            create_virtual_environment(folder, virtual_environment_folder_name)
        install_requirements_using_file(
            folder, requirements_file, virtual_environment_folder_name
        )
        python_bin = os.path.join(folder, virtual_environment_folder_name, "bin/python")
        python_command = f"{python_bin} '{file}'"

    if env_file:
        script_environment_variables = dotenv.dotenv_values(env_file)
        environment_variables_to_pass.update(script_environment_variables)

    run_command(
        python_command, env=environment_variables_to_pass, working_directory=folder
    )


def run_python_scripts(folder, pattern):
    files = get_python_files(folder, pattern)

    for file in files:
        filename_without_extension = os.path.splitext(os.path.basename(file))[0]
        requirements_file = get_requirements_file(
            folder, f"{filename_without_extension}.requirements.txt"
        )
        env_file = get_env_file(folder, f"{filename_without_extension}.env")
        run_python_script(file, requirements_file, env_file, folder)


def make_api_request(method, url, max_retries=3, backoff_factor=1, **kwargs):
    valid_methods = ["GET", "OPTIONS", "HEAD", "POST", "PUT", "PATCH", "DELETE"]
    if method not in valid_methods:
        raise ValueError(
            f"Invalid HTTP method: {method}. Must be one of {valid_methods}."
        )

    for attempt in range(max_retries):
        try:
            response = requests.request(method, url, **kwargs)
            response.raise_for_status()
            return response
        except (
            requests.exceptions.HTTPError,
            requests.exceptions.Timeout,
            requests.exceptions.ConnectionError,
        ) as e:
            if attempt == max_retries - 1:
                raise
            else:
                time.sleep(backoff_factor * (2**attempt))


def create_directory(path):
    os.makedirs(path, exist_ok=True)


def detect_package_manager():
    try:
        run_command("dnf --version")
        return "dnf"
    except:
        pass

    try:
        run_command("yum --version")
        return "yum"
    except:
        pass

    try:
        run_command("apt-get --version")
        return "apt-get"
    except:
        pass
    try:
        run_command("dpkg --version")
        return "dpkg"
    except:
        pass

    raise Exception("No supported package manager found")
