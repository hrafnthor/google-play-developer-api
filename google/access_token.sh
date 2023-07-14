#!/usr/bin/env bash
#
# This script communicates with Google's Play Developer API to exchange an
# JWT authentication token for a access token.
#
# See more:
# https://developers.google.com/android-publisher
# -----------------------------------------------------------------------------
#
# The follwoing inputs or environment variables are accepted
#
#   -t  GOOGLE_API_CLIENT_AUTH_TOKEN
#
#       [REQUIRED]  The authentication token as generated via 'auth_token.sh'
#
#   -s  GOOGLE_API_AUTH_SERVER
#
#       [REQUIRED]  The url for the authentication server that should be used.
#                   Is the field 'token_uri' in the service account json
#                   payload.
# -----------------------------------------------------------------------------
#
# If the operation is successful the authentication token will be returned.
#
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "${PARENT_DIR}"/base.sh 2> /dev/null

print_usage () {
    USAGE=$(cat << END

This script communicates with Google's Play Developer API to exchange an
authentication token for an access token.

The following inputs or environment variables are accepted

-t  GOOGLE_API_CLIENT_AUTH_TOKEN

    [REQUIRED] The authentication token as generated via 'auth_token.sh'

-s  GOOGLE_API_TOKEN_URI

    [REQUIRED] The url for the authentication server that should be used.
    Is the field 'token_uri' in the service account json payload.

If the operation is successful the authentication token will be returned.

END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 's:t:' flag; do
  case "${flag}" in
    t) GOOGLE_API_CLIENT_AUTH_TOKEN="${OPTARG}" ;;
    s) GOOGLE_API_TOKEN_URI="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${GOOGLE_API_CLIENT_AUTH_TOKEN+x} ]; then
    error "Missing required 'GOOGLE_API_CLIENT_AUTH_TOKEN' input. Pass it directly via '-t' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_API_TOKEN_URI+x} ]; then
    error "Missing required 'GOOGLE_API_TOKEN_URI' input. Pass it directly via '-s' flag or set as env var"
    exit 1
fi

HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" \
    --header "Content-type: application/x-www-form-urlencoded" \
    --request POST \
    --data "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=$GOOGLE_API_CLIENT_AUTH_TOKEN" \
    "$GOOGLE_API_TOKEN_URI")

HTTP_BODY=$(echo ${HTTP_RESPONSE} | sed -e 's/HTTPSTATUS\:.*//g')
HTTP_STATUS=$(echo ${HTTP_RESPONSE} | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [[ ${HTTP_STATUS} != 200 ]]; then
    error "Create access token failed. Status: $HTTP_STATUS Body: $HTTP_BODY Exiting."
    exit 1
fi

echo $(echo ${HTTP_BODY} | jq -r '.access_token')
