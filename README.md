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

```bash
#!/bin/bash
#
# The following is an example script that uses the collection of scripts in
# this project to first authenticate with Google's backend services and then
# perform operations against it.
#------------------------------------------------------------------------------

# These paths will be different based on where your script runs from.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PROJECT_DIR="${SCRIPT_DIR}"/scripts
source  "${PROJECT_DIR}"/base.sh

print_usage () {
    USAGE=$(cat << END

    -j  GOOGLE_API_SERVICE_ACCOUNT_JSON

        The Google API service account json payload to use for authentication.
END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'j:n:p:' flag; do
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


info "Verify environment and extract input values"
. "${PROJECT_DIR}"/google/setup.sh -j "$GOOGLE_API_SERVICE_ACCOUNT_JSON"

info "Generate authentication token"
RETURN_VALUE=$("${SCRIPROJECT_DIRPT_DIR}"/google/auth_token.sh)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export GOOGLE_API_CLIENT_AUTH_TOKEN="$RETURN_VALUE"
fi


info "Request access token"
RETURN_VALUE=$("${PROJECT_DIR}"/google/access_token.sh)
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export GOOGLE_API_CLIENT_ACCESS_TOKEN="$RETURN_VALUE"
fi

info "Initiate edit operation"
RETURN_VALUE=$("${PROJECT_DIR}"/google/edits/insert.sh -n "$APP_PACKAGE_NAME")
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    export EDIT_ID="$RETURN_VALUE"
fi

# TODO: Perform some edit actions


info "commit edit operation"
RETURN_VALUE=$("${PROJECT_DIR}"/google/edits/commit.sh -n "$APP_PACKAGE_NAME")
RETURN_CODE=$?

if [ $RETURN_CODE -ne 0 ]; then
    error "$RETURN_VALUE"
    exit $RETURN_CODE
else
    echo "$RETURN_VALUE"
fi


```
