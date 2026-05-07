#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <gitops-dir> <environment> <image-repository> <image-tag> <commit-sha>" >&2
  exit 1
fi

GITOPS_DIR="$1"
ENVIRONMENT="$2"
IMAGE_REPOSITORY="$3"
IMAGE_TAG="$4"
COMMIT_SHA="$5"
VALUES_FILE="${GITOPS_DIR}/values/diploma-demo/demo-web/values-${ENVIRONMENT}.yaml"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

test -f "${VALUES_FILE}"

ruby -ryaml -e '
  file, repository, tag, sha, timestamp = ARGV
  values = YAML.load_file(file)
  values["image"] ||= {}
  values["config"] ||= {}
  values["image"]["repository"] = repository
  values["image"]["tag"] = tag
  values["config"]["APP_VERSION"] = tag
  values["config"]["DEPLOYMENT_TIMESTAMP"] = timestamp
  values["config"]["GIT_SHA"] = sha
  File.write(file, YAML.dump(values).sub(/\A---\n/, ""))
' "${VALUES_FILE}" "${IMAGE_REPOSITORY}" "${IMAGE_TAG}" "${COMMIT_SHA}" "${TIMESTAMP}"

echo "Updated ${VALUES_FILE} to ${IMAGE_REPOSITORY}:${IMAGE_TAG}"
