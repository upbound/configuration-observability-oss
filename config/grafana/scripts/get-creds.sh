#!/bin/bash

GRAFANA=$(kubectl -n operators get secret|grep grafana|awk '{print $1}')
USER=$(kubectl get secret \
    --namespace operators \
    ${GRAFANA} \
    -o jsonpath="{.data.admin-user}" \
    | base64 --decode ; echo)
PASSWORD=$(kubectl get secret \
    --namespace operators \
    ${GRAFANA} \
    -o jsonpath="{.data.admin-password}" \
    | base64 --decode ; echo)

echo "user: ${USER}"
echo "password: ${PASSWORD}"
