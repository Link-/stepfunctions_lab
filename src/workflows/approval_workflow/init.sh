#!/bin/sh
# +-------------------------------+
# | buid.sh                       |
# | +-----------------------------+
# |                               |
# | This is a simple bash script  |
# | that will compile the needed  |
# | artefacts (like lambda        |
# | function payload or otherwise)|
# | and make them ready for       |
# | Terraform to upload to AWS.   |
# |                               |
# | v:0.1                         |
# +-------------------------------+

set -o errexit
set -o nounset
set -o pipefail

LAMBDA_PAYLOAD_FILE_PATH="lambda"
LAMBDA_PAYLOAD_FILE_NAME="function.py"
LAMBDA_PAYLOAD_ZIP_FILE_NAME="payload.zip"
TERRAFORM_MODULE_PATH="terraform"
EXPRESS_APP_PATH="app"

echo "$(date +%F_%T) \t INFO:: Checking if zip is installed"
hash zip 2>/dev/null || { echo >&2 "$(date +%F_%T) \t INFO:: I require zip but it's not installed. Aborting."; exit 1; }

echo "$(date +%F_%T) \t INFO:: Checking if lambda payload file exists"
if [[ -e "${LAMBDA_PAYLOAD_FILE_PATH}/${LAMBDA_PAYLOAD_FILE_NAME}" ]]; then
  echo "$(date +%F_%T) \t INFO:: ${LAMBDA_PAYLOAD_FILE_NAME} exists"

  echo "$(date +%F_%T) \t INFO:: Switching directory to: ${LAMBDA_PAYLOAD_FILE_PATH}"
  cd $LAMBDA_PAYLOAD_FILE_PATH

  echo "$(date +%F_%T) \t INFO:: Creating payload zip file"
  zip -r $LAMBDA_PAYLOAD_ZIP_FILE_NAME ./$LAMBDA_PAYLOAD_FILE_NAME

  # Double check if the zip command was successful and that the zip
  # file exists
  if [[ $? -eq 0 ]]; then
    if [[ -e "${LAMBDA_PAYLOAD_ZIP_FILE_NAME}" ]]; then
      echo "$(date +%F_%T) \t INFO:: ${LAMBDA_PAYLOAD_ZIP_FILE_NAME} was created successfully"
    else
      echo "$(date +%F_%T) \t ERROR:: failed to create ${LAMBDA_PAYLOAD_ZIP_FILE_NAME}. Make sure you have sufficient permissions and/or zip is installed"
      exit 1
    fi
  else
    echo "$(date +%F_%T) \t ERROR:: Make sure you have sufficient permissions and/or zip is installed"
    exit 1
  fi

else
  echo "$(date +%F_%T) \t ERROR:: ${LAMBDA_PAYLOAD_FILE_NAME} does not exist, exiting. Please make sure you are running this script from the workflow's directory."
  exit 1
fi

# Initialize terraform
cd ..
echo "$(date +%F_%T) \t INFO:: switching to parent directory $(pwd)"
echo "$(date +%F_%T) \t INFO:: initializing terraform"
terraform init $TERRAFORM_MODULE_PATH

# Setup the control app
cd $EXPRESS_APP_PATH
echo "$(date +%F_%T) \t INFO:: switching to parent directory $(pwd)"
echo "$(date +%F_%T) \t INFO:: running npm install in $EXPRESS_APP_PATH"
npm ci