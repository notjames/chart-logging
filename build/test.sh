#!/usr/bin/env bash
#
# This script installs the helm chart and tests
# against the deployed helm release. This script
# assumes helm is properly installed.

set -o errexit
set -o nounset
set -o pipefail

CHART_NAME=${CHART_NAME:?CHART_NAME must be set}
NAMESPACE=${NAMESPACE:?NAMESPACE must be set}
RELEASE=${RELEASE:?RELEASE must be set}
INSTALL_WAIT=${WAIT:-120}
CI_JOB_ID=${CI_JOB_ID:-empty}

if [[ ! -d ${CHART_NAME} ]]; then
  echo >&2 "Directory for chart '$CHART_NAME' does not exist."
  exit 1
fi

echo "1"
helm lint "${CHART_NAME}"
echo "2"

set -x
helm install --replace --name "${RELEASE}" --namespace "${NAMESPACE}" --set elasticsearch-chart.name=elasticsearch-"${CI_JOB_ID}" \
             --set eventrouter.name=eventrouter-"${CI_JOB_ID}" --set fluent-bit.name=fluent-bit-"${CI_JOB_ID}" ./"${CHART_NAME}"
set +x
echo "3"

echo Waiting for install to complete
sleep "${INSTALL_WAIT}"

# if there are tests, run them against the installed chart
if [[ -d ${CHART_NAME}/templates/tests ]]; then
  echo Testing release "${RELEASE}"
  helm test "${RELEASE}" --cleanup
  HELM_TEST_EXIT_CODE=$?
fi

exit ${HELM_TEST_EXIT_CODE:-0}
