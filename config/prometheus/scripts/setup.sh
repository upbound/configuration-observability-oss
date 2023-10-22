#!/bin/bash

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
MONITORING_NAMESPACE="default"
KIND_CLUSTER_NAME="local-dev"


SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )

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

kind create cluster --name observe
up uxp install

echo_info "Waiting for Crossplane Pod readiness"
kubectl wait -n ${CROSSPLANE_NAMESPACE} pods --all --for condition=Ready 2>/dev/null
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

kubectl apply -f ${SCRIPT_DIR}/../../../test/provider/aws.yaml

LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -

kubectl wait --for=condition=Ready pods -l  app.kubernetes.io/name=prometheus-operator -n default


echo_info "Installing Prometheus Service Monitors"
kubectl apply -f ${SCRIPT_DIR}/../example
kubectl apply -f ${SCRIPT_DIR}/../common
kubectl apply -f ${SCRIPT_DIR}/../crossplane
kubectl apply -f ${SCRIPT_DIR}/../crossplane-rbac-manager
${SCRIPT_DIR}/make-provider-service.sh
kubectl apply -f ${SCRIPT_DIR}/../providers
echo_step_completed "Installed Prometheus Service Monitors"

echo kubectl port-forward prometheus-prometheus-0 9090
echo open localhost:9090
