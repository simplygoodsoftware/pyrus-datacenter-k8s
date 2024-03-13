[![PyrusLogo](https://pyrus.com/images/logo/logo_small_x2.png)](https://pyrus.com)

# Running Pyrus Datacenter on K8S

In this repository you can find an example of how to deploy Pyrus Datacenter on Kubernetes.
 * [Pyrus Datacenter Helm Chart](https://github.com/simplygoodsoftware/pyrus-datacenter-k8s/tree/main/pyrus-datacenter)

# Getting started with Pyrus using Helm

Pyrus Datacenter can be installed in just a few following steps:
```
kubectl create namespace pyrus
kubectl create secret generic pyrus-ssl  \
        --from-file=tls.crt=yourCert.crt \
        --from-file=tls.key=yourKey.key  \
        -n pyrus

helm repo add pyrus-datacenter-k8s https://simplygoodsoftware.github.io/pyrus-datacenter-k8s
helm repo update pyrus-datacenter-k8s

## Install command
helm -n pyrus install pyrus-datacenter              \
  pyrus-datacenter-k8s/pyrus-datacenter             \
  --set pyrusSetupParam.adminEmail=YOURADMINEMAIL   \
  --set pyrusSetupParam.adminPass=YOURADMINPASSWORD \
  --set pyrusSetupParam.license=LICENSE             \
  --set 'values-ingress-dir.tls[0].hosts[0]=YOURDOMAIN'
```

If you want to force version of containers, use next example install command:
```
helm -n pyrus install pyrus-datacenter              \
  pyrus-datacenter-k8s/pyrus-datacenter             \
  --set tagsContainers.All=1.12.0                   \
  --set pyrusSetupParam.adminEmail=YOURADMINEMAIL   \
  --set pyrusSetupParam.adminPass=YOURADMINPASSWORD \
  --set pyrusSetupParam.license=LICENSE             \
  --set 'values-ingress-dir.tls[0].hosts[0]=YOURDOMAIN' \
## version tagsContainers.All=1.12.1 and greater also required S3
  --set pyrusSetupParam.s3.keyId=YOURKEY            \
  --set pyrusSetupParam.s3.secretKey=YOURSECRETKEY  \
  --set pyrusSetupParam.s3.buket=YOURBACKET         \
  --set pyrusSetupParam.s3.storageType=YOURTYPE     \  ## choose options: Aws, MinIo, Azure
  --set pyrusSetupParam.s3.S3_BLOB_STORAGE_ENDPOINT=YOURS3ENDPOINT
```

If you have values settings file from our company you just do next install command:
```
helm -n pyrus install pyrus-datacenter              \
  pyrus-datacenter-k8s/pyrus-datacenter             \
  -f pyrus.values.yaml
```

Example to update to version 1.8.0
```
helm -n pyrus upgrade pyrus-datacenter                   \
  pyrus-datacenter-k8s/pyrus-datacenter                  \
  --set pyrusSetupParam.adminEmail=YOURADMINEMAIL        \
  --set pyrusSetupParam.adminPass=YOURADMINPASSWORD      \
  --set pyrusSetupParam.license=LICENSE                  \
  --set 'values-ingress-dir.tls[0].hosts[0]=YOURDOMAIN'  \
  --set 'values-ingress-dir.secretNameDefault=pyrus-ssl' \
  --set tagsContainers.All=1.8.0                         \
  --reset-values
```
DO NOT FORGET TO REDEFINE YOURE VARIABLES AND CALL --reset-values

For a detailed explanation on installation parameters please refer to the [README](https://github.com/simplygoodsoftware/pyrus-datacenter-k8s/tree/main/pyrus-datacenter) document.
