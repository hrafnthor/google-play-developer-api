#!/usr/bin/env bash
#
# This script facilitates the creation of a track configuration JSON payload
# which is used in communication with '/edits/tracks' service endpoints.
#
# ATTENTION!    The payload is not complete and only uses some of the fields
#               that the API documentation has. Over time more fields will
#               be added.
#
# See more at:
# https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks#Track
#
# -----------------------------------------------------------------------------
#
# The script requires the following input parameters or environment variables:
#
#   -v  GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE
#
#       [REQUIRED]  The version code of the artifact whose status should be
#                   updated.
#
#   -s  GOOGLE_PLAY_API_RELEASE_STATUS
#
#       [OPTIONAL]  The status id to assign to the version. The following are
#                   the valid inputs along with their associated id's.
#
#                       statusUnspecified (1)   (default)
#                       draft (2)
#                       inProgress (3)
#                       halted (4)
#                       completed (5)
#
#                   Either the value name or the id can be supplied:
#
#                       track.sh -s 2
#                       track.sh -s draft
#                       export RELEASE_STATUS=1 && track.sh
#                       export RELEASE_STATUS='draft' && track.sh
#
#                   For full description of these status values see more:
#                   https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks#Status
#
# -----------------------------------------------------------------------------
#
# If successful returns a JSON string representing the 'Track' payload per
# the API documentation.
#
# -----------------------------------------------------------------------------

AVAILABLE_STATUSES=([1]=statusUnspecified [2]=draft [3]=inProgress [4]=halted [5]=completed)

SCRIPT_DIR=$(dirname "$(readlink -f "$0")" )
PARENT_DIR=$(dirname "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR" )")")")
source  "${PARENT_DIR}"/base.sh

print_usage () {
    USAGE=$(cat << END

-v  GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE

    [REQUIRED]  The version code of the artifact whose status should be
                updated.

-s  GOOGLE_PLAY_API_RELEASE_STATUS

    [OPTIONAL]  The status id to assign to the version. The following are
                the valid inputs along with their associated id's.

                    statusUnspecified (1)   (default)
                    draft (2)
                    inProgress (3)
                    halted (4)
                    completed (5)

                Either the value name or the id can be supplied:

                    track.sh -s 2
                    track.sh -s draft
                    export RELEASE_STATUS=1 && track.sh
                    export RELEASE_STATUS='draft' && track.sh

                For full description of these status values see more:
                https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks#Status
END
)
    echo "$USAGE"
}

# shellcheck disable=SC2034
while getopts 'v:s:' flag; do
  case "${flag}" in
    v) GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE="${OPTARG}" ;;
    s) GOOGLE_PLAY_API_RELEASE_STATUS="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z ${GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE+x} ]; then
    error "Missing required 'GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE' input. Pass it directly via '-v' flag or set as env var. Exiting."
    exit 1
elif [[ ! ${GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE} =~ ^[0-9]+$ ]]; then
    error "Received non numerical input '${GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE}' as version code. Only numerical inputs are allowed. Exiting."
    exit 1
fi

if [ -z ${GOOGLE_PLAY_API_RELEASE_STATUS+x} ]; then
    # Default to first entry
    GOOGLE_PLAY_API_RELEASE_STATUS="${AVAILABLE_STATUSES[1]}"
elif ((GOOGLE_PLAY_API_RELEASE_STATUS >= 1 && GOOGLE_PLAY_API_RELEASE_STATUS <= 5)); then
    # Extract value at entry
    GOOGLE_PLAY_API_RELEASE_STATUS="${AVAILABLE_STATUSES[$GOOGLE_PLAY_API_RELEASE_STATUS]}"
elif [[ ${GOOGLE_PLAY_API_RELEASE_STATUS} =~ ^[0-9]+$ ]]; then
    error "Unknown status id '${GOOGLE_PLAY_API_RELEASE_STATUS}' received as release status. Only whole values [1, 5] are accepted!. Exiting."
    error 1
elif [[ ! " ${AVAILABLE_STATUSES[*]} " =~ " ${GOOGLE_PLAY_API_RELEASE_STATUS} " ]]; then
    error "Unknown status '${GOOGLE_PLAY_API_RELEASE_STATUS}' received. Exiting."
    exit 1
fi

echo $(jq  --null-input \
    --argjson versionCodes "[${GOOGLE_PLAY_API_ARTIFACT_VERSION_CODE}]" \
    --arg status "${GOOGLE_PLAY_API_RELEASE_STATUS}" \
    '$ARGS.named'
)
