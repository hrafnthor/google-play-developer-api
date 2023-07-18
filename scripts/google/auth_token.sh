#!/usr/bin/env bash
#
# This script consumes the JSON payload received when creating a service
# account with Google, and constructs a JWT authentication token for use
# in requesting access tokens from Google's Play Developer API.
#
# See more:
# https://developers.google.com/android-publisher
# -----------------------------------------------------------------------------
#
# The script listens for the following inputs or environment variables
#
#   -s  GOOGLE_API_TOKEN_URI
#
#       [REQUIRED]  The token uri as defined in the service account json
#                   received from Google
#
#   -e  GOOGLE_API_CLIENT_EMAIL
#
#       [REQUIRED]  The client email as defined in the service account json
#                   received from Google.
#
#   -p  GOOGLE_API_CLIENT_PRIVATE_KEY
#
#       [REQUIRED]  The client private key as defined in the service account
#                   json received from Google.
#
#   -d  GOOGLE_API_CLIENT_AUTH_TOKEN_EXPIRATION_SECONDS
#
#       [OPTIONAL]  The time in seconds that the generated authentication token
#                   should be valid for. Defaults to 3 minutes.
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "${PARENT_DIR}"/base.sh 2> /dev/null

print_usage () {
    USAGE=$(cat << END

  -s  GOOGLE_API_TOKEN_URI

      [REQUIRED]  The token uri as defined in the service account json
                  received from Google.

  -e  GOOGLE_API_CLIENT_EMAIL

      [REQUIRED]  The client email as defined in the service account json
                  received from Google.

  -k  GOOGLE_API_CLIENT_PRIVATE_KEY

      [REQUIRED]  The client private key as defined in the service account
                  json received from Google.

  -d  GOOGLE_API_CLIENT_AUTH_TOKEN_EXPIRATION_SECONDS

      [OPTIONAL]  The time in seconds that the generated authentication token
                  should be valid for. Defaults to 3 minutes.
END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 's:e:k:d:' flag; do
  case "${flag}" in
    s) GOOGLE_API_TOKEN_URI="${OPTARG}" ;;
    e) GOOGLE_API_CLIENT_EMAIL="${OPTARG}" ;;
    k) GOOGLE_API_CLIENT_PRIVATE_KEY="${OPTARG}" ;;
    d) GOOGLE_API_CLIENT_AUTH_TOKEN_EXPIRATION_SECONDS=${{OPTARG}} ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${GOOGLE_API_TOKEN_URI+x} ]; then
    error "Missing required 'GOOGLE_API_TOKEN_URI' input. Pass it directly via '-s' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_API_CLIENT_EMAIL+x} ]; then
    error "Missing required 'GOOGLE_API_CLIENT_EMAIL' input. Pass it directly via '-e' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_API_CLIENT_PRIVATE_KEY+x} ]; then
    error "Missing required 'GOOGLE_API_CLIENT_PRIVATE_KEY' input. Pass it directly via '-k' flag or set as env var"
    exit 1
fi
if [ -z ${GOOGLE_API_CLIENT_AUTH_TOKEN_EXPIRATION_SECONDS+x} ]; then
    GOOGLE_API_CLIENT_AUTH_TOKEN_EXPIRATION_SECONDS=180
fi

JWT_HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e)
JWT_ISSUED_AT_DATE=$(date +%s)
JWT_EXPIRATION_DATE=$(($(date +%s)+$GOOGLE_API_CLIENT_AUTH_TOKEN_EXPIRATION_SECONDS))
JWT_BODY=$(jq  --null-input \
    --arg aud "${GOOGLE_API_TOKEN_URI}" \
    --arg iss "${GOOGLE_API_CLIENT_EMAIL}" \
    --arg scope "https://www.googleapis.com/auth/androidpublisher" \
    --arg exp "${JWT_EXPIRATION_DATE}" \
    --arg iat "${JWT_ISSUED_AT_DATE}" \
    '$ARGS.named'
)

JWT_BODY_BASE64=$(echo -n "$JWT_BODY" | openssl base64 -e)
JWT_PAYLOAD=$(echo -n "$JWT_HEADER.$JWT_BODY_BASE64" | tr -d '\n' | tr -d '=' | tr '/+' '_-')

JWT_SIGNATURE=$(echo -n "$JWT_PAYLOAD" | openssl dgst -binary -sha256 -sign <(printf '%s' "$GOOGLE_API_CLIENT_PRIVATE_KEY") | openssl base64 -e)
JWT_SIGNATURE_CLEAN=$(echo -n "$JWT_SIGNATURE" | tr -d '\n' | tr -d '=' | tr '/+' '_-')

echo ${JWT_PAYLOAD}.${JWT_SIGNATURE_CLEAN}
