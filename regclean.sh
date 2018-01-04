#!/bin/bash
set -euo pipefail

DEBUG=${DEBUG:-0}

while getopts "h?b:dr:u:" opt; do
  case "$opt" in
    h|\?)
      echo "Usage: $0 [-d] -u 'user:pass'"
      exit 0
      ;;
    b)
      BUCKET=${OPTARG}
      ;;
    d)
      DEBUG=1
      ;;
    r)
      REGISTRY=${OPTARG}
      ;;
    u)
      AUTH=${OPTARG}
      ;;
  esac
done

HEADER="Accept: application/vnd.docker.distribution.manifest.v2+json"

function debug {
  >&2 echo "$@"
}

function get_available_manifests {
  debug "  - Retrieving all available manifests for repository $1 from S3..."
  { aws s3 ls s3://${BUCKET}/docker/registry/v2/repositories/$1/_manifests/revisions/sha256/ || echo ""; } | \
    awk '{print $2}' | sed 's#/$##'
}

function get_current_repos {
  debug "Retrieving repositories from registry..."
  curl -s -u ${AUTH} -H "${HEADER}" ${REGISTRY}/v2/_catalog | jq -r '.repositories | .[]' | xargs
  debug
}

function get_current_tags {
  debug "  - Retrieving tags for repository $1 from registry..."
  curl -sf -u ${AUTH} -H "${HEADER}" ${REGISTRY}/v2/$1/tags/list | jq -r '.tags | .[]' | xargs
}

function get_current_manifest {
  for tag in $(get_current_tags $1); do
    MF=$(curl -sI -u ${AUTH} -H "${HEADER}" ${REGISTRY}/v2/$1/manifests/$tag | \
      grep 'Docker-Content-Digest' | cut -d ':' -f 3)

    debug "  - Found manifest for $1:${tag}: ${MF}"
    echo "${MF}"
  done
}

function remove_unused_manifests {
  current=$(get_current_manifest $1 | xargs)
  available=$(get_available_manifests $1 | xargs)
  debug "  - Processing manifests..."

  for mf in ${available}; do
    if [ -n "${current}" ] && [[ "${current}" == *${mf}* ]]; then
      debug "    - sha256:${mf} - used"
      continue
    fi

    debug -n "    - sha256:${mf} - unused - "
    if [ $DEBUG -eq 0 ]; then
      curl -sI -X DELETE -u ${AUTH} -H "${HEADER}" "${REGISTRY}/v2/$1/manifests/sha256:${mf}" | \
        grep -qE "HTTP/[12.]+ (202|404) " && debug "deleted" || debug "FAILED to delete"
    else
      debug "NOOP"
    fi
  done
}

for repo in $(get_current_repos); do
  debug "Working on repository ${repo}..."
  remove_unused_manifests ${repo}
  debug
done
