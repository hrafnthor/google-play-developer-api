#!/usr/bin/env bash
#
# This script checks for required tooling as well as parsing a supplied
# Google service account JSON payload and extracts the relevant parts
# from it for later use in other scripts.
#
# -----------------------------------------------------------------------------
#
# The script expects the following inputs or environment variables
#
#   -j  GOOGLE_API_SERVICE_ACCOUNT_JSON
#
#       [REQUIRED]  The Google API service account json payload to use for
#                   authentication.
#
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "${PARENT_DIR}"/base.sh 2> /dev/null

print_usage () {
    USAGE=$(cat << END

This script parses a supplied Google service account JSON payload and
extracts the relevant parts from it for later use in other scripts.

The following inputs or environment variables are accepted

-j  GOOGLE_API_SERVICE_ACCOUNT_JSON

    The Google API service account json payload to use for authentication.

END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'j:' flag; do
  case "${flag}" in
    j) GOOGLE_API_SERVICE_ACCOUNT_JSON="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${GOOGLE_API_SERVICE_ACCOUNT_JSON+x} ]; then
    error "Missing required 'GOOGLE_API_SERVICE_ACCOUNT_JSON' input. Pass it directly via '-j' flag or set as env var"
    exit 1
fi

if ! command -v jq &> /dev/null
then
    error "Unable to find  'jq'. Please install it, then try again."
    exit 1
fi

if ! command -v curl &> /dev/null
then
    error "Unable to find  'curl'. Please install it, then try again."
    exit 1
fi

if ! command -v openssl &> /dev/null
then
    error "Unable to find  'openssl'. Please install it, then try again."
    exit 1
fi

export GOOGLE_PLAY_API_CLIENT_PRIVATE_KEY=$(echo "$GOOGLE_API_SERVICE_ACCOUNT_JSON" | jq -r '.private_key')
export GOOGLE_PLAY_API_TOKEN_URI=$(echo "$GOOGLE_API_SERVICE_ACCOUNT_JSON" | jq -r '.token_uri')
export GOOGLE_PLAY_API_CLIENT_EMAIL=$(echo "$GOOGLE_API_SERVICE_ACCOUNT_JSON" | jq -r '.client_email')
