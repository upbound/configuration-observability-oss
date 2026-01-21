import models.io.crossplane.helmm.v1beta1 as helmv1beta1
import models.io.crossplane.kubernetesm.v1alpha1 as kubernetesv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 1 - For PodMonitor for Crossplane RBAC Manager"
        spec = {
            assertResources: [
                # Assert that PodMonitor for Crossplane RBAC Manager is created
                kubernetesv1alpha1.Object {
                    apiVersion: "kubernetes.m.crossplane.io/v1alpha1"
                    kind: "Object"
                    metadata.name: "podmonitorcrossplanerbacmanager-test-cluster"
                    metadata.labels.type: "podMonitorCrossplaneRbacManager"
                    spec.forProvider.manifest = {
                        apiVersion: "monitoring.coreos.com/v1"
                        kind: "PodMonitor"
                        metadata = {
                            name: "crossplane-rbac-manager"
                            namespace: "operators"
                        }
                        spec = {
                            namespaceSelector.matchNames: ["crossplane-system", "upbound-system"]
                            podMetricsEndpoints: [{port: "metrics"}]
                            selector.matchLabels.app: "crossplane-rbac-manager"
                        }
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 2 - For PodMonitor for Crossplane Operator is created"
        spec = {
            assertResources: [
                # Assert that PodMonitor for Crossplane is created
                kubernetesv1alpha1.Object {
                    apiVersion: "kubernetes.m.crossplane.io/v1alpha1"
                    kind: "Object"
                    metadata.name: "podmonitorcrossplane-test-cluster"
                    metadata.labels.type: "podMonitorCrossplane"
                    spec.forProvider.manifest = {
                        apiVersion: "monitoring.coreos.com/v1"
                        kind: "PodMonitor"
                        metadata = {
                            name: "crossplane"
                            namespace: "operators"
                        }
                        spec = {
                            namespaceSelector.matchNames: ["crossplane-system", "upbound-system"]
                            podMetricsEndpoints: [{port: "metrics"}]
                            selector.matchLabels.app: "crossplane"
                        }
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 3 - For PodMonitor for Crossplane is created"
        spec = {
            assertResources: [
                # Assert that PodMonitor for Crossplane Providers is created
                kubernetesv1alpha1.Object {
                    apiVersion: "kubernetes.m.crossplane.io/v1alpha1"
                    kind: "Object"
                    metadata.name: "podmonitorcrossplaneproviders-test-cluster"
                    metadata.labels.type: "podMonitorCrossplaneProviders"
                    spec.forProvider.manifest = {
                        apiVersion: "monitoring.coreos.com/v1"
                        kind: "PodMonitor"
                        metadata = {
                            name: "crossplane-providers"
                            namespace: "operators"
                        }
                        spec = {
                            namespaceSelector.matchNames: ["crossplane-system", "upbound-system"]
                            podMetricsEndpoints: [{port: "http-prom"}]
                            selector.matchLabels.app: "crossplane-providers"
                        }
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 4 - For Helm Release for Prometheus is created"
        spec = {
            assertResources: [
                # Assert that Prometheus Helm Release is created
                helmv1beta1.Release {
                    apiVersion: "helm.m.crossplane.io/v1beta1"
                    kind: "Release"
                    metadata.name: "releaseprometheus-test-cluster"
                    spec = {
                        forProvider = {
                            chart = {
                                name: "kube-prometheus-stack"
                                repository: "https://prometheus-community.github.io/helm-charts"
                                version: "79.1.1"
                            }
                            namespace: "operators"
                            wait: False
                            values.prometheus.prometheusSpec = {
                                podMonitorSelectorNilUsesHelmValues: False
                                probeSelectorNilUsesHelmValues: False
                                ruleSelectorNilUsesHelmValues: False
                                serviceMonitorSelectorNilUsesHelmValues: False
                            }
                        }
                        rollbackLimit: 10
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 5 - For Usage linking PodMonitor RBAC Manager to Prometheus Release"
        spec = {
            assertResources: [
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata.name: "usageprometheusbypodmonitorcrossplanerbacmanager-test-cluster"
                    spec = {
                        by = {
                            apiVersion: "kubernetes.m.crossplane.io/v1alpha1"
                            kind: "Object"
                            resourceSelector = {
                                matchControllerRef: True
                                matchLabels.type: "podMonitorCrossplaneRbacManager"
                            }
                        }
                        of = {
                            apiVersion: "helm.m.crossplane.io/v1beta1"
                            kind: "Release"
                            resourceSelector.matchControllerRef: True
                        }
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 6 - For Usage linking PodMonitor Crossplane to Prometheus Release"
        spec = {
            assertResources: [
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata.name: "usageprometheusbypodmonitorcrossplane-test-cluster"
                    spec = {
                        by = {
                            apiVersion: "kubernetes.m.crossplane.io/v1alpha1"
                            kind: "Object"
                            resourceSelector = {
                                matchControllerRef: True
                                matchLabels.type: "podMonitorCrossplane"
                            }
                        }
                        of = {
                            apiVersion: "helm.m.crossplane.io/v1beta1"
                            kind: "Release"
                            resourceSelector.matchControllerRef: True
                        }
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
    metav1alpha1.CompositionTest {
        metadata.name: "Test - 7 - For Usage linking PodMonitor Providers to Prometheus Release"
        spec = {
            assertResources: [
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata.name: "usageprometheusbypodmonitorproviders-test-cluster"
                    spec = {
                        by = {
                            apiVersion: "kubernetes.m.crossplane.io/v1alpha1"
                            kind: "Object"
                            resourceSelector = {
                                matchControllerRef: True
                                matchLabels.type: "podMonitorCrossplaneProviders"
                            }
                        }
                        of = {
                            apiVersion: "helm.m.crossplane.io/v1beta1"
                            kind: "Release"
                            resourceSelector.matchControllerRef: True
                        }
                    }
                }
            ]
            compositionPath: "apis/oss/composition.yaml"
            xrPath: "examples/xr-oss.yaml"
            xrdPath: "apis/oss/definition.yaml"
            timeoutSeconds: 120
            validate: False
        }
    }
]
items = _items
