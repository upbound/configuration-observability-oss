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
DATADOG_NAMESPACE="monitoring"
KIND_CLUSTER_NAME="local-dev"

echo_info "Waiting for Kubernetes resource readiness"
kubectl wait object.kubernetes.crossplane.io --all --for condition=Ready --timeout=15m 2>/dev/null
echo_step_completed "Kubernetes resources are ready"

kubectl get managed

echo_step_completed "Pre-delete hook complete"
