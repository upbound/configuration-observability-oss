PROJECT_NAME := configuration-observability-oss
UPTEST_INPUT_MANIFESTS := examples/folder-grafana.yaml,examples/dashboard-grafana-crossplane-health.yaml,examples/dashboard-grafana-crossplane-mr.yaml,examples/dashboard-grafana-crossplane-resources-ttr.yaml,examples/dashboard-grafana-crossplane-sli-metrics.yaml,examples/dashboard-grafana-crossplane-sli-2-metrics.yaml,examples/dashboard-grafana-crossplane-top-level.yaml,examples/dashboard-grafana-crossplane-xmetrics.yaml,examples/oss.yaml
UPTEST_SKIP_IMPORT := true
UPTEST_SKIP_UPDATE := true
XPKG_IGNORE ?= .github/workflows/*.yaml,.github/workflows/*.yml,examples/*.yaml,.work/uptest-datasource.yaml,.cache/render/*,test/provider/*
