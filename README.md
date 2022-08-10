[![PyrusLogo](https://pyrus.com/images/logo/logo_small_x2.png)](https://pyrus.com)

# Running Pyrus Datacenter on K8S

In this repository you can find an example of how to deploy Pyrus Datacenter on Kubernetes.
 * [Pyrus Datacenter Helm Chart](https://github.com/simplygoodsoftware/pyrus-datacenter-k8s/tree/main/pyrus-datacenter)

# Install example with your required parameters
```
kubectl create namespace pyrus
kubectl create secret generic pyrus-ssl  \
        --from-file=tls.crt=yourCert.crt \
        --from-file=tls.key=yourKey.key  \
        -n pyrus

helm repo add pyrus-datacenter-k8s https://simplygoodsoftware.github.io/pyrus-datacenter-k8s
helm repo update pyrus-datacenter-k8s
helm -n pyrus install pyrus-datacenter              \
  pyrus-datacenter-k8s/pyrus-datacenter             \
  --set pyrusSetupParam.adminEmail=YOURADMINEMAIL   \
  --set pyrusSetupParam.adminPass=YOURADMINPASSWORD \
  --set pyrusSetupParam.license=YOURLICENSE         \
  --set 'values-ingress-dir.tls[0].hosts[0]=YOURDOMAIN.COM'
```
