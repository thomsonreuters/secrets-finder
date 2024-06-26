#!/bin/bash
set -e

function write {
    CURRENT_TIME=$(date +'%y-%m-%d %T.%6N')
    echo "[$CURRENT_TIME][SECRETS-FINDER][$1] $2"
}

check_exit_code() {
    exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        handle_error
    fi
}

function handle_error {
    write "ERROR" "Unexpected error during initialization. Operation aborted."

    terminate_instance="%{ if terminate_instance_on_error != "" }${terminate_instance_on_error}%{else}false%{ endif }"
    if [[ "$terminate_instance" == "true" ]]; then
        (TOKEN=$(curl -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -s "http://169.254.169.254/latest/api/token") && INSTANCE_ID="$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)" && aws ec2 terminate-instances --instance-ids "$INSTANCE_ID") || shutdown -h now;
    else
        exit 1
    fi
}

trap 'handle_error' ERR

write "INFO" "Creation of user: ${instance_user}"
adduser "${instance_user}"
echo "${instance_user} ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/${instance_user}"

write "INFO" "Creation of folders"
SECRETS_FINDER_SCAN_FOLDER="${scan_folder}"
SECRETS_FINDER_SCANNER_FOLDER="${scanner_folder}"
mkdir -p "$SECRETS_FINDER_SCAN_FOLDER"
mkdir -p "$SECRETS_FINDER_SCANNER_FOLDER"
write "INFO" "Scan folder created successfully: $SECRETS_FINDER_SCAN_FOLDER"
write "INFO" "Scanner folder created successfully: $SECRETS_FINDER_SCANNER_FOLDER"

write "INFO" "Configuration of AWS CLI"
aws configure set region "${aws_region}"
sudo -u ${instance_user} aws configure set region "${aws_region}"

S3_BUCKET="${s3_bucket}"
write "INFO" "Download of mainfiles from bucket: $S3_BUCKET"

write "INFO" "Download of utils files"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/common.py" "$SECRETS_FINDER_SCANNER_FOLDER"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/backend.py" "$SECRETS_FINDER_SCANNER_FOLDER"

write "INFO" "Download of backend initializer and finalizer"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/initializer.py" "$SECRETS_FINDER_SCANNER_FOLDER"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/finalizer.py" "$SECRETS_FINDER_SCANNER_FOLDER"

write "INFO" "Download of requirements"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/common.requirements.txt" "$SECRETS_FINDER_SCANNER_FOLDER"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/backend.requirements.txt" "$SECRETS_FINDER_SCANNER_FOLDER"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scanner/scanner.requirements.txt" "$SECRETS_FINDER_SCANNER_FOLDER"

write "INFO" "Download of environment files"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scans/${scan_identifier}/setup/backend.env" "$SECRETS_FINDER_SCANNER_FOLDER"
aws s3 cp "s3://$S3_BUCKET/secrets-finder/scheduled-scans/scans/${scan_identifier}/setup/scanner.env" "$SECRETS_FINDER_SCANNER_FOLDER"

write "INFO" "Generation of scan UUID"
uuidgen -r > "$SECRETS_FINDER_SCANNER_FOLDER/uuid.txt"
export SECRETS_FINDER_SCAN_UUID="$(cat "$SECRETS_FINDER_SCANNER_FOLDER/uuid.txt")"
write "INFO" "Scan UUID generated: $SECRETS_FINDER_SCAN_UUID"

write "INFO" "Initialization of environment"
python3 -m venv "$SECRETS_FINDER_SCANNER_FOLDER/venv"
source "$SECRETS_FINDER_SCANNER_FOLDER/venv/bin/activate"

write "INFO" "Installation of scanner dependencies"
python3 -m pip install --upgrade pip && pip install -r "$SECRETS_FINDER_SCANNER_FOLDER/common.requirements.txt" && pip install -r "$SECRETS_FINDER_SCANNER_FOLDER/backend.requirements.txt" && pip install -r "$SECRETS_FINDER_SCANNER_FOLDER/scanner.requirements.txt"
check_exit_code

write "INFO" "Initialization of scanner"
python3 "$SECRETS_FINDER_SCANNER_FOLDER/initializer.py"
check_exit_code

deactivate

write "INFO" "Configuration of scheduled scan done. Exiting..."
exit 0
