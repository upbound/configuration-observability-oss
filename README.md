# configuration-observability-oss
Platform Reference to Set Up Crossplane, Provider and Resource Observability
with open source software integrations such as Prometheus and Grafana.

Observability is a measure of how well platform performance can be inferred
from knowledge of its metrics, logs and traces outputs.

## Purpose
The goal for configuration-observability-oss is to complement
other configurations such as configuration-caas. See the
[Upbound Marketplace](https://marketplace.upbound.io/) for
additional configurations.

## Usage
Run `make e2e` to exercise end to end tests for the observability
integrations. Some may require an API key for specific backends.

The `_output` directory includes readily usable configuration packages
after `make build` has been run.

After tests have run and the cluster and initial requirements have
been set up by `make e2e`, you can run `bootstrap.sh` to install
Prometheus operators, Grafana, and Crossplane and Provider service
monitors for further exloration.

Use the following to forward localhost:9090 to the Prometheus pod.
```
PROMETHEUS_POD_NAME=$(k -n operators get pods|\
    awk '{print $1}'|\
    tail +2|\
    grep prometheus-0)
kubectl -n operators port-forward ${PROMETHEUS_POD_NAME} 9090
```

Use the following to forward localhost:3000 to the Grafana pod.
```
GRAFANA_POD_NAME=$(k -n operators get pods|\
    awk '{print $1}'|\
    tail +2|\
    grep grafana)
kubectl -n operators port-forward ${GRAFANA_POD_NAME} 3000
```

Log in to Grafana at http://localhost:3000 with the credentials
obtained from running the following.
```
scripts/get-creds.sh
```

## Community
Feel free to join the [SIG Observability Slack Channel](https://crossplane.slack.com/archives/C061GNH3LA0)
to participate in the Crossplane observability journey.
