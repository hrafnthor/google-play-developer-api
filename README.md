google-play-developer-api
====

A collection of simple bash scripts for communicating with Google's Play Developer API.

### Motivation

To lower the complexity of the tooling needed to perform common actions against the api surface and to make each operation as opaque as possible for anyone who wants to understand the underlying steps taken.

### State of project

As of now only parts of the api surface have been implemented. The end goal is to cover all of it.

### Implementation

Principles for implementation:

- Each script should only perform one external api call and only return one value.
- Inputs should be clearly documented in the script header as well as in printable help sections.
- Inputs should be verified in each and every script.
- Internal variables should be descriptive while still also terse.
- Leverage external toolchains as much as possible (ie. jq, curl, openssl etc).
- Prefer using process substitution to temporary file generation where ever possible.

---

### Usage example

The following script shows how to use the project to authenticate and request a temporary JWT access token before starting a edit operation, uploading a `.aab` and making it available to internal testers.

The script expects to be run from the root of the project (all scripts path in it will fail otherwise).

```bash
#!/bin/bash

ROOT_DIR=$(dirname "$(readlink -f "$0")" )
SCRIPTS_DIR="${ROOT_DIR}"/scripts
source  "${SCRIPTS_DIR}"/base.sh

print_usage () {
    USAGE=$(cat << END

    -j  GOOGLE_API_SERVICE_ACCOUNT_JSON

        The Google API service account json payload to use for authentication.

    -p  GOOGLE_PLAY_API_PACKAGE_NAME

        The application package name as defined in the Play Store.

    -a  ARTIFACT_PATH

        The absolute path to the artifact that should be uploaded
END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'a:j:p:' flag; do
  case "${flag}" in
    j) GOOGLE_API_SERVICE_ACCOUNT_JSON="${OPTARG}" ;;
    p) GOOGLE_PLAY_API_PACKAGE_NAME="${OPTARG}" ;;
    a) ARTIFACT_PATH="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${GOOGLE_API_SERVICE_ACCOUNT_JSON+x} ]; then
    error "Missing required 'GOOGLE_API_SERVICE_ACCOUNT_JSON' input. Pass it directly via '-j' flag or set as env var"
    exit 1
fi

if [ -z ${GOOGLE_PLAY_API_PACKAGE_NAME+x} ]; then
    error "Missing required 'GOOGLE_PLAY_API_PACKAGE_NAME' input. Pass it directly via '-p' flag or set as env var"
    exit 1
else
    export GOOGLE_PLAY_API_PACKAGE_NAME="$GOOGLE_PLAY_API_PACKAGE_NAME"
fi

if [ -z ${ARTIFACT_PATH+x} ]; then
    error "Missing required 'ARTIFACT_PATH' input. Pass it directly via '-p' flag or set as env var"
    exit 1
fi

info "Verify environment and extract input values"
. "${SCRIPTS_DIR}"/google/setup.sh -j "$GOOGLE_API_SERVICE_ACCOUNT_JSON"

info "Generate authentication token"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/auth_token.sh)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export GOOGLE_PLAY_API_CLIENT_AUTH_TOKEN="$RETURN_VALUE"
fi

info "Request access token"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/access_token.sh)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export GOOGLE_PLAY_API_CLIENT_ACCESS_TOKEN="$RETURN_VALUE"
fi

info "Initiate edit operation"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/edits/insert.sh)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export GOOGLE_PLAY_API_EDIT_ID="$RETURN_VALUE"
fi

warning "edit '${GOOGLE_PLAY_API_EDIT_ID}' created"

info "upload bundle to edit operation"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/edits/bundle/upload.sh -a "$ARTIFACT_PATH")
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    echo "$RETURN_VALUE"
    GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE=$(echo ${RETURN_VALUE} | jq -r '.versionCode')
fi

info "Generate track payload"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/edits/tracks/resources/track.sh -s 5 -v 32)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export GOOGLE_PLAY_API_TRACK_PAYLOAD="$RETURN_VALUE"
fi


info "Updating track with artifact"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/edits/tracks/update.sh -r 'internal')
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    echo "$RETURN_VALUE"
fi


info "commit edit"
RETURN_VALUE=$("${SCRIPTS_DIR}"/google/edits/commit.sh)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    echo "$RETURN_VALUE"
fi

```
