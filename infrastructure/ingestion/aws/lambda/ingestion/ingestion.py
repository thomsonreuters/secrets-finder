import os
from typing import List, Dict, Any, Callable, Union
import logging
from modules.common.s3 import S3
from modules.findings_ingestion import ingest_findings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()],
)

bucket_name: str = os.environ.get("BUCKET_NAME")
db_url: str = os.environ.get("DB_URL")

ingestion_callback_mapping: Dict[str, Callable[[str, str, str], bool]] = {
    "ingest_findings": ingest_findings
}


def list_files(prefix: str) -> Dict[str, Union[int, Dict[str, List[str]]]]:
    s3 = S3(bucket_name)
    files = s3.list_files(prefix)
    return {"statusCode": 200, "body": {"files": files}}


def handler(event: Dict[str, Any], _) -> Dict[str, Any]:
    """
    Handle the Lambda function invocation.

    Args:
        event (Dict[str, Any]): The event data passed to the Lambda function.
        _ (Any): The context object representing the runtime information.

    Returns:
        Dict[str, Any]: The response data returned by the Lambda function.

    Raises:
        ValueError: If the request is invalid or the action is not supported.
    """
    action: str = event.get("action")

    if action == "list_files":
        prefix: str = event.get("prefix")
        if not prefix:
            logging.error("missing prefix in request for action list_files")
            raise ValueError("Invalid request")

        response: Dict[str, Union[int, Dict[str, List[str]]]] = list_files(prefix)
        return response

    elif action in ingestion_callback_mapping:
        file_key: str = event.get("file_key")
        if not file_key:
            logging.error("missing file_key in request for action ingest_findings")
            raise ValueError("Invalid request")

        status: bool = ingestion_callback_mapping[action](db_url, bucket_name, file_key)

        if not status:
            logging.error("Error ingesting data")
            raise ValueError("Error ingesting data")

        return {"statusCode": 200, "body": {"success": status}}

    else:
        logging.error(f"Invalid action: {action}")
        raise ValueError("Invalid request")
