
import models.io.upbound.platform.observe.v1alpha1 as observev1alpha1
import models.io.crossplane.helmm.v1beta1 as helmv1beta1
import models.io.crossplane.kubernetesm.v1alpha1 as kubernetesv1alpha1

oxr = observev1alpha1.Oss{**option("params").oxr}

_metadata = lambda name: str -> any {
    {
        name = name.lower() + "-" + _id.lower()
        annotations = { "krm.kcl.dev/composition-resource-name" = name }
    }
}

# Extract parameters from the composite resource
_id = oxr.spec?.parameters?.id
_managementPolicy = oxr.spec?.parameters?.managementPolicies
_prometheusVersion = oxr.spec?.parameters?.operators?.prometheus?.version or "79.1.1"

# PodMonitor for Crossplane RBAC Manager
_pod_monitor_rbac_manager = kubernetesv1alpha1.Object{
    metadata = _metadata("podMonitorCrossplaneRbacManager") | {
        labels = { type = "podMonitorCrossplaneRbacManager" }
    }
    spec = {
        managementPolicies = _managementPolicy
        providerConfigRef = {
            kind = "ProviderConfig"
            name = _id
        }
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
_pod_monitor_crossplane = kubernetesv1alpha1.Object{
    metadata = _metadata("podMonitorCrossplane") | {
        labels = { type = "podMonitorCrossplane" }
    }
    spec = {
        managementPolicies = _managementPolicy
        providerConfigRef = {
            kind = "ProviderConfig"
            name = _id
        }
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
_pod_monitor_providers = kubernetesv1alpha1.Object{
    metadata = _metadata("podMonitorCrossplaneProviders") | {
        labels = { type = "podMonitorCrossplaneProviders" }
    }
    spec = {
        managementPolicies = _managementPolicy
        providerConfigRef = {
            kind = "ProviderConfig"
            name = _id
        }
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
_prometheus_release = helmv1beta1.Release{
    metadata = _metadata("releasePrometheus") | {
        labels = oxr.metadata?.labels or {}
        annotations = (oxr.metadata?.annotations or {}) | {
            "crossplane.io/external-name" = "oss"
        }
    }
    spec = {
        managementPolicies = _managementPolicy
        providerConfigRef = {
            kind = "ProviderConfig"
            name = _id
        }
        rollbackLimit = 10
        forProvider = {
            chart = {
                name = "kube-prometheus-stack"
                repository = "https://prometheus-community.github.io/helm-charts"
                version = _prometheusVersion
            }
            namespace = "operators"
            wait = False
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
    apiVersion = "protection.crossplane.io/v1beta1"
    kind = "Usage"
    metadata = _metadata("usagePrometheusByPodMonitorCrossplaneRbacManager")
    spec = {
        by = {
            apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
            kind = "Object"
            resourceSelector = {
                matchControllerRef = True
                matchLabels = { type = "podMonitorCrossplaneRbacManager" }
            }
        }
        of = {
            apiVersion = "helm.m.crossplane.io/v1beta1"
            kind = "Release"
            resourceSelector = { matchControllerRef = True }
        }
    }
}

_usage_crossplane = {
    apiVersion = "protection.crossplane.io/v1beta1"
    kind = "Usage"
    metadata = _metadata("usagePrometheusByPodMonitorCrossplane")
    spec = {
        by = {
            apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
            kind = "Object"
            resourceSelector = {
                matchControllerRef = True
                matchLabels = { type = "podMonitorCrossplane" }
            }
        }
        of = {
            apiVersion = "helm.m.crossplane.io/v1beta1"
            kind = "Release"
            resourceSelector = { matchControllerRef = True }
        }
    }
}

_usage_providers = {
    apiVersion = "protection.crossplane.io/v1beta1"
    kind = "Usage"
    metadata = _metadata("usagePrometheusByPodMonitorProviders")
    spec = {
        by = {
            apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
            kind = "Object"
            resourceSelector = {
                matchControllerRef = True
                matchLabels = { type = "podMonitorCrossplaneProviders" }
            }
        }
        of = {
            apiVersion = "helm.m.crossplane.io/v1beta1"
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
