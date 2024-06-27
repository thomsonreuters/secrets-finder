import os
import tempfile
import boto3
from typing import List, Tuple


class S3:
    """
    Represents an S3 client for interacting with an S3 bucket.

    Args:
        bucket_name (str): The name of the S3 bucket.

    Attributes:
        client (boto3.client): The S3 client.
        bucket_name (str): The name of the S3 bucket.

    """

    client: boto3.client = None
    bucket_name: str = None

    def __init__(self, bucket_name: str) -> None:
        """
        Initializes the S3 client.

        Args:
            bucket_name (str): The name of the S3 bucket.

        """
        self.client = boto3.client("s3")
        self.bucket_name = bucket_name

    def list_files(self, prefix: str) -> List[str]:
        """
        Lists all the files in the S3 bucket with the specified prefix.

        Args:
            prefix (str): The prefix to filter the files.

        Returns:
            List[str]: A list of file keys.

        """
        keys: List[str] = []
        continuation_token: str = None

        if not prefix.endswith("/"):
            prefix += "/"

        while True:
            kwargs: dict = {
                "Bucket": self.bucket_name,
                "Prefix": prefix,
                "Delimiter": "/",
            }

            if continuation_token:
                kwargs["ContinuationToken"] = continuation_token

            response: dict = self.client.list_objects_v2(**kwargs)
            contents: List[dict] = response.get("Contents", [])
            _keys: List[str] = [
                content["Key"]
                for content in contents
                if not content["Key"].endswith("/")
            ]
            keys.extend(_keys)

            if not response.get("IsTruncated"):
                break

            continuation_token = response.get("NextContinuationToken")

        return keys

    def download_file(self, file_key: str) -> str:
        """
        Downloads the file with the specified key from the bucket.

        Args:
            file_key (str): The key of the file to download.

        Returns:
            str: The local path of the downloaded file.

        """
        file_name: str = os.path.basename(file_key)
        local_path: str = os.path.join(tempfile.gettempdir(), file_name)
        self.client.download_file(self.bucket_name, file_key, local_path)
        return local_path

    def download_first_file(self, prefix: str) -> Tuple[str, str]:
        """
        Downloads the first file with the specified prefix from the bucket.

        Args:
            prefix (str): The prefix to filter the files.

        Returns:
            Tuple[str, str]: A tuple containing the file key and the local path of the downloaded file.

        """
        files = self.list_files(prefix)
        if not files:
            return None

        key = files[0]
        return key, self.download_file(files[0])

    def delete_file(self, file_key: str) -> bool:
        """
        Deletes the file with the specified key from the bucket.

        Args:
            file_key (str): The key of the file to delete.

        Returns:
            bool: True if the file was successfully deleted, False otherwise.

        """
        self.client.delete_object(Bucket=self.bucket_name, Key=file_key)
        return True
