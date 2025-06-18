
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xoss"
        spec= {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                # Create an Oss claim to test the observability stack
                {
                    apiVersion: "observe.platform.upbound.io/v1alpha1"
                    kind: "Oss"
                    metadata = {
                        name: "uptest-observability"
                        namespace: "default"
                    }
                    spec.parameters = {
                        id: "uptest-observability-oss-cluster"
                        operators.prometheus.version: "52.1.0"
                        deletionPolicy: "Delete"
                    }
                }
            ]
            extraResources: [
                # AWS EKS Configuration
                {
                    apiVersion: "pkg.crossplane.io/v1"
                    kind: "Configuration"
                    metadata.name: "configuration-aws-eks"
                    spec.package: "xpkg.upbound.io/upbound/configuration-aws-eks:v0.18.2"
                },

                # AWS Network Configuration
                {
                    apiVersion: "pkg.crossplane.io/v1"
                    kind: "Configuration"
                    metadata.name: "configuration-aws-network"
                    spec.package: "xpkg.upbound.io/upbound/configuration-aws-network:v0.24.0"
                },

                # AWS Network for EKS
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "XNetwork"
                    metadata.name: "configuration-observability-oss-network"
                    spec.parameters = {
                        id: "uptest-observability-oss-cluster"
                        region: "us-west-1"
                        vpcCidrBlock: "192.168.0.0/16"
                        subnets: [
                            {
                                availabilityZone: "us-west-1b"
                                type: "public"
                                cidrBlock: "192.168.0.0/18"
                            },
                            {
                                availabilityZone: "us-west-1c"
                                type: "public"
                                cidrBlock: "192.168.64.0/18"
                            },
                            {
                                availabilityZone: "us-west-1b"
                                type: "private"
                                cidrBlock: "192.168.128.0/18"
                            },
                            {
                                availabilityZone: "us-west-1c"
                                type: "private"
                                cidrBlock: "192.168.192.0/18"
                            }
                        ]
                    }
                },

                # EKS Cluster for testing observability stack
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "XEKS"
                    metadata.name: "configuration-observability-oss-eks"
                    spec = {
                        parameters = {
                            id: "uptest-observability-oss-cluster"
                            region: "us-west-1"
                            version: "1.27"
                            nodes = {
                                count: 1
                                instanceType: "t3.small"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name: "configuration-observability-oss-kubeconfig"
                            namespace: "upbound-system"
                        }
                    }
                },

                # AWS Provider Configuration using Upbound Web Identity
                {
                    apiVersion ="aws.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata.name: "default"
                    spec.credentials = {
                        source = "Upbound"
                        upbound = {
                            webIdentity = {
                                roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                            }
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 3600  # 60 minutes for AWS infrastructure + observability stack deployment
        }
    }
]
items= _items
