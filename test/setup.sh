#!/usr/bin/env bash
set -aeuo pipefail

# setting up colors
BLU='\033[0;104m'
YLW='\033[0;33m'
GRN='\033[0;32m'
RED='\033[0;31m'
NOC='\033[0m' # No Color

echo_info(){
    printf "\n${BLU}%s${NOC}\n" "$1"
}
echo_step(){
    printf "\n${BLU}>>>>>>> %s${NOC}\n" "$1"
}
echo_step_completed(){
    printf "${GRN} [✔] %s${NOC}\n" "$1"
}
echo_fatal(){
    printf "\n${RED}%s${NOC}\n" "$1"
    exit -1
}

SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )
CROSSPLANE_NAMESPACE="upbound-system"
DATADOG_NAMESPACE="monitoring"
KIND_CLUSTER_NAME="local-dev"

function check_if_exists_or_exit() {
    APP=$(which $1)
    if [[ "$APP" == "" ]]; then
	echo_fatal "$1 required. Aborting."
 	exit -1
    else
 	echo_step_completed "$1 exists"
    fi
}

echo_info "Checking for Applications"
check_if_exists_or_exit "kind"
check_if_exists_or_exit "kubectl"

echo_info "Waiting for Crossplane Pod readiness"
"${KUBECTL}" wait -n ${CROSSPLANE_NAMESPACE} pods --all --for condition=Ready 2>/dev/null
echo_step_completed "Universal Crossplane is ready"

CRDS_NOT_READY=true
echo_info "Waiting for CRDs to be available"
while [[ "$CRDS_NOT_READY" == "true" ]]; do
    sleep 7
    echo_step "Waiting for CRDs. This may take a moment"
    PROVIDERS=$(kubectl get crds 2>/dev/null|grep providers.pkg.crossplane.io)
    if [[ "$PROVIDERS" != "" ]]; then
        CRDS_NOT_READY=false
    fi
done
echo_step_completed "CRDs are available"

echo_info "Installing ControllerConfig"
"${KUBECTL}" apply -f ${SCRIPT_DIR}/provider/controllerconfig.yaml
echo_step_completed "Installed ControllerConfig"

echo_info "Installing select AWS providers"
"${KUBECTL}" apply -f ${SCRIPT_DIR}/provider/provider-aws.yaml
echo_step_completed "Installed select AWS providers"

echo_info "Installing grafana providers"
"${KUBECTL}" apply -f ${SCRIPT_DIR}/provider/provider-grafana.yaml
echo_step_completed "Installed select grafana providers"

echo_info "Waiting for provider readiness ... this will take a moment"
"${KUBECTL}" wait provider.pkg --all --for condition=Healthy --timeout=15m 2>/dev/null
NUM_CRDS=$("${KUBECTL}" get crds|wc -l)
echo_step_completed "Installed providers using ${NUM_CRDS} CRDs"

echo_info "Installing providerconfigs"
"${KUBECTL}" apply -f ${SCRIPT_DIR}/provider/providerconfigs.yaml
"${KUBECTL}" apply -f ${SCRIPT_DIR}/provider/providerconfig-grafana.yaml
echo_step_completed "Installed providerconfigs"

echo_info "Adding provider-kubernetes Service Account permissions"
SA=$("${KUBECTL}" -n ${CROSSPLANE_NAMESPACE} get sa -o name|grep provider-kubernetes | sed -e "s|serviceaccount\/|${CROSSPLANE_NAMESPACE}:|g")
"${KUBECTL}" create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
echo_step_completed "Added provider-kubernetes Service Account permissions"

echo_info "Adding provider-helm Service Account permissions"
SA=$("${KUBECTL}" -n ${CROSSPLANE_NAMESPACE} get sa -o name|grep provider-helm | sed -e "s|serviceaccount\/|${CROSSPLANE_NAMESPACE}:|g")
"${KUBECTL}" create clusterrolebinding provider-helm-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
echo_step_completed "Added provider-helm Service Account permissions"

# workaround because build module cannot set the metrics.enabled
"${KUBECTL}" patch deployment crossplane -n upbound-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"name": "metrics", "containerPort": 8080}}]'
"${KUBECTL}" patch deployment crossplane-rbac-manager -n upbound-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports", "value": [{"name": "metrics", "containerPort": 8080}]}]'
