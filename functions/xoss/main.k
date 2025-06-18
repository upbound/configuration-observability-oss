
oxr = option("params").oxr # observed composite resource
_ocds = option("params").ocds # observed composed resources
_dxr = option("params").dxr # desired composite resource
dcds = option("params").dcds # desired composed resources

_metadata = lambda name: str -> any {
    { 
        name = name.lower() + "-" + _id.lower()
        annotations = { "krm.kcl.dev/composition-resource-name" = name }
    }
}

# Extract parameters from the composite resource
_id = oxr.spec?.parameters?.id or "default"
_deletionPolicy = oxr.spec?.parameters?.deletionPolicy or "Delete"
_prometheusVersion = oxr.spec?.parameters?.operators?.prometheus?.version or "52.1.0"

# PodMonitor for Crossplane RBAC Manager
_pod_monitor_rbac_manager = {
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = _metadata("podMonitorCrossplaneRbacManager") | {
        labels = { type = "podMonitorCrossplaneRbacManager" }
    }
    spec = {
        deletionPolicy = _deletionPolicy
        providerConfigRef = { name = _id }
        managementPolicies = ["*"]
        watch = False
        forProvider = {
            manifest = {
                apiVersion = "monitoring.coreos.com/v1"
                kind = "PodMonitor"
                metadata = {
                    labels = { app = "crossplane-rbac-manager" }
                    name = "crossplane-rbac-manager"
                    namespace = "operators"
                }
                spec = {
                    namespaceSelector = {
                        matchNames = ["crossplane-system", "upbound-system"]
                    }
                    podMetricsEndpoints = [{ port = "metrics" }]
                    selector = {
                        matchLabels = { app = "crossplane-rbac-manager" }
                    }
                }
            }
        }
    }
}

# PodMonitor for Crossplane
_pod_monitor_crossplane = {
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = _metadata("podMonitorCrossplane") | {
        labels = { type = "podMonitorCrossplane" }
    }
    spec = {
        deletionPolicy = _deletionPolicy
        providerConfigRef = { name = _id }
        managementPolicies = ["*"]
        watch = False
        forProvider = {
            manifest = {
                apiVersion = "monitoring.coreos.com/v1"
                kind = "PodMonitor"
                metadata = {
                    labels = { app = "crossplane" }
                    name = "crossplane"
                    namespace = "operators"
                }
                spec = {
                    namespaceSelector = {
                        matchNames = ["crossplane-system", "upbound-system"]
                    }
                    podMetricsEndpoints = [{ port = "metrics" }]
                    selector = {
                        matchLabels = { app = "crossplane" }
                    }
                }
            }
        }
    }
}

# PodMonitor for Crossplane Providers
_pod_monitor_providers = {
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = _metadata("podMonitorCrossplaneProviders") | {
        labels = { type = "podMonitorCrossplaneProviders" }
    }
    spec = {
        deletionPolicy = _deletionPolicy
        providerConfigRef = { name = _id }
        managementPolicies = ["*"]
        watch = False
        forProvider = {
            manifest = {
                apiVersion = "monitoring.coreos.com/v1"
                kind = "PodMonitor"
                metadata = {
                    labels = { app = "crossplane-providers" }
                    name = "crossplane-providers"
                    namespace = "operators"
                }
                spec = {
                    namespaceSelector = {
                        matchNames = ["crossplane-system", "upbound-system"]
                    }
                    podMetricsEndpoints = [{ port = "http-prom" }]
                    selector = {
                        matchLabels = { app = "crossplane-providers" }
                    }
                }
            }
        }
    }
}

# Prometheus Helm Release
_prometheus_release = {
    apiVersion = "helm.crossplane.io/v1beta1"
    kind = "Release"
    metadata = _metadata("releasePrometheus") | {
        labels = oxr.metadata?.labels or {}
        annotations = (oxr.metadata?.annotations or {}) | {
            "crossplane.io/external-name" = "oss"
        }
    }
    spec = {
        deletionPolicy = _deletionPolicy
        providerConfigRef = { name = _id }
        managementPolicies = ["*"]
        rollbackLimit = 3
        forProvider = {
            chart = {
                name = "kube-prometheus-stack"
                repository = "https://prometheus-community.github.io/helm-charts"
                version = _prometheusVersion
            }
            namespace = "operators"
            values = {
                prometheus = {
                    prometheusSpec = {
                        podMonitorSelectorNilUsesHelmValues = False
                        probeSelectorNilUsesHelmValues = False
                        ruleSelectorNilUsesHelmValues = False
                        serviceMonitorSelectorNilUsesHelmValues = False
                    }
                }
            }
        }
    }
}

# Usage resources
_usage_rbac = {
    apiVersion = "apiextensions.crossplane.io/v1alpha1"
    kind = "Usage"
    metadata = _metadata("usagePrometheusByPodMonitorCrossplaneRbacManager")
    spec = {
        by = {
            apiVersion = "kubernetes.crossplane.io/v1alpha2"
            kind = "Object"
            resourceSelector = {
                matchControllerRef = True
                matchLabels = { type = "podMonitorCrossplaneRbacManager" }
            }
        }
        of = {
            apiVersion = "helm.crossplane.io/v1beta1"
            kind = "Release"
            resourceSelector = { matchControllerRef = True }
        }
    }
}

_usage_crossplane = {
    apiVersion = "apiextensions.crossplane.io/v1alpha1"
    kind = "Usage"
    metadata = _metadata("usagePrometheusByPodMonitorCrossplane")
    spec = {
        by = {
            apiVersion = "kubernetes.crossplane.io/v1alpha2"
            kind = "Object"
            resourceSelector = {
                matchControllerRef = True
                matchLabels = { type = "podMonitorCrossplane" }
            }
        }
        of = {
            apiVersion = "helm.crossplane.io/v1beta1"
            kind = "Release"
            resourceSelector = { matchControllerRef = True }
        }
    }
}

_usage_providers = {
    apiVersion = "apiextensions.crossplane.io/v1alpha1"
    kind = "Usage"
    metadata = _metadata("usagePrometheusByPodMonitorProviders")
    spec = {
        by = {
            apiVersion = "kubernetes.crossplane.io/v1alpha2"
            kind = "Object"
            resourceSelector = {
                matchControllerRef = True
                matchLabels = { type = "podMonitorCrossplaneProviders" }
            }
        }
        of = {
            apiVersion = "helm.crossplane.io/v1beta1"
            kind = "Release"
            resourceSelector = { matchControllerRef = True }
        }
    }
}

_items = [
    _pod_monitor_rbac_manager,
    _pod_monitor_crossplane,
    _pod_monitor_providers,
    _prometheus_release,
    _usage_rbac,
    _usage_crossplane,
    _usage_providers
]

items = _items
