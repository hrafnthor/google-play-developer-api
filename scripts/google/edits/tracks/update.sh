#!/usr/bin/env bash
#
# This script interacts with Google's Play Developer API to promote a release
# artifact to a given track.
#
# See more:
# https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks/update
#
# -----------------------------------------------------------------------------
#
# The script requires the following input parameters or environment variables:
#
# -p  GOOGLE_PLAY_API_PACKAGE_NAME
#
#     [REQUIRED]  The package name being uploaded, for example 'com.company.appname'
#
# -t  GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN
#
#     [REQUIRED]  The access token to use for the upload task.
#
#                 Fetched via the script '/google/access_token.sh'.
#
# -r  GOOGLE_PLAY_API_TRACK_NAME
#
#     [REQUIRED]  The name of the track that the artifact should be promoted
#                 to.
#
#                 See more:
#                 https://developers.google.com/android-publisher/tracks#ff-track-name
#
# -e  GOOGLE_PLAY_API_EDIT_ID
#
#     [REQUIRED]  The edit id to update.
#                 A new edit can be started with '/google/edits/insert.sh'
#
# -j  GOOGLE_PLAY_API_TRACK_PAYLOAD
#
#     [REQUIRED]  JSON payload descriping the details of the track update
#                 operation.
#
#                 Created via the script '/tracks/resources/track.sh'.
#
# -----------------------------------------------------------------------------
#
# If successful will return a JSON string representing the state of the track.
#
# See more:
# https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks#Track
#
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PARENT_DIR=$(dirname "$(dirname "$(dirname "$SCRIPT_DIR" )")")
source  "${PARENT_DIR}"/base.sh

print_usage () {
    USAGE=$(cat << END

-p  GOOGLE_PLAY_API_PACKAGE_NAME

    [REQUIRED]  The package name being uploaded, for example 'com.company.appname'

-t  GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN

    [REQUIRED]  The access token to use for the upload task.

                Fetched via the script '/google/access_token.sh'.

-r  GOOGLE_PLAY_API_TRACK_NAME

    [REQUIRED]  The name of the track that the artifact should be promoted
                to.

                See more:
                https://developers.google.com/android-publisher/tracks#ff-track-name

-e  GOOGLE_PLAY_API_EDIT_ID

    [REQUIRED]  The edit id to update.
                A new edit can be started with '/google/edits/insert.sh'

-j  GOOGLE_PLAY_API_TRACK_PAYLOAD

    [REQUIRED]  JSON payload descriping the details of the track update
                operation.

                Created via the script '/tracks/resources/track.sh'.

END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'p:t:e:r:j:' flag; do
  case "${flag}" in
    p) GOOGLE_PLAY_API_PACKAGE_NAME="${OPTARG}" ;;
    t) GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN="${OPTARG}" ;;
    e) GOOGLE_PLAY_API_EDIT_ID="${OPTARG}" ;;
    r) GOOGLE_PLAY_API_TRACK_NAME="${OPTARG}" ;;
    j) GOOGLE_PLAY_API_TRACK_PAYLOAD="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${GOOGLE_PLAY_API_PACKAGE_NAME+x} ]; then
    error "Missing required 'GOOGLE_PLAY_API_PACKAGE_NAME' input. Pass it directly via '-p' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN+x} ]; then
    error "Missing required 'GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN' input. Pass it directly via '-t' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_PLAY_API_EDIT_ID+x} ]; then
    error "Missing required 'GOOGLE_PLAY_API_EDIT_ID' input. Pass it directly via '-e' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_PLAY_API_TRACK_NAME+x} ]; then
    error "Missing required 'GOOGLE_PLAY_API_TRACK_NAME' input. Pass it directly via '-r' flag or set as env var"
    exit 1
fi
if [ $(echo "${GOOGLE_PLAY_API_TRACK_PAYLOAD}" | jq empty > /dev/null 2>&1; echo $?) -ne 0 ]; then
  error "Input received for 'GOOGLE_PLAY_API_TRACK_PAYLOAD' does not seem to be valid JSON. Exiting."
  exit 1
fi

PAYLOAD=$(jq  --null-input \
    --argjson releases "[${GOOGLE_PLAY_API_TRACK_PAYLOAD}]" \
    '$ARGS.named'
)

HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
    --header "Authorization: Bearer $GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN" \
    --header "Content-Type: application/json" \
    --silent \
    --request PUT \
    --data "${PAYLOAD}" \
    https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${GOOGLE_PLAY_API_PACKAGE_NAME}/edits/${GOOGLE_PLAY_API_EDIT_ID}/tracks/${GOOGLE_PLAY_API_TRACK_NAME})

HTTP_BODY=$(echo ${HTTP_RESPONSE} | sed -e 's/HTTPSTATUS\:.*//g')
HTTP_STATUS=$(echo ${HTTP_RESPONSE} | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [[ ${HTTP_STATUS} != 200 ]]; then
    info "Status: $HTTP_STATUS"
    info "Body: $HTTP_BODY"
    error "Failed to update track ${TRACK_NAME} with edit ${EDIT_ID}. Exiting."
    exit 1
fi

echo "$HTTP_BODY"
