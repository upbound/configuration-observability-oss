
import models.io.crossplane.helm.v1beta1 as helmv1beta1
import models.io.crossplane.kubernetes.v1alpha2 as kubernetesv1alpha2
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.observe.platform.upbound.io.v1alpha1 as ossv1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xoss"
        spec= {
            assertResources: [
                # Assert that PodMonitor for Crossplane RBAC Manager is created
                kubernetesv1alpha2.Object{
                    apiVersion: "kubernetes.crossplane.io/v1alpha2"
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
                            podMetricsEndpoints: [{ port: "metrics" }]
                            selector.matchLabels.app: "crossplane-rbac-manager"
                        }
                    }
                },

                # Assert that PodMonitor for Crossplane is created
                kubernetesv1alpha2.Object{
                    apiVersion: "kubernetes.crossplane.io/v1alpha2"
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
                            podMetricsEndpoints: [{ port: "metrics" }]
                            selector.matchLabels.app: "crossplane"
                        }
                    }
                },

                # Assert that PodMonitor for Crossplane Providers is created
                kubernetesv1alpha2.Object{
                    apiVersion: "kubernetes.crossplane.io/v1alpha2"
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
                            podMetricsEndpoints: [{ port: "http-prom" }]
                            selector.matchLabels.app: "crossplane-providers"
                        }
                    }
                },

                # Assert that Prometheus Helm Release is created
                helmv1beta1.Release{
                    apiVersion: "helm.crossplane.io/v1beta1"
                    kind: "Release"
                    metadata.name: "releaseprometheus-test-cluster"
                    spec = {
                        forProvider = {
                            chart = {
                                name: "kube-prometheus-stack"
                                repository: "https://prometheus-community.github.io/helm-charts"
                                version: "52.1.0"
                            }
                            namespace: "operators"
                            wait: True
                            waitTimeout: "600s"
                            values.prometheus.prometheusSpec = {
                                podMonitorSelectorNilUsesHelmValues: False
                                probeSelectorNilUsesHelmValues: False
                                ruleSelectorNilUsesHelmValues: False
                                serviceMonitorSelectorNilUsesHelmValues: False
                            }
                        }
                        rollbackLimit: 3
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
items= _items
