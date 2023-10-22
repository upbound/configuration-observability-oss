#!/bin/bash

NAMESPACE="operators"
GRAFANA=$(kubectl -n ${NAMESPACE} get secret|grep grafana|awk '{print $1}')
USER=$(kubectl get secret \
    --namespace ${NAMESPACE} \
    ${GRAFANA} \
    -o jsonpath="{.data.admin-user}" \
    | base64 --decode ; echo)
PASSWORD=$(kubectl get secret \
    --namespace ${NAMESPACE} \
    ${GRAFANA} \
    -o jsonpath="{.data.admin-password}" \
    | base64 --decode ; echo)

echo "user: ${USER}"
echo "password: ${PASSWORD}"
