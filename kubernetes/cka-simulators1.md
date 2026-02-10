# CKA 一模考试总结

## Question 1 | Contexts

原题：
---
You're asked to extract the following information out of kubeconfig file `/opt/course/1/kubeconfig` on `cka9412`:
- Write all kubeconfig **context names** into `/opt/course/1/contexts`, one per line
- Write the **name** of the current context into `/opt/course/1/current-context`
- Write the **client-certificate** of user `account-0027` ***base64-decoded*** into `/opt/course/1/cert`

解析:
---
1. 通过 --kubeconfig  或者 环境变量KUBE_CONFIG 可以指定 config 的位置,默认在 .kube/config.
2. 通过 kubectl config --help 可以获得帮助提示

答案:
```bash 
export KUBE_CONFIG=/opt/course/1/kubeconfig
# step1 获取所有 context
k config get-contexts -o name > /opt/course/1/contexts
# step2 获取当前 context
k config current-context > /opt/course/1/current-context
# step3 获取客户端证书并 base64 解码
K config view --raw -o jsonPath='{.users[0].user.client-certificate-data}'|base64 -d  >  /opt/course/1/cert
```

## Question 2 | MinIO Operator, CRD Config, Helm Install

原题:
--- 
Install the MinIO Operator using Helm in Namespace minio. Then configure and create the Tenant CRD:

- Create Namespace `minio`
- Install Helm chart `minio/operator` into the new Namespace. The Helm Release should be called `minio-operator`
- Update the `Tenant` resource in `/opt/course/2/minio-tenant.yaml` to include `enableSFTP: true` under features
- Create the `Tenant` resource from `/opt/course/2/minio-tenant.yaml`

>tips: It is not required for MinIO to run properly. Installing the Helm Chart and the Tenant resource as requested is enough

解析:
---

答案:
---
```bash
# step1 创建 namespace
+ k create ns minio
# step2 查看仓库
+ helm repo list
# step3 查找minio operator
+ helm search repo
# step4 安装 minio/operator 
+ helm -n minio install minio-operator minio/operator
# step4 查询 telnet crd 
+ k describe crd telnet
```


## Question 3 | Scale down StatefulSet
原题：
---
There are two Pods named `o3db-*` in Namespace `project-h800`. The Project H800 management asked you to scale these down to one replica to save resources.

解析:
---
---
答案:
```bash

```


## Question 4 | Find Pods first to be terminated

原题：
---
Check all available Pods in the Namespace `project-c13` and find the names of those that would probably be terminated first if the nodes run out of resources (cpu or memory).

Write the Pod names into `/opt/course/4/pods-terminated-first.txt`.

解析:
---


答案:
---
```bash

```
```yml

```


## Question 5 | Kustomize configure HPA Autoscaler

原题:
---
Previously the application `api-gateway` used some external autoscaler which should now be replaced with a ***HorizontalPodAutoscaler (HPA)***. The application has been deployed to Namespaces `api-gateway-staging` and `api-gateway-prod` like this:

`kubectl kustomize /opt/course/5/api-gateway/staging | kubectl apply -f -`
`kubectl kustomize /opt/course/5/api-gateway/prod | kubectl apply -f -`
Using the Kustomize config at `/opt/course/5/api-gateway` do the following:

Remove the ConfigMap horizontal-scaling-config completely

Add HPA named api-gateway for the Deployment api-gateway with min 2 and max 4 replicas. It should scale at 50% average CPU utilisation

In prod the HPA should have max 6 replicas

Apply your changes for staging and prod so they're reflected in the cluster

解析:
---

答案:
---

```bash
```


## Question 6 | Storage, PV, PVC, Pod volume

原题:
---
Create a new PersistentVolume named `safari-pv`. It should have a capacity of` 2Gi`, accessMode `ReadWriteOnce`, hostPath `/Volumes/Data` and **no** storageClassName defined.

Next create a new PersistentVolumeClaim in Namespace `project-t230` named `safari-pvc` . It should request `2Gi` storage, accessMode `ReadWriteOnce` and should **not** define a storageClassName. The PVC should bound to the PV correctly.

Finally create a new Deployment safari in Namespace `project-t230` which mounts that volume at `/tmp/safari-data`. The Pods of that Deployment should be of image `httpd:2-alpine`.

解析:
---

答案:
---
```bash

```

## Question 7 | Node and Pod Resource Usage
原题:
---
The metrics-server has been installed in the cluster. Write two bash scripts which use kubectl:

- Script `/opt/course/7/node.sh` should show resource usage of nodes
- Script `/opt/course/7/pod.sh` should show resource usage of Pods and their containers

解析:
---


答案:
---
```bash

```

## Question 8 | Update Kubernetes Version and join cluster
原题:
---
Your coworker notified you that node `cka3962-node1` is running an older Kubernetes version and is not even part of the cluster yet.

1. Update the node's Kubernetes to the exact version of the controlplane
2. Add the node to the cluster using kubeadm

> tips: You can connect to the worker node using ssh cka3962-node1 from cka3962

解析:
---


答案:
---
```bash
```


## Question 9 | Contact K8s Api from inside Pod
原题:
---
There is ServiceAccount secret-reader in Namespace project-swan. Create a Pod of image `nginx:1-alpine` named `api-contact` which uses this ServiceAccount.

Exec into the Pod and use curl to manually query all Secrets from the Kubernetes Api.

Write the result into file `/opt/course/9/result.json`.

解析:
---

答案:
---
```bash

```


## Question 10 | RBAC ServiceAccount Role RoleBinding
原题:
---
Create a new **ServiceAccount** `processor` in Namespace `project-hamster`. Create a Role and RoleBinding, both named `processor` as well. These should allow the new SA to only create **Secrets** and **ConfigMaps** in that Namespace.

解析:
---



答案:
---



## Question 11 | DaemonSet on all Nodes
原题:
---

Use Namespace `project-tiger` for the following. Create a DaemonSet named `ds-important` with image `httpd:2-alpine` and labels `id=ds-important` and `uuid=18426a0b-5f59-4e10-923f-c0e078e82462`. The Pods it creates should request **10 millicore cpu** and **10 mebibyte memory**. The Pods of that DaemonSet should run on all nodes, also **controlplanes**.

解析:
---



答案:
---


## Question 12 | Schedule Pod on Controlplane Nodes
原题:
---
Implement the following in Namespace `project-tiger`:
- Create a Deployment named `deploy-important` with `3` replicas
- The Deployment and its Pods should have label `id=very-important`
- First container named `container1` with image `nginx:1-alpine`
- Second container named `container2` with image `google/pause`
- There should only ever be one Pod of that Deployment running on one worker node, use `topologyKey: kubernetes.io/hostname` for this

解析:
---


答案:
---
```bash

```


## Question 13 | Gateway Api Ingress
 
原题:
---
The team from Project r500 wants to replace their Ingress (networking.k8s.io) with a Gateway Api (gateway.networking.k8s.io) solution. The old Ingress is available at `/opt/course/13/ingress.yaml`.

Perform the following in Namespace `project-r500` and for the already existing Gateway:

Create a new ***HTTPRoute*** named `traffic-director` which replicates the routes from the old Ingress

Extend the new ***HTTPRoute*** with path `/auto` which redirects to mobile if the User-Agent is exactly `mobile` and to desktop otherwise

The existing Gateway is reachable at `http://r500.gateway:30080` which means your implementation should work for these commands:

```bash
curl r500.gateway:30080/desktop
curl r500.gateway:30080/mobile
curl r500.gateway:30080/auto -H "User-Agent: mobile" 
curl r500.gateway:30080/auto
```
解析:
---


答案:
---

## Question 14 | Check how long certificates are valid
原题:
---

Perform some tasks on cluster certificates:

Check how long the kube-apiserver server certificate is valid using openssl or cfssl. Write the expiration date into `/opt/course/14/expiration`. Run the kubeadm command to list the expiration dates and confirm both methods show the same one

Write the `kubeadm` command that would renew the kube-apiserver certificate into `/opt/course/14/kubeadm-renew-certs.sh`

解析:
---




答案:
---
```bash

```

## Question 15 | NetworkPolicy
原题:
---
There was a security incident where an intruder was able to access the whole cluster from a single hacked backend Pod.

To prevent this create a NetworkPolicy called `np-backend` in Namespace `project-snake`. It should allow the `backend-*` Pods only to:

- Connect to `db1-*` Pods on port `1111`
- Connect to `db2-*` Pods on port `2222`

Use the app Pod labels in your policy.


>tips: All Pods in the Namespace run plain Nginx images. This allows simple connectivity tests like: k -n project-snake exec POD_NAME -- curl POD_IP:PORT

解析:
---


答案:
---
```bash

```

## Question 16 | Update CoreDNS Configuration
 
原题:
---
The CoreDNS configuration in the cluster needs to be updated:

Make a backup of the existing configuration Yaml and store it at `/opt/course/16/coredns_backup.yaml`. You should be able to fast recover from the backup

Update the CoreDNS configuration in the cluster so that DNS resolution for `SERVICE.NAMESPACE.custom-domain` will work exactly like and in addition to `SERVICE.NAMESPACE.cluster.local`

Test your configuration for example from a Pod with `busybox:1` image. These commands should result in an IP address:

```bash
nslookup kubernetes.default.svc.cluster.local
nslookup kubernetes.default.svc.custom-domain
```

解析:
---


答案:
---
```bash

```

## Question 17 | Find Container of Pod and check info
原题:
---
In Namespace `project-tiger` create a Pod named `tigers-reunite` of image `httpd:2-alpine` with labels `pod=container` and `container=pod`. Find out on which node the Pod is scheduled. Ssh into that node and find the containerd container belonging to that Pod.

Using command `crictl`:
1. Write the ID of the container and the `info.runtimeType` into `/opt/course/17/pod-container.txt`
2. Write the logs of the container into `/opt/course/17/pod-container.log`

>tips: You can connect to a worker node using ssh cka2556-node1 or ssh cka2556-node2 from cka2556


解析:
---


答案:
---
```bash


```

## Preview Question 1 | ETCD Information
原题:
---
The cluster admin asked you to find out the following information about etcd running on `cka9412`:

- Server private key location
- Server certificate expiration date
- Is client certificate authentication enabled

Write these information into `/opt/course/p1/etcd-info.txt`


解析:
---


答案:
---
```bash


```

## Preview Question 2 | Kube-Proxy iptables


You're asked to confirm that kube-proxy is running correctly. For this perform the following in Namespace `project-hamster`:

Create Pod `p2-pod` with image `nginx:1-alpine`

Create Service `p2-service` which exposes the Pod internally in the cluster on port `3000->80`

Write the iptables rules of node `cka2556` belonging the created Service `p2-service` into file `/opt/course/p2/iptables.txt`

Delete the Service and confirm that the iptables rules are gone again


## Preview Question 3 | Change Service CIDR

1. Create a Pod named `check-ip` in Namespace `default` using image `httpd:2-alpine`
2. Expose it on port `80` as a ClusterIP Service named `check-ip-service`. Remember/output the IP of that Service
3. Change the Service CIDR to `11.96.0.0/12` for the cluster
4. Create a second Service named `check-ip-service2` pointing to the same Pod


解析:
---


答案:
---
```bash


```
