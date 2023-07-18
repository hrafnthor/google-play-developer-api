#!/usr/bin/env bash
#
# This script communicates with Google's Play Developer API to upload an app bundle
# artifact to an ongoing edit.
#
# The operation requires that an initial manual upload of a first time artifact
# has taken place via the Play Store web interface (and so will fail if no
# artifact already exists).
#
# As per suggestions in api documentation the timeout for this operation is set to
# 2 minutes.
#
# See more:
# https://developers.google.com/android-publisher/api-ref/rest/v3/edits.bundles/upload
#
# -----------------------------------------------------------------------------
#
# The script requires the following input parameters or environment variables:
#
#   -p  APP_PACKAGE_NAME
#
#       The package name being uploaded, for example 'com.company.appname'
#
#   -t  GOOGLE_API_CLIENT_ACCESS_TOKEN
#
#       The access token to use for the upload task.
#       See script '/google/access_token.sh' for generation.
#
#   -a  ARTIFACT_PATH
#
#       The absolute path to the artifact that should be uploaded.
#
#   -e  EDIT_ID
#
#       The id of the edit this bundle should be associated with.
#
# -----------------------------------------------------------------------------
#
# If successful will return a JSON payload.
#
# See more:
# https://developers.google.com/android-publisher/api-ref/rest/v3/edits.bundles#Bundle
#
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PARENT_DIR=$(dirname "$(dirname "$(dirname "$SCRIPT_DIR" )")")
source  "${PARENT_DIR}"/base.sh

print_usage () {
    USAGE=$(cat << END
    -p  APP_PACKAGE_NAME

        The package name being uploaded, for example 'com.company.appname'

    -t  GOOGLE_API_CLIENT_ACCESS_TOKEN

        The access token to use for the upload task.
        See script '/google/access_token.sh' for generation.

    -a  ARTIFACT_PATH

        The absolute path to the artifact that should be uploaded

    -e  EDIT_ID

        The id of the edit this bundle should be associated with.
END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'a:e:p:t:' flag; do
  case "${flag}" in
    a) ARTIFACT_PATH="${OPTARG}" ;;
    e) EDIT_ID="${OPTARG}" ;;
    p) APP_PACKAGE_NAME="${OPTARG}" ;;
    t) GOOGLE_API_CLIENT_ACCESS_TOKEN="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${APP_PACKAGE_NAME+x} ]; then
    error "Missing required 'APP_PACKAGE_NAME' input. Pass it directly via '-p' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_API_CLIENT_ACCESS_TOKEN+x} ]; then
    error "Missing required 'GOOGLE_API_CLIENT_ACCESS_TOKEN' input. Pass it directly via '-t' flag or set as env var"
    exit 1
fi
if [ -z ${ARTIFACT_PATH+x} ]; then
    error "Missing required 'ARTIFACT_PATH' input. Pass it directly via '-a' flag or set as env var"
    exit 1
fi
if [ -z ${EDIT_ID+x} ]; then
    error "Missing required 'EDIT_ID' input. Pass it directly via '-e' flag or set as env var"
    exit 1
fi

HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
    --header "Authorization: Bearer $GOOGLE_API_CLIENT_ACCESS_TOKEN" \
    --header "Content-Type: application/octet-stream" \
    --max-time 120 \
    --progress-bar \
    --request POST \
    --upload-file ${ARTIFACT_PATH} \
    https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${APP_PACKAGE_NAME}/edits/${EDIT_ID}/bundles?uploadType=media)

HTTP_BODY=$(echo ${HTTP_RESPONSE} | sed -e 's/HTTPSTATUS\:.*//g')
HTTP_STATUS=$(echo ${HTTP_RESPONSE} | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [[ ${HTTP_STATUS} != 200 ]]; then
    warning "Status: $HTTP_STATUS"
    warning "Body: $HTTP_BODY"
    error "Uploading bundle failed. Exiting."
    exit 1
fi

echo "$HTTP_BODY"
