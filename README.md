# Observability OSS Configuration

This repository contains an Upbound project, tailored for users establishing comprehensive observability for their Crossplane control planes with [Upbound](https://cloud.upbound.io). This configuration deploys a fully managed observability stack using open source tools like Prometheus and Grafana to monitor Crossplane platform performance.

## Overview

Observability is a measure of how well platform performance can be inferred from knowledge of its metrics, logs and traces outputs. This configuration provides monitoring for Crossplane components, providers, and managed resources.

The core components of a custom API in [Upbound Project](https://docs.upbound.io/learn/control-plane-project/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Configures the Functions Pipeline
- **Embedded Function(s):** Encapsulates the Composition logic and implementation within a self-contained, reusable unit

In this specific configuration, the API contains:

- **an [Oss](/apis/oss/definition.yaml) custom resource type.**
- **Composition:** Configured in [/apis/oss/composition.yaml](/apis/oss/composition.yaml), it provisions Prometheus, Grafana, and monitoring components.
- **Embedded Function:** The Composition logic is encapsulated within [embedded function](/functions/xoss/main.k)

## Important Disclaimers

**⚠️ Management Cluster Resource Use**  
Prometheus and Grafana may require significant cluster resources in relation to the amount of metrics scraped, processed and visualized. This may impact cluster operations. Consult the respective Prometheus Operator and Grafana documentation for set up guidance prior to using this configuration on mission critical Crossplane management clusters.

**⚠️ Metric Stability**  
Crossplane has no concept of metric stability. This implies that metrics used in this configuration may be absent in future versions of Crossplane and / or its providers.

## Deployment

- Execute `up project run`
- Alternatively, install the Configuration from the [Upbound Marketplace](https://marketplace.upbound.io/configurations/upbound/configuration-observability-oss)
- Check [examples](/examples/) for example XR (Composite Resource)

## Testing

The configuration can be tested using:

- `up project build` to build the project and embedded functions
- `up test run tests/*` to run composition tests in `tests/test-xoss/`
- `up test run tests/* --e2e` to run end-to-end tests in `tests/e2etest-xoss/`

## Usage

Apply the resource claim as follows to deploy the observability stack:
```bash
kubectl apply -f examples/oss.yaml
```

To load dashboards that are part of this configuration repository, apply the following dashboard resource claims:
```bash
kubectl apply -f examples/folder-grafana.yaml
kubectl apply -f examples/dashboard-grafana-crossplane-health.yaml
kubectl apply -f examples/dashboard-grafana-crossplane-mr.yaml
kubectl apply -f examples/dashboard-grafana-crossplane-resources-ttr.yaml
kubectl apply -f examples/dashboard-grafana-crossplane-sli-metrics.yaml
```

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
scripts/grafana-get-creds.sh
```

See example dashboards below.

#### Crossplane MR Dashboard
![Crossplane MR Dashboard](docs/media/crossplane-mr-dashboard.png)

#### Controller Runtime Panels From Crossplane Dashboard
![Controller Runtime Panels From Crossplane Dashboar](docs/media/crossplane-controller-runtime-panels.png)

#### Resources TTR Dashboard
![Resources TTR Dashboard](docs/media/resoures-ttr-dashboard.png)

### Crossplane Observability In Action
Once your cluster has been bootstrapped, and that prometheus and grafana
endpoints have been forwarded, what's next?

Install a kubernetes secret with your provider credentials or use IRSA or
your own preferred way to provide the providers with the permissions to
create and reconcile cloud resources.

If you use AWS, One way would be to add your credentials to
`~/.aws/credentials`, and to run
```
kubectl create secret generic aws-creds \
    -n upbound-system \
    --from-file=credentials=~/.aws/credentials
```
Note that your shell may need a fully qualified path versus `~` above.

Apply a provider configuration as follows.
```
cat <<EOF | kubectl -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: upbound-system
      name: aws-creds
      key: credentials
EOF
```

Apply resource claims and see information on the
loaded dashboards. For example you can create an AWS VPC as follows, and
you can use your own compositions and any of our
[marketplace configurations](https://marketplace.upbound.io/configurations).

```
apiVersion: ec2.aws.upbound.io/v1beta1
kind: VPC
metadata:
  name: sample-vpc
  annotations:
    meta.upbound.io/example-id: ec2/v1beta1/vpc
spec:
  forProvider:
    region: us-west-1
    cidrBlock: 172.16.0.0/16
    tags:
      Name: SampleVpc
```

## Next steps

This repository serves as a foundational step for comprehensive Crossplane observability. To enhance the configuration, consider:

1. Create new API definitions for monitoring additional components
2. Customize the existing observability stack to meet your specific monitoring requirements
3. Integrate with additional data sources or alerting systems
4. Extend monitoring to cover your custom compositions and managed resources

## Purpose

The goal for configuration-observability-oss is to complement other configurations such as [configuration-caas](https://marketplace.upbound.io/configurations). See the [Upbound Marketplace](https://marketplace.upbound.io/) for additional configurations.

## Community

Feel free to join the [SIG Observability Slack Channel](https://crossplane.slack.com/archives/C061GNH3LA0) to participate in the Crossplane observability journey.

To learn more about how to build APIs for your managed control planes in Upbound, read the guide on [Upbound's docs](https://docs.upbound.io/concepts/).
