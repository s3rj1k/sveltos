---
title: Kubernetes add-ons management for tens of clusters quick start
description: Projectsveltos extends the functionality of Cluster API with a solution for managing the installation, configuration & deletion of Kubernetes cluster add-ons.
tags:
    - Kubernetes
    - add-ons
    - helm
    - clusterapi
    - multi-tenancy
authors:
    - Gianluca Mardente
---

## What is Sveltos?

Sveltos is a set of Kubernetes controllers deployed in the management cluster. From the management cluster, it can manage add-ons and applications to multiple clusters.

## Deploy Kubernetes Add-ons

The main goal of Sveltos is to deploy add-ons in managed Kubernetes clusters. So let's see that in action.

If you want to try the projectsveltos with a **test cluster**, follow the steps below:

``` bash
$ git clone https://github.com/projectsveltos/addon-controller

$ make quickstart
```

The above will create a management cluster using [Kind](https://kind.sigs.k8s.io), deploy clusterAPI and projectsveltos,
create a workload cluster powered by clusterAPI using Docker as infrastructure provider.

!!! note
    The Sveltos Dashboard is an optional component of Sveltos. To include it in the deployment, follow the instructions found in the [dashboard](../optional/dashboard.md) section.

    **_v0.38.4_** is the first Sveltos release that includes the dashboard and it is compatible with Kubernetes **_v1.28.0_** and higher.

## Deploy Helm Charts

To deploy the Kyverno Helm chart in any Kubernetes cluster with labels _env: fv_ create this ClusterProfile instance in the management cluster:

!!! example "Example - Helm Chart"
    ```yaml
    cat > clusterprofile_kyverno.yaml <<EOF
    ---
    apiVersion: config.projectsveltos.io/v1beta1
    kind: ClusterProfile
    metadata:
      name: deploy-kyverno
    spec:
      clusterSelector:
        matchLabels:
          env: fv
      syncMode: Continuous
      helmCharts:
      - repositoryURL:    https://kyverno.github.io/kyverno/
        repositoryName:   kyverno
        chartName:        kyverno/kyverno
        chartVersion:     v3.3.3
        releaseName:      kyverno-latest
        releaseNamespace: kyverno
        helmChartAction:  Install
    EOF
    ```

## Deploy Raw YAMl/JSON

Download this file

```bash
$ wget https://raw.githubusercontent.com/projectsveltos/demos/main/httproute/gateway-class.yaml
```

which contains:

- Namespace projectcontour to run the Gateway provisioner
- Contour CRDs
- Gateway API CRDs
- Gateway provisioner RBAC resources
- Gateway provisioner Deployment

and create a Secret in the management cluster containing the contents of the downloaded file:

```bash
$ kubectl create secret generic contour-gateway-provisioner-secret \
    --from-file=contour-gateway-provisioner.yaml \
    --type=addons.projectsveltos.io/cluster-profile
```

To deploy all these resources in any cluster with labels *env: fv*, create a ClusterProfile instance in the management cluster referencing the Secret created above:

!!! example "Example - Raw Yaml/Json"
    ```yaml
    cat > clusterprofile_gateway.yaml <<EOF
    ---
    apiVersion: config.projectsveltos.io/v1beta1
    kind: ClusterProfile
    metadata:
      name: gateway-configuration
    spec:
      clusterSelector:
        matchLabels:
          env: fv
      syncMode: Continuous
      policyRefs:
      - name: contour-gateway-provisioner-secret
        namespace: default
        kind: Secret
    EOF
    ```

## Deploy Resources Assembled with Kustomize

Sveltos can work along with Flux to deploy content of Kustomize directories.

!!! example "Example - Kustomize"
    ```yaml
    cat > clusterprofile_flux.yaml <<EOF
    ---
    apiVersion: config.projectsveltos.io/v1beta1
    kind: ClusterProfile
    metadata:
      name: flux-system
    spec:
      clusterSelector:
        matchLabels:
          env: fv
      syncMode: Continuous
      kustomizationRefs:
      - namespace: flux-system
        name: flux-system
        kind: GitRepository
        path: ./helloWorld/
        targetNamespace: eng
    EOF
    ```

Full examples can be found [here](../../addons/kustomize.md).

ClusterProfile can reference:

1. GitRepository (synced with flux);
2. OCIRepository (synced with flux);
3. Bucket (synced with flux);
4. ConfigMap whose BinaryData section contains __kustomize.tar.gz__ entry with tar.gz of kustomize directory;
5. Secret (type addons.projectsveltos.io/cluster-profile) whose Data section contains __kustomize.tar.gz__ entry with tar.gz of kustomize directory;

## Carvel ytt and Jsonnet
Sveltos offers support for Carvel ytt and Jsonnet as tools to define add-ons that can be deployed in a managed cluster. For additional information, please consult the [Carvel ytt](../../template/ytt_extension.md) and [Jsonnet](../../template/jsonnet_extension.md) sections.
