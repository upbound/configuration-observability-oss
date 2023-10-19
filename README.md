# platform-ref-observability-oss
Platform Reference to Set Up Crossplane, Provider and Resource Observability
with open source software integrations.

Observability is a measure of how well platform performance can be inferred
from knowledge of its metrics, logs and traces outputs.

## Purpose
The goal for platform-ref-observability is to be a reference of configuration
packages that can be installed in combination with other reference platforms
including platform-ref-aws, platform-ref-gcp and platform-ref-azure.
It show cases open source tooling like Prometheus, Grafana, Loki and
commercial integrations. The platform-ref-observability repository will
evolve over time.

Vendor specific commerical integrations are in dedicated repositories.

## Usage
Run `make e2e` to exercise end to end tests for the observability
integrations. Some may require an API key for specific backends.

The `_output` directory includes readily usable configuration packages
after `make build` has been run.

## Community
reel free to join the [SIG Observability Slack Channel](https://crossplane.slack.com/archives/C061GNH3LA0)
to participate in the Crossplane observability journey.
