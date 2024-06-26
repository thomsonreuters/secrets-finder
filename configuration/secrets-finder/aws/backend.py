import botocore
import inspect
import os
import random
import re
import time

import common


def call_aws_service(fn, max_retries=5):
    delay = 1
    for i in range(max_retries):
        try:
            return fn()
        except botocore.exceptions.ClientError as error:
            if error.response["Error"]["Code"] in [
                "TooManyRequestsException",
                "Throttling",
            ]:
                delay_with_jitter = random.uniform(delay, delay + i + 1)
                delay *= 2
                time.sleep(delay_with_jitter)
            else:
                raise error

    aws_service = (
        re.sub("\s+", " ", inspect.getsource(fn)).replace("lambda: ", "").strip()
    )
    raise Exception(f"Maximum attempts reached calling AWS service: {aws_service}")


def get_imdsv2_token():
    token_url = "http://169.254.169.254/latest/api/token"
    token_headers = {"X-aws-ec2-metadata-token-ttl-seconds": "300"}
    token_response = common.make_api_request("PUT", token_url, headers=token_headers)
    return token_response.text


def terminate_instance(ec2_client):
    token = get_imdsv2_token()
    headers = {"X-aws-ec2-metadata-token": token}
    response = common.make_api_request(
        method="GET",
        url="http://169.254.169.254/latest/meta-data/instance-id",
        headers=headers,
    )
    instance_id = response.text

    ec2_client.terminate_instances(InstanceIds=[instance_id])


def upload_files_to_s3(s3_client, s3_bucket_name, s3_directory, local_directory):
    if os.path.exists(local_directory):
        for file in os.listdir(local_directory):
            if file.endswith(".log") and os.path.isfile(
                os.path.join(local_directory, file)
            ):
                upload_file_to_s3_using_local_directory_structure(
                    s3_client, s3_bucket_name, s3_directory, local_directory, file
                )


def upload_file_to_s3_using_local_directory_structure(
    s3_client, s3_bucket_name, s3_directory, local_directory, file
):
    local_file_path = os.path.join(local_directory, file)
    s3_file_path = os.path.join(s3_directory, file)
    upload_file_to_s3(s3_client, s3_bucket_name, local_file_path, s3_file_path)


def upload_file_to_s3(s3_client, s3_bucket_name, local_file_path, s3_file_path):
    if not os.path.isfile(local_file_path):
        raise FileNotFoundError(
            f"File could not be uploaded to S3 as it does not exist: {local_file_path}"
        )
    s3_client.upload_file(local_file_path, s3_bucket_name, s3_file_path)
    return True


def download_s3_file(
    s3_client, s3_bucket_name, s3_file_path, local_file_path, accept_missing=False
):
    try:
        call_aws_service(
            lambda: s3_client.download_file(
                s3_bucket_name, s3_file_path, local_file_path
            )
        )
        return True
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "404":
            if accept_missing:
                return False
            else:
                raise FileNotFoundError(
                    f"The file {s3_file_path} does not exist in bucket: {s3_bucket_name}"
                )
        else:
            raise


def download_s3_bucket_directory(s3_client, s3_bucket_name, s3_path, local_path):
    paginator = s3_client.get_paginator("list_objects")
    for result in paginator.paginate(
        Bucket=s3_bucket_name, Delimiter="/", Prefix=s3_path
    ):
        if result.get("CommonPrefixes") is not None:
            for subdirectory in result.get("CommonPrefixes"):
                download_s3_bucket_directory(
                    s3_client, s3_bucket_name, subdirectory.get("Prefix"), local_path
                )
        for file in result.get("Contents", []):
            destination = os.path.join(local_path, file.get("Key")[len(s3_path) :])
            if not os.path.exists(os.path.dirname(destination)):
                os.makedirs(os.path.dirname(destination))
            download_s3_file(
                s3_client=s3_client,
                s3_bucket_name=s3_bucket_name,
                s3_file_path=file.get("Key"),
                local_file_path=destination,
            )


def get_secret_value_from_secrets_manager(secrets_manager_client, reference):
    response = call_aws_service(
        lambda: secrets_manager_client.get_secret_value(SecretId=reference)
    )
    secret_string = response["SecretString"]
    return secret_string


def send_sns_message(sns_client, sns_topic_arn, subject, message):
    try:
        call_aws_service(
            lambda: sns_client.publish(
                TopicArn=sns_topic_arn, Subject=subject, Message=message
            )
        )
    except Exception:
        pass


def get_topic_arn(sns_client, topic_name):
    response = sns_client.list_topics()
    for topic in response["Topics"]:
        if topic["TopicArn"].split(":")[-1] == topic_name:
            return topic["TopicArn"]
    return None


def publish_to_sns(sns_client, topic_name, message):
    topic_arn = get_topic_arn(topic_name)
    if topic_arn:
        call_aws_service(
            lambda: sns_client.publish(
                TopicId=topic_arn, Message=f"[SECRETS FINDER] {message}"
            )
        )
