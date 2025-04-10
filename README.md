# Test

## Pre-req
### Create fine-grane token in Github
Even when in the [docs](https://fluxcd.io/flux/installation/bootstrap/github/#github-personal-account) it says only needs Administration (read-only), after checking official documentation
for Github and testing it really needs:

 - Administration (rw)
 - Contents (rw)
 - Metadata (ro)

## Deploy infra
Go to directory `infra` and source `.env`. Make sure your <<ENV>>.tfvars file exists and have all the desired values.
After that you just need to run standard TF commands
```shell
terraform init
terraform plan
```
**After planning please review the plan before applying**
```shell
terraform apply
```

## Deploy instructions

### Login to GKE
```shell
gcloud container clusters get-credentials `terraform output -raw gke_name` --zone us-central1-c --project `terraform output -raw gcp_project_name`
```
### Bootstrap flux
**Make sure you have `GITHUB_USER` and `GITHUB_TOKEN` set as env variables** (you can create a .env.secrets file)
```shell
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=symmetrical-winner \
  --path=./clusters/test/management/prod
````

### Insights 
#### Create the podinfo source file
```shell
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=1m \
  --export > ./clusters/test/apps/podinfo/source.yaml
```
#### Create kustomize base config
```shell
flux create kustomization podinfo \
  --target-namespace=cbrio \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --wait=true \
  --interval=30m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/test/management/prod/deploy.yaml
```
Once the basic file is created we need to add our patches. It should look like
```yaml
# [...]
spec:
  interval: 30m0s
  path: ./kustomize
  # [...]
  patches:
    - patch: |-
        apiVersion: autoscaling/v2
        kind: HorizontalPodAutoscaler
        metadata:
          name: podinfo
        spec:
          minReplicas: 3
      target:
        name: podinfo
        kind: HorizontalPodAutoscaler
    - patch: |-
        - op: remove
          path: "/spec/template/spec/volumes"
      target:
        name: podinfo
        kind: Deployment
    - patch: |-
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: podinfo
        spec:
          template:
            spec:
              volumes:
                - name: data
                  ephemeral:
                    volumeClaimTemplate:
                      metadata:
                        labels:
                          type: pd-standard
                      spec:
                        accessModes: [ "ReadWriteOnce" ]
                        storageClassName: "pd-standard"
                        resources:
                          requests:
                            storage: 1Gi
```
#### Storage
Due to the fact this is a test and there are certain parameters I made certain compromises on the storage. Since the PV were specifically
asked to be provisioned statically I created the `Google Disks` via terraform but then the `PVs` are created via manifest through Flux.
I could have created the disks dynamically or even through terraform but K8s provider in conjunction with GKE has certain bugs that
make it very "annoying" and reduce the repeatability of the deployment, i.e. 
    - Random calls to localhost (Error: Get "http://localhost/api/v1/persistentvolumes/podinfo-pv-0": dial tcp [::1]:80: connect: connection refused)
This is a known issue for which there are some works around but for simplicity this option was decided
```yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pd-standard
provisioner: pd.csi.storage.gke.io
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: pd-standard
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cbrio-pv-0
  finalizers:
    - kubernetes.io/pv-protection
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  storageClassName: pd-standard
  volumeMode: Filesystem
  gcePersistentDisk:
    pdName: podinfo-disk-0
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cbrio-pv-1
  finalizers:
    - kubernetes.io/pv-protection
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  storageClassName: pd-standard
  volumeMode: Filesystem
  gcePersistentDisk:
    pdName: podinfo-disk-1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cbrio-pv-2
  finalizers:
    - kubernetes.io/pv-protection
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  storageClassName: pd-standard
  volumeMode: Filesystem
  gcePersistentDisk:
    pdName: podinfo-disk-2
```