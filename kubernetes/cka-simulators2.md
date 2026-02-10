# CKA 二模考试总结

## Question 1 | DNS / FQDN / Headless Service

原题：
---
The Deployment controller in Namespace `lima-control` communicates with various cluster internal endpoints by using their DNS FQDN values.
Update the ConfigMap used by the Deployment with the correct FQDN values for:
1. DNS_1: Service `kubernetes` in Namespace `default`
2. DNS_2: Headless Service `department` in Namespace `lima-workload`
3. DNS_3: Pod `section100` in Namespace `lima-workload`. It should work even if the Pod IP changes
4. DNS_4: A Pod with IP `1.2.3.4` in Namespace `kube-system` Ensure the Deployment works with the updated values.

解析:
---
考察K8S DNS解析规则:

1. 想跨 Namespace 访问service 那么请求 [service].[namespace].svc.cluster.local: kubernetes.default.svc.cluster.local。
2. headless同第一点,但是第一点解析出来是service IP,headless 解析出来详细的PodIP。
3. 想特定访问 service 中具体的实例,需要修改subDomain 和serviceName 一致，然后使用hostname 访问。
4. 即使ip不存在对应实例，也可以通过ip.namespace.pod.cluster.local访问：1-2-3-4.kube-system.pod.cluster.local

答案:
```bash 
# 找到需要修改的 configMap 修改保存
k -n lima-control edit cm control-config

DNS_1: kubernetes.default.svc.cluster.local
DNS_2: department.lima-workload.svc.cluster.local
DNS_3: section100.section.lima-workload.svc.cluster.local
DNS_4: 1-2-3-4.kube-system.pod.cluster.local
```

```yml
apiVersion: v1
data:
  DNS_1: kubernetes.default.svc.cluster.local                  # UPDATE
  DNS_2: department.lima-workload.svc.cluster.local            # UPDATE
  DNS_3: section100.section.lima-workload.svc.cluster.local    # UPDATE
  DNS_4: 1-2-3-4.kube-system.pod.cluster.local                 # UPDATE
kind: ConfigMap
metadata:
  name: control-config
  namespace: lima-control
```

## Question 2 | Create a Static Pod and Service

原题:
--- 
Create a `Static Pod` named `my-static-pod` in Namespace `default` on the controlplane node. It should be of image `nginx:1-alpine` and have resource requests for `10m` CPU and `20Mi` memory.

Create a `NodePort` Service named `static-pod-service` which exposes that static Pod on port `80`.

解析:
---
1. 要熟练掌握 `k run [podName] -o yaml --dry-run=client` 快速生成 pod 模板,
2. 以及 `k expose pod [podName] --name=[svcName]` 快速创建service。
3. static pod 指的是,yaml文件放在 `/etc/kubernetes/manifest`中的pod,k8s 的api-server,etcd,controller-manager,kube-scheduler 都是这么创建的,一般该目录pod 无需apply 。

答案:
---
```bash
# step1 切换成root 账号, cka考试使用 ubuntu 
+ sodo -i
# step2 使用答案生成初始化模板
+ k run my-static-pod --image=nginx:1-alpine -o yaml --dry-run=client > /etc/kubernetes/manifest/my-static-pod.yaml
# step3 修改 resources.requests.cpu/memory
+ vim /etc/kubernetes/manifest/my-static-pod.yaml 
# step4 查看pod状态,default namespace 可以不写 -n default
+ k get po
# step5 快速创建 service,static pod 创建时名称会自动带上后缀 -cka2560 要加上
k expose pod my-static-pod-cka2560 --name=static-pod-service --type=NodePort --port=80
```

```yml
# cka2560:/etc/kubernetes/manifests/my-static-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: my-static-pod
  name: my-static-pod
spec:
  containers:
  - image: nginx:1-alpine
    name: my-static-pod
    resources:
      requests:
        cpu: 10m
        memory: 20Mi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

## Question 3 | Kubelet client/server cert info
原题：
---
Node `cka5248-node1` has been added to the cluster using kubeadm and TLS bootstrapping.
Find the `Issuer` and `Extended Key Usage` values on `cka5248-node1` for:

- `Kubelet Client Certificate`, the one used for outgoing connections to the `kube-apiserver`
- `Kubelet Server Certificate`, the one used for incoming connections from the `kube-apiserver`

Write the information into file `/opt/course/3/certificate-info.txt`.


解析:
---
1. kubenetes 证书使用 x509 规范生成,使用openssl 查看颁发者和扩展使用,
2. 需要获取kubelet 证书,通过`systemctl status kubelet`可以看到依赖证书在`/var/lib/kubelet/pki`,客户端证书是:`/var/lib/kubelet/pki/kubelet-client-current.pem`, 服务端证书是:`/var/lib/kubelet/pki/kubelet.crt`。
3. 查看证书信息答案: `openssl x509 -in [证书文件] -text -noout`
4. 对于集群节点信息查看这种动作,一定要切换到 root 权限。
---
答案:
```bash
# step 1 登录到 node1节点
ssh cka5248-node1
# step 2 切换成root
sudo -i
# step 3 查看客户端证书
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout
# step 4 查看服务端证书
openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout
```


## Question 4 | Pod Ready if Service is reachable

原题：
---
Do the following in Namespace default:
- Create a Pod named `ready-if-service-ready` of image `nginx:1-alpine`
- Configure a LivenessProbe which simply executes command `true`
- Configure a ReadinessProbe which does check if the url `http://service-am-i-ready:80` is reachable, you can use `wget -T2 -O- http://service-am-i-ready:80` for this
- Start the Pod and confirm it isn't ready because of the ReadinessProbe.

Then:
- Create a second Pod named `am-i-ready` of image `nginx:1-alpine`with label id: `cross-server-ready`
- The already existing Service `service-am-i-ready` should now have that second Pod as endpoint
- Now the first Pod should be in ready state, check that

解析:
---
- 通过 [k run](#解析-1) 快速创建pod模板
- 设置健康检查为执行答案,并且返回true,怎么简单怎么来如: echo "ok"，pwd 都可以
- 设置就绪检查执行答案,为了提高做题时间 建议 ["sh","-c","wget -T2 -O- http://service-am-i-ready:80"],这样最容易复制
- 同样使用 [k run](#解析-1) 快速创建 am-i-ready pod，因为没有需要通过编辑设置的属性,所以可以不必 dry-run

答案:
---
```bash
# step1 要dry-run 因为健康检查和就绪检查要编辑 yaml 设置
k run ready-if-service-ready --image=nginx:1-alpine --dry-run=client -o yaml > ready-if-service-ready.yaml
# step2 编辑yaml 健康检查和就绪检查 并apply 
k apply -f ready-if-service-ready.yaml
# step3 查看pod 状态 应该是running 但不 ready
k get po
# step4 创建第二个pod 直接使用k run
k run am-i-ready --image=nginx:1-alpine -l id=cross-server-ready
# 检查 ready-if-service-ready 是否ready 状态
k get po ready-if-service-ready
```
```yml

```


## Question 5 | Kubectl sorting

原题:
---

Create two bash script files which use kubectl sorting to:

- Write a command into `/opt/course/5/find_pods.sh` which lists all Pods in all Namespaces sorted by their AGE (`metadata.creationTimestamp`)

- Write a command into `/opt/course/5/find_pods_uid.sh` which lists all Pods in all Namespaces sorted by field `metadata.uid`

解析:
---

1. 答案里要使用 `kubectl`,alias 不起作用
2. 使用答案先测试效果,注意--sort-by 要有`.`(没有不影响答案结果，但影响判题)
3. 直接使用 echo [command] > [file] 修改文件
4. 修改完记得校验

答案:
---

```bash
# STEP 1 获取 pod 按照 age 排序
echo "kubectl get po --sort-by=.metadata.creationTimestamp" > /opt/course/5/find_pods.sh 
# STEP 2 获取 pod 按照 uid 排序
echo "kubectl get po --sort-by=.metadata.uid" > /opt/course/5/find_pods_uid.sh
```


## **Question 6 | Fix Kubelet**  
>***排错题定位困难，要结合linux 基础知识做出判断，要花时间仔细研究***

原题:
---
There seems to be an issue with the kubelet on controlplane node `cka1024`, it's not running.
Fix the kubelet and confirm that the node is available in Ready state.
Create a Pod called `success` in `default` Namespace of image `nginx:1-alpine`.

解析:
---
1. 错误排查结果通常不复杂,要掌握具体方式方法
2. kubelet 通常使用linux systemd 控制,系统管理服务的调试技巧要充分了解
答案:
---
```bash
# step1 查看一下集群状态 无法显示集群节点集群异常
+ k get no

E0423 12:27:08.326639   12871 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.100.41:6443/api?timeout=32s\": dial tcp 192.168.100.41:6443: connect: connection refused"
E0423 12:27:08.329430   12871 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.100.41:6443/api?timeout=32s\": dial tcp 192.168.100.41:6443: connect: connection refused"
# 查看一下kubelet 状态, inactive, service 文件在 /usr/lib/systemd/system/kubelet.service,配置文件在 /usr/lib/systemd/system/kubelet.service.d
+ systemctl status kubelet

kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: inactive (dead) since Sun 2025-03-23 08:16:52 UTC; 1 month 0 days ago
   Duration: 2min 46.830s
       Docs: https://kubernetes.io/docs/
   Main PID: 7346 (code=exited, status=0/SUCCESS)
        CPU: 5.956s
# 尝试启动失败, 报错 Failed with result 'exit-code'，进程尝试从 /usr/local/bin/kubelet 启动kubelet
+ systemctl start kubelet 

● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: activating (auto-restart) (Result: exit-code) since Wed 2025-04-23 12:31:07 UTC; 2s ago
       Docs: https://kubernetes.io/docs/
    Process: 13014 ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EX>
   Main PID: 13014 (code=exited, status=203/EXEC)
        CPU: 10ms

Apr 23 12:31:07 cka1024 systemd[1]: kubelet.service: Failed with result 'exit-code'.
# 尝试查看一下kubelet 可执行文件所在路径,发现路径填写错误
+ type kubelet 

kubelet is /usr/bin/kubelet
# 调整配置文件   /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf 修改为 /usr/bin/kubelet 启动服务,启动成功
+ systemctl start kubelet 
# 部署success pod 
+ k run success --image nginx:1-alpine
```

## Question 7 | Etcd Operations
原题:
---
You have been tasked to perform the following etcd operations:

1. Run `etcd --version` and store the output at `/opt/course/7/etcd-version`
2. Make a snapshot of etcd and save it at `/opt/course/7/etcd-snapshot.db`

解析:
---
1. 通常 etcd 集成是以static pod 部署于容器中的,可通过 `kubectl exec` 执行etcd --version,如果安装在物理机器上则直接执行
2. etcd 备份通常借用etcd 客户端

答案:
---
```bash
# etcd 在容器中,直接执行
k exec -it etcd-cka2560 -n kube-system -- etcd --version > /opt/course/7/etcd-version
# etcd 备份需要认证相关证书,切换root 操作
sudo -i
# etcd 备份命令
etcdctl snapshot save /opt/course/7/etcd-snapshot.db \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key
```

## Question 8 | Get Controlplane Information
原题:
---
Check how the controlplane components kubelet, kube-apiserver, kube-scheduler, kube-controller-manager and etcd are started/installed on the controlplane node.

Also find out the name of the DNS application and how it's started/installed in the cluster.

Write your findings into file `/opt/course/8/controlplane-components.txt`. The file should be structured like:
```bash
# /opt/course/8/controlplane-components.txt
kubelet: [TYPE]
kube-apiserver: [TYPE]
kube-scheduler: [TYPE]
kube-controller-manager: [TYPE]
etcd: [TYPE]
dns: [TYPE] [NAME]
```
Choices of [TYPE] are: not-installed, process, static-pod, pod

解析:
---
1. 一般kubelet 肯定是系统进程systemd安装,验证命令 systemctl status kubelet
2. static pod 安装可查看 kube-system 的组件,带cka-8448的pod 就是
3. dns 一般为coreDNS 并且deployment 安装

答案:
---
```bash
# 切换到root 账号,
sudo -i
# 查看kubelet 安装详情
+ systemctl status kubelet 

● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Sun 2024-12-08 16:10:53 UTC; 1h 6min ago
       Docs: https://kubernetes.io/docs/
   Main PID: 7355 (kubelet)
      Tasks: 11 (limit: 1317)
     Memory: 69.0M (peak: 75.9M)
        CPU: 1min 58.582s
     CGroup: /system.slice/kubelet.service
             └─7355 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet>
# 查看 kube-system 安装信息,可知coredns 是deployment 其他都是static-pod
+ k -n kube-system get all 


# 确认后输出内容
cat <<EOF > /opt/course/8/controlplane-components.txt
# /opt/course/8/controlplane-components.txt
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coreDNS
EOF 
```


## Question 9 | Kill Scheduler, Manual Scheduling
原题:
---
**Temporarily** stop the kube-scheduler, this means in a way that you can start it again afterwards.

Create a single Pod named `manual-schedule` of image `httpd:2-alpine`, confirm it's created but not scheduled on any node.

Now you're the scheduler and have all its power, manually schedule that Pod on node `cka5248`. Make sure it's running.

Start the kube-scheduler again and confirm it's running correctly by creating a second Pod named `manual-schedule2` of image `httpd:2-alpine` and check if it's running on `cka5248-node1`.

解析:
---
1. 此处要编辑/etc/kubernetes/manifest 文件，切换到root 账号
2. 临时关闭kube-schedule 可以将 /etc/kubernetes/manifest/kube-scheduler.yaml 改名为 /etc/kubernetes/manifest/kube-scheduler.yaml.off
3. 需要熟练使用创建模板创建,并且不要在 /etc/kubernetes/manifest 避免被解析成static-pod
4. 手动通过修改 pod.spec.nodeName 实现手动scheduler
5. 恢复scheduler 文件之后，运行pod 查看最终调度情况
答案:
---
```bash
# 切换到root 
sudo -i
# 转移kubeschedule 文件
mv  /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/kube-scheduler.yaml 
# 使用k run 运行容器
k run manual-schedule --image=httpd:2-alpine
# 编辑 pod 指定调度node 
k edit po manual-schedule
# 恢复 kubeScheduler 
mv /tmp/kube-scheduler.yaml  /etc/kubernetes/manifests/kube-scheduler.yaml 
# 创建 manual-schedule2 pod
k run manual-schedule2 --image=httpd:2-alpine
# 查看调度情况
k get po -o wide 
```
```yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2020-09-04T15:51:02Z"
  labels:
    run: manual-schedule
  managedFields:
...
    manager: kubectl-run
    operation: Update
    time: "2020-09-04T15:51:02Z"
  name: manual-schedule
  namespace: default
  resourceVersion: "3515"
  selfLink: /api/v1/namespaces/default/pods/manual-schedule
  uid: 8e9d2532-4779-4e63-b5af-feb82c74a935
spec:
  nodeName: cka5248       # ADD the controlplane node name
  containers:
  - image: httpd:2-alpine
    imagePullPolicy: IfNotPresent
    name: manual-schedule
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-nxnc7
      readOnly: true
  dnsPolicy: ClusterFirst
```

## Question 10 | PV PVC Dynamic Provisioning
原题:
---
There is a backup Job which needs to be adjusted to use a PVC to store backups.

Create a StorageClass named `local-backup` which uses `provisioner: rancher.io/local-path` and `volumeBindingMode: WaitForFirstConsumer`. To prevent possible data loss the StorageClass should keep a PV `retained` even if a bound PVC is deleted.

Adjust the Job at `/opt/course/10/backup.yaml` to use a PVC which request `50Mi` storage and uses the new StorageClass.

Deploy your changes, verify the Job completed once and the PVC was bound to a newly created PV.

> To re-run a Job, delete it and create it again

>  The abbreviation PV stands for PersistentVolume and PVC for PersistentVolumeClaim

解析:
---
1. 通过kuberentes 官网获取到storageClass 和 PVC 创建模板
2. 特别注意storageClass 的apiVersion: storage.k8s.io/v1 pv 和pvc 是v1
3. 要把所有条件情况看清楚，特别注意着重号，加粗等内容
4. 本题提供两点建议： 
    1. 如何重跑job
    2. pv 指的是PersistentVolume而pvc指的是PersistentVolume


答案:
---
> 整理yaml 如下
- storageClass.yaml
```yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-backup
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```
- PersistentVolumeClaim.yaml
```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: project-bern            # 要和job 处于同一个namespace
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi                  # 按照要求的容量
  storageClassName: local-backup     # 按照要求使用对应sc
```
- backup.yaml
```yml
apiVersion: batch/v1
kind: Job
metadata:
  name: backup
  namespace: project-bern
spec:
  backoffLimit: 0
  template:
    spec:
      volumes:
        - name: backup
          persistentVolumeClaim:     # 使用pvc 修改使用
            claimName: backup-pvc    # 与pvc名称相同
      containers:
        - name: bash
          image: bash:5
          command:
            - bash
            - -c
            - |
              set -x
              touch /backup/backup-$(date +%Y-%m-%d-%H-%M-%S).tar.gz
              sleep 15
          volumeMounts:
            - name: backup
              mountPath: /backup
      restartPolicy: Never
```
apply 所有文件即可


## Question 11 | Create Secret and mount into Pod
原题:
---
Create Namespace `secret` and implement the following in it:

- Create Pod `secret-pod` with image `busybox:1`. It should be kept running by executing `sleep 1d` or something similar
- Create the existing Secret `/opt/course/11/secret1.yaml` and mount it **readonly** into the Pod at `/tmp/secret1`
- Create a new Secret called secret2 which should contain `user=user1` and `pass=1234`. These entries should be available inside the Pod's container as environment variables `APP_USER` and `APP_PASS`

解析:
---
1. 先创建 namespace 
2. 通过 [k run](#解析-1)创建模板,并修改启动命令 `sleep 1d`
3. 在修改 `/opt/course/11/secret1.yaml` 的metadata.namespace 属性,apply。
4. 通过volume形式引用Secret1,通过 valueFrom.secretKeyRef 形式引用secret2。


答案:
---
```bash
# step1 创建namespace
k create ns secret
# step2 创建pod.yaml
k -n secret run secret-pod --image=busybox:1 --dry-run=client -o yaml -- sh -c "sleep 1d" > secret-pod.yaml
# step3 创建 secret2 
k -n secret create secret generic secret2 --from-literal=user=user1 --from-literal=pass=1234
# step4 修改yaml 并apply 
k apply -f secret1.yaml  secret-pod.yaml
```

- secret 1 和 podyaml 如下
```yaml
# secret1
apiVersion: v1
data:
  halt: IyEgL2Jpbi9zaAo...
kind: Secret
metadata:
  creationTimestamp: null
  name: secret1
  namespace: secret  
---
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: secret-pod
  name: secret-pod
  namespace: secret                       # important if not automatically added
spec:
  containers:
  - args:
    - sh
    - -c
    - sleep 1d
    image: busybox:1
    name: secret-pod
    resources: {}
    env:                                  # add
    - name: APP_USER                      # add
      valueFrom:                          # add
        secretKeyRef:                     # add
          name: secret2                   # add
          key: user                       # add
    - name: APP_PASS                      # add
      valueFrom:                          # add
        secretKeyRef:                     # add
          name: secret2                   # add
          key: pass                       # add
    volumeMounts:                         # add
    - name: secret1                       # add
      mountPath: /tmp/secret1             # add
      readOnly: true                      # add
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:                                # add
  - name: secret1                         # add
    secret:                               # add
      secretName: secret
```

## Question 12 | Schedule Pod on Controlplane Nodes
原题:
---
Create a Pod of image `httpd:2-alpine` in Namespace `default`.

The Pod should be named `pod1` and the container should be named `pod1-container`.

This Pod should **only** be scheduled on controlplane nodes.

Do **not** add new labels to any nodes.

解析:
---
1. 使用[k run](#解析-1) 快速创建pod 模板,并修改container name为 pod1-container
2. 将 pod 设置 nodeSelector（单条件支持key-value匹配）或者nodeAffinity(多条件支持操作符匹配(Exist，in))
3. 设置tolerations 容忍 `key=node-role.kubernetes.io/control-plane`，`effect=NoSchedule`

答案:
---
```bash
# step 1
k run pod1 --image=httpd:2-alpine > pod1.yaml
# step 修改yaml 如下并apply
k apply -f pod1.yaml
```

```yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: httpd:2-alpine
    name: pod1-container                       # change
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:                                 # add
  - effect: NoSchedule                         # add
    key: node-role.kubernetes.io/control-plane # add
  nodeSelector:                                # add
    node-role.kubernetes.io/control-plane: ""  # add
status: {}
```

## Question 13 | Multi Containers and Pod shared Volume
原题:
---
Create a Pod with multiple containers named `multi-container-playground` in Namespace `default`:

- It should have a volume attached and mounted into each container. The volume shouldn't be persisted or shared with other Pods。
- Container `c1` with image `nginx:1-alpine` should have the name of the node where its Pod is running on available as environment variable `MY_NODE_NAME`
- Container `c2` with image `busybox:1` should write the output of the date command every second in the shared volume into file `date.log`. You can use `while true; do date >> /your/vol/path/date.log; sleep 1; done` for this.
- Container `c3` with image `busybox:1` should constantly write the content of file `date.log` from the shared volume to stdout. You can use `tail -f /your/vol/path/date.log` for this.

解析:
---
1. 有个小要求不能忽视,需要创建一个共享目录emptyDir
2. 节点名称要使用 downwardAPI 获取
3. 共享目录中 container2 要在共享目录打印日期,container3 要tail -f 启动后可以查看c3 日志确定题目完成度

答案:
---
- 根据上述要求,需要设置一个多容器pod,并且共享 volume `k run multi-container-playground --image=nginx:1-alpine`

```yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: multi-container-playground
  name: multi-container-playground
spec:
  containers:
  - image: nginx:1-alpine
    name: c1                                                                      # change
    env:                                                                          # add
    - name: MY_NODE_NAME                                                          # add
      valueFrom:                                                                  # add
        fieldRef:                                                                 # add
          fieldPath: spec.nodeName                                                # add
    volumeMounts:                                                                 # add
    - name: vol                                                                   # add
      mountPath: /vol                                                             # add
  - image: busybox:1                                                              # add
    name: c2                                                                      # add
    command: ["sh", "-c", "while true; do date >> /vol/date.log; sleep 1; done"]  # add
    volumeMounts:                                                                 # add
    - name: vol                                                                   # add
      mountPath: /vol                                                             # add
  - image: busybox:1                                                              # add
    name: c3                                                                      # add
    command: ["sh", "-c", "tail -f /vol/date.log"]                                # add
    volumeMounts:                                                                 # add
    - name: vol                                                                   # add
      mountPath: /vol                                                             # add
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:                                                                        # add
    - name: vol                                                                   # add
      emptyDir: {}                                                                # add
```
- 校验是否达到题目要求 `k logs -f multi-container-playground -c c3`
## Question 14 | Find out Cluster Information
原题:
---

You're ask to find out following information about the cluster:

1. How many controlplane nodes are available?
2. How many worker nodes (non controlplane nodes) are available?
3. What is the Service CIDR?
4. Which Networking (or CNI Plugin) is configured and where is its config file?
5. Which suffix will static pods have that run on cka8448?

Write your answers into file /opt/course/14/cluster-info, structured like this:

```bash
# /opt/course/14/cluster-info
1: [ANSWER]
2: [ANSWER]
3: [ANSWER]
4: [ANSWER]
5: [ANSWER]
```


解析:
---
1. 通过各种命令执行判断本题集群信息，首先记得先切换root
2. service CIDR 一般会配置在 apiserver 的启动参数中
3. CNI 组件结合`kube-system` 命名空间和 `/etc/cni/net.d` 目录
4. 一般static-pod 的suffix 可以从kube-system 的static pod 中看出



答案:
---
```bash
# step1 获取controlplane 节点个数和worker 节点个数
k get no
# step2 获取 service CIDR
sudo -i；cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep range
# step3 查看集群内 kube-system 信息,一般除了apiserver，schedule，proxy，coreDNS,etcd 剩下的就是网络插件,可和step4 结合一起看
k get all -n kube-system 
# step4 通过 /etc/cni/net.d 查看
cat /etc/cni/net.d/10-weave.conflist
# step5 输出
cat <<EOF > /opt/course/14/cluster-info
# /opt/course/14/cluster-info
1: 1
2: 0
3: 10.96.0.0/12
4: Weave, /etc/cni/net.d/10-weave.conflist
5: -cka8448
EOF
```

## Question 15 | Cluster Event Logging
原题:
---
1. Write a `kubectl` command into `/opt/course/15/cluster_events.sh` which shows the latest events in the whole cluster, ordered by time (`metadata.creationTimestamp`)

2. Delete the kube-proxy Pod and write the events this caused into `/opt/course/15/pod_kill.log` on `cka6016`

3. Manually kill the containerd container of the kube-proxy Pod and write the events into `/opt/course/15/container_kill.log`

解析:
---
1. 输出命令kubectl 不能使用alias
2. `sort-by` value 要`.`开头
3. 使用crictl 直接操作CRI时,要切换到root账号

答案:
---
```bash
# step 1 获取 event
echo "kubectl get event -A  --sort-by=.metadata.creationTimestamp" > /opt/course/15/cluster_events.sh
# step 2 监听 event 变化
k get event -w -n kube-system
# step 3 再开一个 tab 结束 kube-proxy,然后把日志输出到文件
k delete po kube-proxy -n kube-system
# step 4 新tab 执行 crictl rm 
crictl ps|grep kube-proxy
crictl rm -f [containerID] 
```

## Question 16 | Namespaces and Api Resources
原题:
---
Write the names of all namespaced Kubernetes resources (like Pod, Secret, ConfigMap...) into `/opt/course/16/resources.txt`.

Find the `project-*` Namespace with the highest number of Roles defined in it and write its name and amount of Roles into `/opt/course/16/crowded-namespace.txt`.

解析:
---
1. 输出命令必须使用kubectl 不要用 k(alias 不生效),
2. kubectl apiresource 可以获取,并根据实际情况选择输出特定列
3. 通过获取所有namespace 并通过管道过滤并统计，然后输出

答案:
---
```bash
# step1 api-resources可以获取所有资源
echo "kubectl api-resources --namespaced -o name --no-headers" > /opt/course/16/resources.txt
# step2 通过统计
k get role -A -o custom-columes=NS:metadata.namespace|grep project-*| uniq -c 
# step 3 根据统计输出到特定文件
echo "project-miami 300" > /opt/course/16/crowded-namespace.txt
```

## **Question 17 | Operator, CRDs, RBAC, Kustomize**
原题:
---
There is Kustomize config available at `/opt/course/17/operator`. It installs an operator which works with different CRDs. It has been deployed like this:

`kubectl kustomize /opt/course/17/operator/prod | kubectl apply -f -`
Perform the following changes in the Kustomize base config:

- The operator needs to `list` certain CRDs. Check the logs to find out which ones and adjust the permissions for Role `operator-role`

Add a new Student resource called `student4` with any `name` and `description`

Deploy your Kustomize config changes to prod.


解析:
---
1. kustomize 技术是对多个yaml 共同点的统一抽取,能更好的管理多个yaml，做到配置分级
2. 题意要求为rbac 新增list crds的权限,这里的crd 是指具体的 Classes,Students类型 而不是Crd类型
3. 题意要求添加新的学生 students4 

答案:
---
```bash
# step 1 检查 kustomize 目录以及有多少个overlays
+ ls /opt/course/17/operator

base  prod
# step2     发现有两个 overlays, 运行`kubectl kustomize [DIR]` 各自查看每个overlays
+ k kustomize base
+ k kustomize prod
# 可以找到我们需要编辑的role 和 我们需要增加的students类型，于是编辑rbac.yaml 和 statents.yaml 按如下要求修改yaml


```
```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator-role
  namespace: default
rules:
- apiGroups:
  - education.killer.sh # api组可以在CRD声明中找到
  resources:
  - students 
  - classes
  verbs:
  - list
---
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student3
spec:
  name: Carol Williams
  description: A student excelling in container orchestration and management
---
# 增加student4 部分
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student4
spec:
  name: Some Name
  description: Some Description
---
```
- 执行 `k kustomize /opt/course/17/operator/prod | kubectl apply -f -`并检查
