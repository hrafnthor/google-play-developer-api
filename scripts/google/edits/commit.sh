#!/usr/bin/env bash
#
# This script communicates with Google's Play Developer API to commit an ongoing
# edit.
#
# See more:
# https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit
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
#   -e  EDIT_ID
#
#       The edit id to commit.
#       A new edit can be gotten via the script '/google/edits/insert.sh'
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
TOP_LEVEL_DIR=$(dirname "$(dirname "$SCRIPT_DIR" )")
source  "${TOP_LEVEL_DIR}"/base.sh

print_usage () {
    USAGE=$(cat << END
    -p  APP_PACKAGE_NAME

        The package name being uploaded, for example 'com.company.appname'

    -t  GOOGLE_API_CLIENT_ACCESS_TOKEN

        The access token to use for the upload task.
        See script '/google/access_token.sh' for generation.

    -e  EDIT_ID

        The edit id received when running the script /google/edits/insert.sh
END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'p:t:e:' flag; do
  case "${flag}" in
    p) APP_PACKAGE_NAME="${OPTARG}" ;;
    t) GOOGLE_API_CLIENT_ACCESS_TOKEN="${OPTARG}" ;;
    e) EDIT_ID="${OPTARG}" ;;
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
if [ -z ${EDIT_ID+x} ]; then
    error "Missing required 'EDIT_ID' input. Pass it directly via '-e' flag or set as env var"
    exit 1
fi

HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
    --header "Authorization: Bearer $GOOGLE_API_CLIENT_ACCESS_TOKEN" \
    --header "Content-Type: application/octet-stream" \
    --silent \
    --request POST \
    https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${APP_PACKAGE_NAME}/edits/${EDIT_ID}:commit)

HTTP_BODY=$(echo ${HTTP_RESPONSE} | sed -e 's/HTTPSTATUS\:.*//g')
HTTP_STATUS=$(echo ${HTTP_RESPONSE} | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [[ ${HTTP_STATUS} != 200 ]]; then
    info "Status: $HTTP_STATUS"
    info "Body: $HTTP_BODY"
    error "Failed to commit edit ${EDIT_ID}. Exiting."
    exit 1
fi

echo "$HTTP_RESPONSE"
