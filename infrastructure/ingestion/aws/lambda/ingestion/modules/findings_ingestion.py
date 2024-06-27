import datetime
import json
import logging
from sqlalchemy import (
    JSON,
    VARCHAR,
    Boolean,
    Column,
    Integer,
    String,
    DateTime,
    create_engine,
)
from sqlalchemy.orm import sessionmaker, declarative_base
from modules.common.s3 import S3
from modules.common.utils import DATE_TIME_FORMAT
import uuid

Base = declarative_base()


class Finding(Base):
    __tablename__ = "findings"
    uuid = Column(String, primary_key=True)
    scan_uuid = Column(String, nullable=False)
    job_uuid = Column(String, nullable=False)
    organization = Column(String, nullable=True)
    scan_context = Column(String, nullable=False)
    created_on = Column(DateTime, nullable=False)
    decoder_name = Column(String, nullable=False)
    detector_name = Column(String, nullable=False)
    detector_type = Column(Integer, nullable=False)
    raw = Column(VARCHAR, nullable=False)
    raw_v2 = Column(VARCHAR, nullable=True)
    redacted = Column(String, nullable=True)
    source_name = Column(String, nullable=False)
    source_type = Column(Integer, nullable=False)
    verified = Column(Boolean, nullable=False)
    extra_data = Column(JSON, nullable=True)
    repository = Column(String, nullable=True)
    filename = Column(String, nullable=False)
    commit_hash = Column(String, nullable=True)
    committer_email = Column(String, nullable=True)
    commit_timestamp = Column(DateTime, nullable=True)
    line_number = Column(Integer, nullable=False)
    is_still_valid = Column(Boolean, nullable=False)
    last_validated_on = Column(DateTime, nullable=False)


class Scans(Base):
    __tablename__ = "scans"
    uuid = Column(String, primary_key=True)
    job_uuid = Column(String, nullable=False)
    scan_identifier = Column(String, nullable=True)
    scm = Column(String, nullable=False)
    organization = Column(String, nullable=True)
    repository = Column(String, nullable=False)
    scan_context = Column(String, nullable=False)
    started_on = Column(DateTime, nullable=False)
    completed_on = Column(DateTime, nullable=False)
    status = Column(Integer, nullable=False)
    scan_mode = Column(String, nullable=False)
    scan_type = Column(String, nullable=False)
    # metadata is a reserved attribute name in SQLAlchemy
    metadata_ = Column("metadata", JSON, nullable=True)


class Jobs(Base):
    __tablename__ = "jobs"
    uuid = Column(String, primary_key=True)
    scan_identifier = Column(String, nullable=False)
    scm = Column(String, nullable=False)
    scan_context = Column(String, nullable=False)
    started_on = Column(DateTime, nullable=False)
    completed_on = Column(DateTime, nullable=False)
    status = Column(Integer, nullable=False)
    scan_mode = Column(String, nullable=False)
    scan_type = Column(String, nullable=False)


def ingest_findings(db_url: str, bucket_name: str, file_key: str) -> bool:
    """
    Ingests findings from a file downloaded from S3 into a database.

    Args:
        db_url (str): The URL of the database to connect to.
        bucket_name (str): The name of the S3 bucket.
        file_key (str): The key of the file in the S3 bucket.

    Returns:
        bool: True if the ingestion is successful, False otherwise.
    """
    logging.info(f"Downloading file from S3, key: {file_key}, bucket: {bucket_name}")
    s3 = S3(bucket_name)
    file_path = s3.download_file(file_key)
    logging.info(f"File downloaded to {file_path}, key: {file_key}")

    with open(file_path, "r") as file:
        data = json.load(file)

    if not data:
        logging.error("No data in the file")
        return False

    # Create a SQLAlchemy engine to connect to the database
    engine = create_engine(db_url)

    # Create a session
    Session = sessionmaker(bind=engine)
    session = Session()

    job = Jobs(
        uuid=data["scan_uuid"],
        scan_identifier=data["scan_identifier"],
        scm=data["scm"],
        scan_context=data["scan_context"],
        started_on=datetime.datetime.strptime(data["start"], DATE_TIME_FORMAT),
        completed_on=datetime.datetime.strptime(data["end"], DATE_TIME_FORMAT),
        status=data["status"],
        scan_type=data["scan_type"],
        scan_mode=data["scan_mode"],
    )

    session.add(job)

    for result in data.get("results", []):
        scan = Scans(
            uuid=result["scan_uuid"],
            job_uuid=job.uuid,
            scan_identifier=job.scan_identifier,
            scm=job.scm,
            organization=result["organization"],
            repository=result["repository"],
            scan_context=job.scan_context,
            started_on=datetime.datetime.strptime(result["start"], DATE_TIME_FORMAT),
            completed_on=datetime.datetime.strptime(result["end"], DATE_TIME_FORMAT),
            status=result.get("status"),
            scan_mode=job.scan_mode,
            scan_type=job.scan_type,
            metadata_=result.get("metadata", {}),
        )

        logging.info(f'Ingesting scan: {result["scan_uuid"]}')
        session.add(scan)

        for finding in result.get("findings", []):
            source_meta_data = list(
                finding.get("SourceMetadata", {}).get("Data", {}).values()
            )[0]
            finding = Finding(
                uuid=str(uuid.uuid4()),
                scan_uuid=result["scan_uuid"],
                job_uuid=job.uuid,
                organization=result["organization"],
                scan_context=job.scan_context,
                created_on=datetime.datetime.now(),
                decoder_name=finding["DetectorName"],
                detector_name=finding["DetectorName"],
                detector_type=finding["DetectorType"],
                raw=finding["Raw"],
                raw_v2=finding.get("RawV2", ""),
                redacted=finding.get("Redacted", ""),
                source_name=finding["SourceName"],
                source_type=finding["SourceType"],
                verified=finding["Verified"],
                extra_data=finding.get("ExtraData", {}),
                repository=result["repository"],
                filename=source_meta_data["file"],
                commit_hash=source_meta_data.get("commit"),
                committer_email=source_meta_data.get("email"),
                commit_timestamp=(
                    datetime.datetime.strptime(
                        source_meta_data.get("timestamp"), "%Y-%m-%d %H:%M:%S %z"
                    )
                    if source_meta_data.get("timestamp")
                    else None
                ),
                line_number=source_meta_data["line"],
                is_still_valid=finding["Verified"],
                last_validated_on=datetime.datetime.strptime(
                    result["end"], DATE_TIME_FORMAT
                ),
            )

            logging.info(
                f'Ingesting finding: {finding.uuid} for scan: {result["scan_uuid"]}'
            )
            session.add(finding)

    if not s3.delete_file(file_key):
        logging.error(f"Error deleting file from S3, key: {file_key}")
        session.rollback()
        return False

    logging.info(f"Deleted file from S3, key: {file_key}")
    session.commit()
    return True
