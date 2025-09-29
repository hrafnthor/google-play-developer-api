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
#   -p  GOOGLE_PLAY_API_PACKAGE_NAME
#
#       The package name being uploaded, for example 'com.company.appname'
#
#   -t  GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN
#
#       The access token to use for the upload task.
#       See script '/google/access_token.sh' for generation.
#
#   -e  GOOGLE_PLAY_API_EDIT_ID
#
#       The edit id to commit.
#       A new edit can be gotten via the script '/google/edits/insert.sh'
# -----------------------------------------------------------------------------

RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info () {
  echo -e "${BLUE}$1${NC}" >&2
}

warning () {
  echo -e "${YELLOW}$1${NC}" >&2
}

error () {
  echo -e "${RED}$1${NC}" >&2
}

print_usage () {
    USAGE=$(cat << END
This script communicates with Google's Play Developer API to commit an ongoing
edit.

It requires the following input parameters or environment variables:

-p | --package-name <value>

  The package name being uploaded, for example 'com.company.appname'.

  Can also be supplied via environment variable:

  'GOOGLE_PLAY_API_PACKAGE_NAME'

-t | --access-token <value>

  The access token to use for the upload task.
  See script '/google/access_token.sh' for generation.

  Can also be supplied via environment variable:

  'GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN'

-i | --edit-id <value>

  The edit id received when running the script '/google/edits/insert.sh'.

  Can also be supplied via environment variable:

  'GOOGLE_PLAY_API_EDIT_ID'

-r | --send-for-review

  Marks the edit to be committed with the parameter 'changesNotSentForReview'
  set as false. This indicates that the changes should be automatically sent
  for a review rather than require manual submission via the Play store console.

  Can also be enabled via the following environment variable:

  'GOOGLE_PLAY_API_RELEASE_STATUS=[TRUE|FALSE]'

-h | --help

  Prints this message
END
)
    echo "$USAGE"
}

execute () {
  local opt_short opt_long
  opt_short="hp:t:i:r"
  opt_long="help,package-name:,access-token:,edit-id:,send-for-review"

  local opts
  opts=$(getopt -o "$opt_short" -l "$opt_long" -- "$@")

  eval set -- "$opts"
  while true; do
    case "$1" in
      -h|--help)
        print_usage
        exit 0;;
      -p|--package-name)
        GOOGLE_PLAY_API_PACKAGE_NAME="$2"
        shift 2 ;;
      -t|--access-token)
        GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN="$2"
        shift 2 ;;
      -i|--edit-id)
        GOOGLE_PLAY_API_EDIT_ID="$2"
        shift 2 ;;
      -r|--send-for-review)
        GOOGLE_PLAY_API_SEND_FOR_REVIEW="TRUE"
        shift 2 ;;
      --) # End of input reading
        shift
        break ;;
      * )
        error "${BASH_SOURCE[0]}, lineno: ${LINENO}: Unknown parameter $1 received!"
        print_usage
        exit 1
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

  local parameters=

  if [ -z ${GOOGLE_PLAY_API_SEND_FOR_REVIEW+x} ] || [ "$GOOGLE_PLAY_API_SEND_FOR_REVIEW" = "FALSE" ]; then
    parameters="?changesNotSentForReview=true"
  else
    parameters="?changesNotSentForReview=false"
  fi

  HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
      --header "Authorization: Bearer $GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN" \
      --header "Content-Type: application/octet-stream" \
      --silent \
      --request POST \
      "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${GOOGLE_PLAY_API_PACKAGE_NAME}/edits/${GOOGLE_PLAY_API_EDIT_ID}:commit${parameters}")

  HTTP_BODY=$(echo ${HTTP_RESPONSE} | sed -e 's/HTTPSTATUS\:.*//g')
  HTTP_STATUS=$(echo ${HTTP_RESPONSE} | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  if [[ ${HTTP_STATUS} != 200 ]]; then
      error "Status: $HTTP_STATUS"
      error "Body: $HTTP_BODY"
      error "${BASH_SOURCE[0]}, lineno: ${LINENO}: Failed to commit edit ${GOOGLE_PLAY_API_EDIT_ID}. Exiting."
      exit 1
  fi

  echo "$HTTP_BODY"
}

execute "$@"
