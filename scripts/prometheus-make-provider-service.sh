#!/bin/bash

SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )
NAMESPACE="upbound-system"
kubectl -n ${NAMESPACE} get pods|\
    awk '{print $1}'|\
    tail -n +2|\
    while read pod; do
	LABEL=$(kubectl -n ${NAMESPACE} \
	    get pod $pod \
	    -o jsonpath='{.metadata.labels}'|\
	    jq '.["pkg.crossplane.io/provider"]')
	if [[ ${LABEL} == "null" ]]; then
	    continue
	fi
	echo $LABEL
	touch ${SCRIPT_DIR}/../.up/config/providers/service.yaml
	cat <<EOF >> ${SCRIPT_DIR}/../.up/config/providers/service.yaml
---
kind: Service
apiVersion: v1
metadata:
  name: ${LABEL}
  namespace: upbound-system
  labels:
    app: providers
spec:
  selector:
    pkg.crossplane.io/provider: ${LABEL}
  ports:
  - name: web
    port: 8080
EOF
    done
