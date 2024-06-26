import boto3
import hashlib
import hmac
import json
import os
import requests


HTTP_MAX_RETRIES = 5
HTTP_BACKOFF_FACTOR = 0.1
HTTP_STATUSES_ELIGIBLE_FOR_RETRY = [429, 500, 502, 503, 504]


secrets_manager = boto3.client("secretsmanager")


def handler(event, _):
    validate_request(event)
    status_code = forward_request(event)
    return {"statusCode": status_code}


def validate_request(event):
    if "body" not in event:
        raise Exception("Error: Invalid request")

    signature = event["headers"]["X-Hub-Signature-256"]
    if not signature:
        raise Exception("Missing X-Hub-Signature-256 header")

    github_app_secret_reference = os.environ[
        "SECRETS_FINDER_GITHUB_APP_SECRET_REFERENCE"
    ]
    github_app_secret = secrets_manager.get_secret_value(
        SecretId=github_app_secret_reference
    )["SecretString"]

    if not verify_signature(github_app_secret, signature, event["body"]):
        raise Exception("Unauthorized")


def verify_signature(secret, signature, payload):
    mac = hmac.new(
        secret.encode("utf-8"), msg=payload.encode("utf-8"), digestmod=hashlib.sha256
    )
    expected_signature = f"sha256={mac.hexdigest()}"
    return hmac.compare_digest(expected_signature, signature)


def forward_request(event):
    payload = json.loads(event["body"])

    if "commits" in payload and "ref" in payload:
        if (
            payload.get("ref")
            == f"refs/heads/{(repository := payload.get('repository')) and (default_branch := repository.get('default_branch'))}"
        ):
            event_type = "secrets_detection_in_default_branch"
            formatted_event = {
                "ref": payload.get("ref"),
                "commits": list(
                    map(
                        lambda c: {
                            "id": c.get("id"),
                            "author": c.get("author").get("username"),
                            "url": c.get("url"),
                            "timestamp": c.get("timestamp"),
                        },
                        payload["commits"],
                    )
                ),
                "before": payload.get("before"),
                "after": payload.get("after"),
                "pusher": payload.get("pusher").get("name"),
                "repository": {
                    "default_branch": default_branch,
                    "name": repository.get("name"),
                    "full_name": repository.get("full_name"),
                    "owner": repository.get("owner").get("login"),
                    "visibility": repository.get("visibility"),
                },
            }
        else:
            return {"statusCode": 204}

    elif "pull_request" in payload and "action" in payload:
        if payload.get("action") in ["opened", "synchronize", "reopened"]:
            event_type = "secrets_detection_in_pull_request"
            pull_request = payload.get("pull_request")
            repository = payload.get("repository")
            formatted_event = {
                "action": payload.get("action"),
                "pull_request": {
                    "number": pull_request.get("number"),
                    "head": pull_request.get("head").get("ref"),
                    "base": pull_request.get("base").get("ref"),
                    "created_at": pull_request.get("created_at"),
                },
                "repository": {
                    "name": repository.get("name"),
                    "full_name": repository.get("full_name"),
                    "owner": repository.get("owner").get("login"),
                    "visibility": repository.get("visibility"),
                },
            }
        else:
            return {"statusCode": 204}
    else:
        raise ValueError("Unrecognized request. Operation canceled.")

    github_token_reference = os.environ["SECRETS_FINDER_GITHUB_TOKEN_REFERENCE"]
    github_token = secrets_manager.get_secret_value(SecretId=github_token_reference)[
        "SecretString"
    ]

    organization = os.getenv("GITHUB_ORGANIZATION")
    repository = os.getenv("GITHUB_REPOSITORY")
    url = f"https://api.github.com/repos/{organization}/{repository}/dispatches"

    formatted_payload = {
        "event_type": event_type,
        "client_payload": {"event": formatted_event},
    }

    headers = {
        "Accept": "application/vnd.github.everest-preview+json",
        "Authorization": f"Bearer {github_token}",
    }

    requests_session = requests.Session()
    requests_retry_strategy = requests.adapters.Retry(
        total=HTTP_MAX_RETRIES,
        backoff_factor=HTTP_BACKOFF_FACTOR,
        status_forcelist=HTTP_STATUSES_ELIGIBLE_FOR_RETRY,
    )
    requests_session.mount(
        "https://", requests.adapters.HTTPAdapter(max_retries=requests_retry_strategy)
    )
    response = requests_session.post(
        url, data=json.dumps(formatted_payload).encode("utf-8"), headers=headers
    )
    return response.status_code
