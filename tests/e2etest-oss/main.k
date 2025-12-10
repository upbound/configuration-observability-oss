import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.E2ETest {
        metadata.name: "e2etest-oss"
        spec = {
            crossplane.autoUpgrade.channel: "None"
            crossplane.version = "2.1.3-up.1"
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
                        operators.prometheus.version: "79.1.1"
                        managementPolicies: ["*"]
                    }
                }
            ]
            extraResources: [
                # AWS EKS Configuration
                {
                    apiVersion: "pkg.crossplane.io/v1"
                    kind: "Configuration"
                    metadata.name: "configuration-aws-eks"
                    spec.package: "xpkg.upbound.io/upbound/configuration-aws-eks:v2.0.0"
                }
                ##TODO: Remove this temporary inclusion after the fix is released for forbidden error.
                {
                    apiVersion: "pkg.crossplane.io/v1"
                    kind: "Configuration"
                    metadata.name: "configuration-azure-database"
                    spec.package: "xpkg.upbound.io/upbound/configuration-azure-database:v2.0.0"
                }
                # AWS Network for EKS
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "Network"
                    metadata = {
                        name: "configuration-observability-oss-network"
                        namespace: "default"
                    }
                    spec.parameters = {
                        id: "uptest-observability-oss-cluster"
                        region: "us-west-1"
                        vpcCidrBlock: "192.168.0.0/16"
                        subnets: [
                            {
                                availabilityZone: "us-west-1b"
                                type: "public"
                                cidrBlock: "192.168.0.0/18"
                            }
                            {
                                availabilityZone: "us-west-1c"
                                type: "public"
                                cidrBlock: "192.168.64.0/18"
                            }
                            {
                                availabilityZone: "us-west-1b"
                                type: "private"
                                cidrBlock: "192.168.128.0/18"
                            }
                            {
                                availabilityZone: "us-west-1c"
                                type: "private"
                                cidrBlock: "192.168.192.0/18"
                            }
                        ]
                    }
                }
                # EKS Cluster for testing observability stack
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "EKS"
                    metadata = {
                        name: "configuration-observability-oss-eks"
                        namespace: "default"
                    }
                    spec = {
                        parameters = {
                            id: "uptest-observability-oss-cluster"
                            region: "us-west-1"
                            version: "1.34"
                            nodes = {
                                count: 1
                                instanceType: "t3.small"
                            }
                        }
                    }
                }
                # AWS Provider Configuration using Upbound Web Identity
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name: "default"
                        namespace: "default"
                    }
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
            # 60 minutes for AWS infrastructure + observability stack deployment
            timeoutSeconds: 3600
        }
    }
]
items = _items
