# CKA刷题心得

> 本文假定用户已基本理解 K8S 基础使用和运行原理,辅以高效率的刷题技巧，通过接触足够多的场景从而高分通过CKA考试。如果你对 K8S 的基础了解仍然不够,请参照：
1. [官网](https://kubernetes.io)
2. [kubernetes in action](https://sutlib2.sut.ac.th/sut_contents/H173702.pdf)
以上两个方式都能快速入门。

## 选择 CKA 模拟网站
>经对比使用官方考试模拟题目推荐地址 https://killercoda.com/sachin/course/CKA,选用70+ 部分题目更加贴近考试,接下来是刷题秘籍

## 注意事项
- [x] 使用 `alias k=kubectl`指令缩短命令,模拟环境和考试环境都可以这么做,以下命令都采取该做法。
- [x] 正式考试时,真实考试环境有多个context,执行命令前要选择对应的context。
- [x] 掌握快速强制删除: `--force --grace-period=0`
- [x] 掌握生成模板指令: `--dry-run=NONE -o yaml `

## 各题型快速解答
### 根据要求完成创建/修改体型
1. [打印pod日志](https://killercoda.com/sachin/course/CKA/log-reader-1)
```bash
k logs  alpine-reader-pod >podlogs.txt
# 解析：没什么好说的直接log 重定向到对应文件 不会的参考第一步
```
2. [打印pod日志2](https://killercoda.com/sachin/course/CKA/log-reader)
```bash
k logs log-reader-pod >podalllogs.txt
# 同上
```
3. [ETCD 数据恢复](https://killercoda.com/sachin/course/CKA/etcd-restore)
> 本题目主要考察三个知识点
```bash
etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    --endpoints=127.0.0.1:2379 \
    snapshot restore /opt/cluster_backup.db\
    --data-dir=/root/default.etcd > restore.txt 2>&1

# 解析:
# etcd 是k8s的数据库,它是以static pod 方式运行，采用 mTLS 证书认证
# etcdctl snapshot restore 命令用于将备份快照文件还原成etcd 数据
# etcd证书文件目录在 `/etc/kubernetes/pki/etcd
```
4. [ETCD 数据备份](https://killercoda.com/sachin/course/CKA/etcd-backup)
```bash
etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    --endpoints=127.0.0.1:2379 \
    snapshot save /opt/cluster_backup.db > backup.txt 2>&1
# 解析：同上,备份快照文件的命令是 etcd snapshot save
```
5. [secret 解码](https://killercoda.com/sachin/course/CKA/secret-1)
```bash
k get secret database-data -o jsonpath='{.data.DB_PASSWORD}' -n database-ns|base64 -d >decoded.txt
# 解析
# kubectl get secret database-data -n database-ns 获取secret 详情
# 通过 -o jsonpath 比较好定位到具体属性具体内容,使用参考 https://kubernetes.io/docs/reference/kubectl/jsonpath/
# secret data 中的value 是使用base64 存储的 通过管道输入base64 -d 进行解码
```
6. [快速创建基于文件内容的secret](https://killercoda.com/sachin/course/CKA/secret)
```bash
k create secret generic database-app-secret --from-file=database-data.txt
# 解析：可以通过kubectl create secret 快速创建基于文件内容|键值对|env文件的secret 本题基于文件内容
```
7. [集群升级](https://killercoda.com/sachin/course/CKA/cluster-upgrade) ***重要！！！难点！！！***

```bash
# 先更新linux 包依赖
apt update 
# 查看最新的包
apt list kubeadm
# 如果当前节点有工作负载 (业务负载) 驱逐到其他的节点上
kubectl drain [nodeName] --ignore-daemonsets
# 下载对应版本的包 此处以1.33.4-1.1 为例
apt install kubeadm=1.33.4-1.1 kubelet=1.33.4-1.1 kubectl=1.33.4-1.1
# 查看升级计划
kubeadm upgrade plan
# controlplane 节点执行
kubeadm upgrade apply v1.33.4
# node 节点执行
kubeadm upgrade node
# systemctl 重启kubelet
systemctl daemon-reload
systemctl restart kubelet
# 检查集群状态
kubectl get nodes
# 把驱逐的工作负载拉回来
kubectl uncordon [nodeName]
```

8. [service 过滤](https://killercoda.com/sachin/course/CKA/service-filter)

```bash
echo "kubectl get svc redis-service -o jsonpath='{.spec.ports[0].targetPort}'" >> svc-filter.sh
# 解析 本题主要考察jsonpath 的使用,答案不唯一,但由于校验方案问题仅能使用上述答案 实际上以下答案也是可以的
# echo "kubectl get svc -o jsonpath='{.items[?(@.metadata.name=="redis-service")].spec.ports[0].targetPort}'" >> svc-filter.sh
```
9. [RBAC 认证，创建SA，Role，RoleBinding](https://killercoda.com/sachin/course/CKA/sa-cr-crb-1)
```bash
# 快速创建一个名为 app-account 的serviceAccount
k create sa app-account
# 快速创建一个role 有get pod 的权限
k create role app-role-cka --verb=get --resource=pods  
# 快速将 role 和servicAccount 绑定起来
k create rolebinding app-role-binding-cka --role=app-role-cka --user=app-account
```
10. [RBAC 认证,修改ClusterRole](https://killercoda.com/sachin/course/CKA/sa-cr-crb)

```bash
# 通过 edit 命令使用vim 快速修改已经存在的资源,wq保存退出
k edit clusterRole group1-role-cka
```
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: "2025-09-07T04:40:25Z"
  name: group1-role-cka
  resourceVersion: "24859"
  uid: ac947dd2-5db1-496a-84c0-7fd98854e220
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - get
# 按照题目要求,添加 create 和list 行为
  - create
  - list
```
11. [查找CPU资源占用高的](https://killercoda.com/sachin/course/CKA/pod-resource)
```bash
k top pod --all-namespaces --sort-by=cpu|grep -v NAMESPACE -m 1|awk '{print $2","$1}' >high_cpu_pod.txt
# 解析:
# 通过top 命令获取cpu和内存,指定--all-namespaces 通过sort by 指定排序
# 后续管道只是为了调整格式,如果实际考试请直接vim编辑文件保存
```
12. [修改日志输出](https://killercoda.com/sachin/course/CKA/pod-log-1)

```bash
# 通过edit 指令使用vim 修改product pod 的yaml,修改Mi为Sony
k edit po product
# 查看日志由于edit修改command 是禁止的,会在日志中有输出对应的文件此时使用replace --force
k replace -f /tmp/kubectl-edit-68171752.yaml --force
```

13. [快速创建pod](https://killercoda.com/sachin/course/CKA/pod-log)
```bash
# 通过run --dry-run=client -o yaml 快速创建一个pod 模板,方便修改
k run alpine-pod-pod --image=alpine:latest --restart=Never -o yaml --dry-run=client > alpine-pod-pod.yml
# 按照提纲修改pod.yml 然后 apply 
k apply -f alpine-pod-pod.yml
```

```yml
# 修改后pod yml如下所示
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod-pod
spec:
  containers:
  - name: alpine-container
    image: alpine:latest
    command: ["/bin/sh", "-c"]
    args:
    - "tail -f /config/log.txt"
    volumeMounts:
    - name: config-volume
      mountPath: /config
  volumes:
  - name: config-volume
    configMap:
      name: log-configmap
  restartPolicy: Never
```
14. [pod 过滤](https://killercoda.com/sachin/course/CKA/pod-filter)
```bash
echo "kubectl get pod nginx-pod -o jsonpath='{.metadata.labels.application}'"> pod-filter.sh
# 解析 还是考察jsonpath 的使用
```
15. [pod 创建](https://killercoda.com/sachin/course/CKA/pod-create)
```bash
# 同13
k run sleep-pod --image=nginx --dry-run=client -o yaml
k apply -f pod.yml 
```

```yml
apiVersion: v1
kind: Pod
metadata:
  name: sleep-pod
spec:
  containers:
  - image: nginx
    name: sleep-pod
    command: ["sleep","3600"]
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```
16. [找出内存占用最高的node](https://killercoda.com/sachin/course/CKA/node-resource)

```bash
# 通过 sort-by 找到内存占用最高的node
k top node --sort-by=memory
# 通过题目找到context 直接输出到 high_memory_node.txt 文件
echo kubernetes-admin@kubernetes,controlplane >high_memory_node.txt
```

17. [记录pod错误日志](https://killercoda.com/sachin/course/CKA/log-reader-2)

```bash
# 使用管道过滤错误日志
k logs application-pod |grep ^ERROR > poderrorlogs.txt
```
18. [服务访问](https://killercoda.com/sachin/course/CKA/svc)
```bash
# 解析
# 考察使用kubectl expose 快速创建service 
k expose pod nginx-pod --name nginx-service
# 考察使用port-forward 临时映射端口本地访问
k port-forward service/nginx-service 80
```

19. [ClusterIP类型服务](https://killercoda.com/sachin/course/CKA/clusterip)

```bash
# part I 考察 kubectl expose 创建服务
k expose deploy nginx-deployment --name=nginx-service --port=80 --target-port=8080
# part II 记录所有pod IP -o wide 即可看到ip 后续 awk sort sed 只为了调整格式，不清楚使用手动录入也是可以的
k get po -o wide|awk '{print$6}'|sort -h|sed s#IP#IP_ADDRESS#g > pod_ips.txt
```

20. [创建RS,并测试coreDNS 域名解析](https://killercoda.com/sachin/course/CKA/coredns)
> 高版本rs 快速创建已经在 run以及create 子命令中移除,如果确实需要创建,建议从官网复制[replicas 模板](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)基础模板(建议收藏到收藏夹),从题意来看要满足三点

- **replicas 名称**: dns-rs-cka
- **命名空间**: dns-ns
- **实例数**: 2
- **容器名称**: dns-container
- **启动命令**: sleep 3600
- **label 和matchLabel对应关系**: 隐形条件，确保pod数目正确

```yml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: dns-rs-cka
  namespace: dns-ns
  labels:
    app: dnsutil
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dnsutil
  template:
    metadata:
      labels:
        app: dnsutil
    spec:
      containers:
      - name: dns-container
        image: registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3
        command: ["sleep","3600"]
```

```bash
# 检查发现 namespace 不存在所以先创建namespace
k create ns dns-ns
# apply rs.yml rs.yml 如上所示
k apply -f rs.yml
# 监听 pod 正常启动,直到所有pod running 状态
k get pod --watch -n dns-ns
# 随意选择一个pod 执行nslookup 命令
k -n dns-ns exec -it dns-rs-cka-l7flw -- nslookup kubernetes.default
# 无法解析kubernete.default 怀疑coredns 服务问题,发现endpoint 列表缺少core dns 
k describe svc kube-dns -n kube-system
# 进一步发现 service 和 deployment label 不匹配,deploy模板是kube-dns svc是core-dns,选择其中一个修改一致即可,建议修改svc 如果修改deploy 要同步修改deployment 的matchLabel 同时等待新的pod 启动
k get deploy coredns -n kube-system  --show-labels
k get svc kube-dns -n kube-system -o jsonpath-as-json='{.spec.selector}'
# 使用 edit 修改service,和deployment 保持一致
k patch service kube-dns -n kube-system -p '{"spec":{"selector":{"k8s-app": "kube-dns"}}}'
# 重新nslookup 并输出到dns-output.txt 大概内容如下
# Server:         10.96.0.10
# Address:        10.96.0.10#53
 
# Name:   kubernetes.default.svc.cluster.local
# Address: 10.96.0.1
k exec -n dns-ns dns-rs-cka-l7flw -- nslookup kubernetes.default > dns-output.txt
```

21. [coreDNS 域名解析](https://killercoda.com/sachin/course/CKA/coredns-1)
```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dns-deploy-cka
  name: dns-deploy-cka
  namespace: dns-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dns-deploy-cka
  template:
    metadata:
      labels:
        app: dns-deploy-cka
    spec:
      containers:
      - image: registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3
        name: dns-container
        command: ["sleep", "3600"]
```


```bash
# 创建namespace 
k create ns dns-ns
# 可以使用 create 命令快速通过模板创建deployment 
k create deploy dns-deploy-cka --replicas=2 -n dns-ns --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 -o yaml --dry-run=client > dns.yml
# 按要求修改 dns.yml 后 apply 
k apply -f dns.yml
# 监听等待pod 启动完成
k -n dns-ns get pod -w
# 选择任意一个pod执行命令解析域名输出到 dns-output.txt
k exec -n dns-ns dns-deploy-cka-6dbc94c975-8d6xn -- nslookup kubernetes.default > dns-output.txt
```
22. [ingress 创建](https://killercoda.com/sachin/course/CKA/ingress)

```bash
# 使用命令快速创建ingress
k create ing nginx-ingress-resource --rule=/shop*=nginx-service:80
# nginx ssl-redirect 需要使用annotations 识别,使用patch 快速修改
k patch ing nginx-ingress-resource -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/ssl-redirect":"false"}}}'
```
23. [NetworkPolicy设置](https://killercoda.com/sachin/course/CKA/network-policy)  ***重要！！！难点！！！***

```bash
# TODO
```

24. [NodePort 类型service](https://killercoda.com/sachin/course/CKA/nodeport)
```bash
# 快速创建 nodeport 类型service
k expose deploy nginx-app-cka --name app-service-cka --type=NodePort --port=80 --target-port=80  --protocol=TCP -n nginx-app-space
# 修改端口,如果你对patch熟悉都可以这么改 否则使用edit +vim 修改最直接
k patch svc  app-service-cka --type=json -p '[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":31000}]' -n nginx-app-space
```

25. [NodePort 类型service](https://killercoda.com/sachin/course/CKA/nodeport-1)

```bash 
# 快速创建deployment 
k create deploy my-web-app-deployment --replicas=2 --image=wordpress
# 通过测试知道wordPress端口是80 后续操作参考 24 题
k expose deploy my-web-app-deployment --port=80 --target-port=80 --type=NodePort --name=my-web-app-service
k patch svc my-web-app-service --type=json -p '[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30770}]'
```
26. [域名解析](https://killercoda.com/sachin/course/CKA/nslookup)

```bash
# 快速创建 pod
k run nginx-pod-cka --image=nginx 
# 快速创建 service 
k expose pod nginx-pod-cka --name=nginx-service-cka --port=80
# 快速验证 service 域名解析,此处比较狗血,cka校验答案太死板,一定要和答案本身一模一样,使用如下命令会生成 test-nslookup容器退出的日志,用其他方式也能获得结果,但校验不通过
k run test-nslookup --image=busybox:1.28 --restart=Never --rm -i -- nslookup nginx-service-cka > nginx-service.txt
```
27. [存储类](https://killercoda.com/sachin/course/CKA/Storage-class)
> 存储相关的无法通过 `create` 子命令快速创建,所以请保存网页https://kubernetes.io/docs/concepts/storage/storage-classes/ 以便快速找到模板按题目要求,
所需的 `sc.yml` 如下:

```yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: green-stc
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```
```bash
# 直接 apply
k apply -f sc.yml
```

28. [共享目录](https://killercoda.com/sachin/course/CKA/Shared-Volume)

```yml
- name: sidecar-container
  image: busybox
  command: ["sh","-c","tail -f /dev/null"]
  volumeMounts:
  - name: shared-storage
    mountPath: /var/www/shared
    readOnly: true
```

```bash 
# 通过edit 命令打开编辑页面,containers新增一个容器 插入如上片段 wq保存退出
k edit po my-pod-cka 
# 由于添加sidecar容器无法直接保存,可通过replace 解决
k replace -f /tmp/kubectl-edit-2750922353.yaml --force
```

29. [pvc扩缩容](https://killercoda.com/sachin/course/CKA/pvc-resize)
```bash 
# 直接使用 patch 是最快的方法,不熟悉就老老实实edit 
k patch pvc yellow-pvc-cka -p '{"spec":{"resources":{"requests":{"storage":"60Mi"}}}}'
```

30. [Storage,PV,PVC,POD综合练习](https://killercoda.com/sachin/course/CKA/sc-pv-pvc-pod)
> 编辑一个 all.yml 解决这些问题

```yml
# storage Class 模板 https://kubernetes.io/docs/concepts/storage/storage-classes/
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner   
volumeBindingMode: Immediate
---
# https://kubernetes.io/docs/concepts/storage/persistent-volumes/ 获取pv 和pvc模板
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fast-pv-cka
spec:
  capacity:
    storage: 50Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  hostPath:
    path: /tmp/fast-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-pvc-cka
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Mi
  storageClassName: fast-storage
---
# 通过 kubectl run fast-pod-cka --image=nginx:latest -o yaml --dry-run=client 生成,再添加volume 挂载
apiVersion: v1
kind: Pod
metadata:
  name: fast-pod-cka
spec:
  volumes:
  - name: nginx-dir
    persistentVolumeClaim:
      claimName: fast-pvc-cka
  containers:
  - image: nginx:latest
    name: fast-pod-cka
    volumeMounts:
    - name: nginx-dir
      mountPath: /app/data
```
```bash
# 直接apply 即可
k apply -f all.yml
```
31. [Storage,PV,PVC综合练习](https://killercoda.com/sachin/course/CKA/sc-pv-pvc)
> 与上文相似,但隐性考察WaitForFirstConsumer 需要自己创建pod，考察污点与容忍度,考察pv NodeAffinity
```yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: blue-stc-cka
provisioner: kubernetes.io/no-provisioner   
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: blue-pv-cka
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: blue-stc-cka
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /opt/blue-data-cka
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: ["controlplane"]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: blue-pvc-cka
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
  storageClassName: blue-stc-cka
---
# 通过 kubectl run fast-pod-cka --image=nginx:latest -o yaml --dry-run=client 生成,再添加volume 挂载
apiVersion: v1
kind: Pod
metadata:
  name: blue-pod-cka
spec:
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
    operator: Exists
  nodeSelector:
    kubernetes.io/hostname: controlplane
  volumes:
  - name: nginx-dir
    persistentVolumeClaim:
      claimName: blue-pvc-cka
  containers:
  - image: nginx:latest
    name: blue-pod-cka
    volumeMounts:
    - name: nginx-dir
      mountPath: /app/data
```
```bash
# 创建localPath
mkdir /opt/blue-data-cka
# 直接apply 即可
k apply -f all.yml
```

32. [pvc 和pod 综合练习](https://killercoda.com/sachin/course/CKA/pvc-pod)
> 31 弱化版，修改现成的pod yaml
```yml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc-cka
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 80Mi
  storageClassName: nginx-stc-cka
# 修改nginx-pod-cka.yaml 如下
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-cka
spec:
  # 可以使用nodeAffinity 但没必要。直接使用nodeSelector 最简单
  nodeSelector:
    kubernetes.io/hostname: controlplane
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
    operator: Exists
  volumes:
  - name: nginx-pvc
    persistentVolumeClaim:
      claimName: nginx-pvc-cka
  containers:
    - name: my-container
      image: nginx:latest
      volumeMounts:
      - mountPath: /var/www/html
        name: nginx-pvc
```
33. [pvc考察](https://killercoda.com/sachin/course/CKA/pvc)
> 32 弱化版,仅需创建pvc,直接apply 即可
```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: red-pvc-cka
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Mi
  storageClassName: manual
```

34. [pv pvc pod 综合练习](https://killercoda.com/sachin/course/CKA/pv-pvc-pod)
> 32 同类型,最好让pv 亲和到node01 节点
```yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv-cka
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: ["node01"]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-cka
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: standard
---
apiVersion: v1
kind: Pod
metadata:
  name: my-pod-cka
spec:
  volumes:
  - name: nginx-dir
    persistentVolumeClaim:
      claimName: my-pvc-cka
  containers:
  - image: nginx:latest
    name: blue-pod-cka
    volumeMounts:
    - name: nginx-dir
      mountPath: /var/www/html
```

35. [pv 和pvc练习](https://killercoda.com/sachin/course/CKA/pv-pvc)
> 与34 相似,着重练习pvc 标签选择器 可使用精确或表达式匹配
```yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  labels:
    tier: white
  name: gold-pv-cka
spec:
  capacity:
    storage: 50Mi
  accessModes:
    - ReadWriteMany
  storageClassName: gold-stc-cka
  hostPath:
    path: /opt/gold-stc-cka
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: ["node01"]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gold-pvc-cka
spec:
  selector:
    matchLabels:
      tier: white
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 30Mi
  storageClassName: gold-stc-cka
---
apiVersion: v1
kind: Pod
metadata:
  name: gold-pod-cka
spec:
  volumes:
  - name: nginx-dir
    persistentVolumeClaim:
      claimName: gold-pvc-cka
  containers:
  - image: nginx:latest
    name: gold-pod-cka
    volumeMounts:
    - name: nginx-dir
      mountPath: /var/www/html
```

36. [pv 练习](https://killercoda.com/sachin/course/CKA/pv)
> 无脑apply即可,最简单的练习
```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: black-pv-cka
spec:
  capacity:
    storage: 50Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /opt/black-pv-cka
```
### 问题排查类型 
> 问题排查需要一定的k8s 基本功,需要程序员一定的解决问题能力,通过全局考虑辅助命令快速发现问题

37. [deployment 问题排查](https://killercoda.com/sachin/course/CKA/deployment-issue-1)
> 主要考察 describe 子命令使用,pod 状态分析

```bash
k describe deploy nginx-deployment
# 未发现异常
k get po
# 发现处于init 阶段,说明 initContainer 有问题
k describe po nginx-deployment-7df8cc9d85-hppwq
# 发现configMap 挂载问题 nginx-configuration 不存在
k get cm
# 猜测 configMap名称 写错了，应为 nginx-configmap
k edit deploy nginx-deployment
# 修改后启动报错,说明有其他问题
k describe po nginx-deployment-854cc5bc79-8k97d
# exec shell 应该不是shell环境 尝试修改为 sh -c 重启问题解决
```
38. [pod 问题排查-1](https://killercoda.com/sachin/course/CKA/pod-issue)
> 考察describe 使用,以及强制replace 使用
```bash 
k describe po hello-kubernetes
# 发现 shell 不存在 $PATH 变量中,尝试改成sh -c
k edit po hello-kubernetes
# 出现 pod 不允许直接修改的提示,通过replace --force 问题解决
k replace -f /tmp/kubectl-edit-89856244.yaml --force
```
39. [pod问题排查-2](https://killercoda.com/sachin/course/CKA/pod-issue-1)
```bash
k describe po nginx-pod
# 老规矩使用describe 检查 发现 Failed to pull image "nginx:ltest"分析它是要写latest 拼写出错,于是修改版本 latest 问题解决
k edit po nginx-pod 
```
40. [pod问题排查-3](https://killercoda.com/sachin/course/CKA/pod-issue-2)
> 考察pv 和pvc 匹配
```bash
k describe po edis-pod
# describe 发现pvc-redis不存在,检查是不是pvc名称写错
k get pvc
# 发现名称为redis-pvc 修改名称 replace 重新启动,
k replace -f /tmp/kubectl-edit-883473936.yaml --force
# pending,继续describe 发现pvc 绑定 pv 失败(pod has unbound immediate PersistentVolumeClaims)
k describe pvc redis-pvc 
# storage class manually 不存在,猜测是不是 sc名称写错了
k get pv 
# 分析sc 名称应为 manual 修改pvc storageClassName 为 manual
k edit pvc redis-pvc
# 保存后退出发现镜像名写错 按 题39方式处理
```
41.[pod 问题排查-4](https://killercoda.com/sachin/course/CKA/pod-issue-3)
> 考察 label 匹配
```bash
k describe po frontend
# 继续 describe 发现无法调度到节点上,提示是一个节点不满足条件(node01),一个节点上有污点(controlplane) 看一下当前 pod,节点匹配
k get po frontend -o yaml
# 发现设置了强制节点亲和（需要有 label: NodeName=frontend 才能调度）继续查看哪个node 有这个label
k get no --show-labels
# 发现 node01 标签写错了,修改frontendnode 为frontend
k label no node01 NodeName=frontend --overwrite
```
42. [pod 问题排查-5](https://killercoda.com/sachin/course/CKA/pod-issue-4)
> 考察 explain 子命令使用,健康检查配置
```bash
k apply -f postgres-pod.yaml 
# 直接 apply 报错显而易见,健康检查配置有问题,使用explain 看一下属性描述
k explain pod.spec.containers.readinessProbe.exec
# exec 需要配置command 按照要求修改 cmd 改成 command
k explain pod.spec.containers.livenessProbe.tcpSocket
# tcp socket 需要配置host或port 按照要求修改 command.args 改成port
```
43. [pod 问题排查-6](https://killercoda.com/sachin/course/CKA/pod-issue-5)
```bash
k apply -f redis-pod.yaml 
# 直接 apply 报错显而易见,资源限制 request 大于limit,对调requests,limit 作为 Burstable Qos(使用requests 作为limit 理论也可以但是答案不允许，使用limit 作为request 不可以，因为总资源不够)
```
44. [pod 问题排查-7](https://killercoda.com/sachin/course/CKA/pod-issue-6)

```bash
k describe po my-pod-cka
# 老规矩,先describe 发现无法绑定pvc 
k describe pvc my-pvc-cka
# 发现accessMode 不一致,查看pv 的accessMode 修改为 ReadWriteOnce
k edit pvc my-pvc-cka
```
45. [pod 问题排查-8](https://killercoda.com/sachin/course/CKA/pod-issue-7)
> 考察为pod 添加对污点的容忍使po能调度到有污点的node上
```yml
# 修改pod 描述文件,添加Node01 污点 nodeName 容忍度,apply 即可
spec:
  tolerations:
  - key: nodeName
    operator: Equal
    effect: NoSchedule
    value: workerNode01
```
46.  [kubectl 故障排查](https://killercoda.com/sachin/course/CKA/kubectl-issue)
> kubectl 客户端描述文件 ～/.kube/config
```bash
k cluster-info
# 查询集群信息,发现发送地址端口为644333,而API-server 默认端口6443 查看客户端配置文件 修改后正常
```
47. [deployment 故障](https://killercoda.com/sachin/course/CKA/deployment-issue)
> 考察在pod 环境变量中引用 secret
```bash
k apply -f postgres-deployment.yaml 
# apply 成功执行 但是pod pending状态,describe 一下
k describe po postgres-deployment-fbb47698c-4gwdm
# 报错: secret "postgres-secrte" not found 怀疑 写错了secret 名称
k get secret
# 发现secret 名称错误,于是编辑修改secret
k edit deploy postgres-deployment
# 修改后重新describe 发现报错 couldn't find key db_user in Secret default/postgres-secret 怀疑key 引用写错
k get secret postgres-secret -o yaml
# 比对key 引用,并更新deployment db_user 改为username;db_password改为password
k edit deploy postgres-deployment 
```
48. [pod 故障排查9](https://killercoda.com/sachin/course/CKA/pod-issue-8)
> 考察service 流量代理 pod
考察 port-forward 用法
```bash
# 由题意分析的 port-forward 之后无法在本地访问,首先查看一下service IP 看能否直接访问
k get svc nginx-service -o wide 
# 获得IP 10.108.241.163 端口为80 使用curl 请求
curl 10.108.241.163 -v 
# 发现不通 再排查pod 能不能访问
k get po nginx-pod -o wide
# 获取到IP 192.168.1.4 直接curl 试试
curl 192.168.1.4 -v 
# 可以访问 判断是否 service 代理除了问题,查看service Endpoint
k describe svc nginx-service
# endpoints 列表为空,则检查service matchLable 和 pod label 对应关系
k get pod nginx-pod -o yaml
k get svc nginx-service -o yaml
# pod 未定义label 而service 定义 label 选择器为 app: nginx-pod 于是添加label 给pod
k label pod nginx-pod app=nginx-pod
# port-forward 重新测试 问题解决
```
49. [kubelet 问题排查](https://killercoda.com/sachin/course/CKA/kubelet-issue)
- kubelet 以systemd 形式部署到物理机(虚拟机)上,可以参照systemd 服务管理模式
- kubelet 主要承担pod 具像化部署为容器的工作(作为api-server的agent)
- 默认ca证书目录是 
·
```bash
systemctl status kubelet
# 查看状态,发现系统尝试自动重启kubele,说明kubelet 是enabled 状态,看一看有没有对应日志
journalctl -xeu kubelet 
# 通过日志查询 发现错误: failed to construct kubelet dependencies: unable to load client CA file,通过status 知道kubelet 的变量配置保存在 /usr/lib/systemd/system/kubelet.service.d,查看该文件获得kubelet 主要的配置位于:

# /etc/kubernetes/bootstrap-kubelet.conf 
# /etc/kubernetes/kubelet.conf
# /var/lib/kubelet/config.yaml 
# /var/lib/kubelet/kubeadm-flags.env 这是在kubeadm init 过程中指定生效的
# /etc/default/kubelet 用户自定义可以覆盖上述配置的文件

# 检查以上配置文件 关注CA配置 发现 

# /etc/kubernetes/kubelet.conf api-server地址异常 应为  https://172.30.1.2:6443
# /etc/kubernetes/kubelet.conf 文件异常,ca 证书 目录修改为: /etc/kubernetes/pki/ca.crt

# 重新启动kubelet 问题修复
systemctl start kubelet
```

50. [deploy 无实例](https://killercoda.com/sachin/course/CKA/deployment-rollout-resume)
```bash
k describe deploy stream-deployment 
# 先describe 发现 replicas=0 直接扩容为1 问题解决
k scale deploy stream-deployment  --replicas=1
```

51. [deploy 问题排查](https://killercoda.com/sachin/course/CKA/deployment-issue-4)

```bash
k describe po database-deployment-b95f67975-nljhx
# persistentvolumeclaim "postgres-db-pvc" not found 原因很清晰,是不是pvc 名字写错
k get pvc
# 果然,修改pvc 名称 postgres-db-pvc 为 postgres-pvc
k edit deploy database-deployment
# 继续describe po 发现 pod has unbound immediate PersistentVolumeClaims 看一下pvc 和pv 匹配关系
k describe pvc postgres-pvc
# 发现原因 requested PV is too small capacity 为0 参考一下pv 的容量
k get pv 
# capacity 100Mi 修改pvc 容量 100Mi
k describe pvc postgres-pvc accessModes 
# 不匹配,同样参考pv 配置为ReadWriteOnce 修改 验证成功
```
52. [kube-controller-manager 故障排查](https://killercoda.com/sachin/course/CKA/controller-manager-issue)
- controller-manager 是 以static pod 部署的。主要配置在 /etc/kubernetes/manifest/kube-controller-manager.yml 中 可通过 容器命令查询日志
- controller-manager 主要负责解析各种 yml 生成对应的部署资源
- controller-manager pod 管理在`kube-system` namespace
```bash
k get po -n kube-system 
# 发现 pod 异常
k describe po kube-controller-manager-controlplane
# error during container init: exec: "kube-controller-manegaar": executable file not found in $PATH: unknown 启动命令拼错了manager 于是修改描述文件 启动命令
vim /etc/kubernetes/manifest/kube-controller-manager.yaml
```

53. [network-policy 故障排查](https://killercoda.com/sachin/course/CKA/network-policy-issue)

```bash

```

54. [node 不ready](https://killercoda.com/sachin/course/CKA/node-notready)
```bash
# 之前说过kubelet 作为node agent通信,node 不正常先检查kubelet 
systemctl status kubelet
# inactive 状态 于是启动 问题解决
systemctl start kubelet
```
55. [kubectl 端口异常故障排查](https://killercoda.com/sachin/course/CKA/node-port-issue)

```bash
kubectl cluster-info
# 测试发现集群客户端信息正常
kubectl get pod -A 
# 偶尔出现连接超时，api-server 有可能异常
kubectl describe po kube-apiserver-controlplane -n kube-system
#  Startup probe failed: Get "https://172.30.1.2:6433/livez": dial tcp 172.30.1.2:6433: connect: connection refused 健康检查异常,知道 api-server 是static-pod 启动的。直接查看 /etc/kubernetes/manifest/kube-apiserver.yaml修改端口6433 为6443
```
60. [deploy 故障排查](https://killercoda.com/sachin/course/CKA/deployment-issue-3)

```bash
k describe po postgres-deployment-68d5bf48b6-b4brs
# describe 发现 configmap postgres-db-config 不存在,可能名字写错了
k get cm 
# 果然 只发现 postgres-config 未出现 postgres-db-config 
k get cm -o jsonpath-as-json='{.data}'
# 出现 POSTGRES_DB 和 POSTGRES_USER 两个key 同步修改 deployment 中引用
k edit deploy postgres-deployment
# 编辑后启动失败 发现相似问题 secret 名称写错 继续编辑完成
```
61. [deploy 故障排查](https://killercoda.com/sachin/course/CKA/deployment-issue-2)

```bash
k apply -f frontend-deployment.yaml
# 报错,namespace 不存在 先创建
k create ns nginx-ns
# 重新apply
k apply -f frontend-deployment.yaml
```
62. [PV,PVC故障排查](https://killercoda.com/sachin/course/CKA/pv-pvc-issue)
```bash
# 查看pv 和pvc 匹配问题
k get pv my-pv -o yaml
k get pvc my-pvc -o yaml
# 发现 accessModes 不一致,且pvc capacity 比pv 大 于是修改pvc
k edit pvc my-pvc
# 修改 accessModes ReadWriteOnce ,capacity 100Mi 保存 报非法操作
k replace -f /tmp/kubectl-edit-3437866368.yaml --force
# 强行replace
```
63. [cronJob 故障排查](https://killercoda.com/sachin/course/CKA/cronjob-issue)
> cron job 会定期生成job job 会启动pod 运行任务 完成后显示complete

```bash
k logs -f cka-cronjob-29288849-h7z56 
# 日志中 Could not resolve host: cka-pod 按照体感要求应该是流量要过service 所以应该是command 有问题
k edit cj cka-cronjob
# 修改command curl cka-service 继续报错,查询service 的endpoint 列表
k describe svc cka-service 
# 列表为空 索命 selector 和 label 不匹配
k get svc cka-service -o custom-columns=selector:spec.selector
# 查询选择器指定的selector app:cka-pod
k get po cka-pod --show-labels
# 查询label 为空,要为cka-pod 添加label
k label pod cka-pod app=cka-pod
# 修改schedule */1 * * * * 每分钟运行一次
```
64. [RBAC问题排查](https://killercoda.com/sachin/course/CKA/sa-cr-crb-issue)

> 掌握kubernetes 的rbac 模型 

```bash
k get sa dev-sa
# 获取dev-sa 看是否创建 确认已经创建
k get rolebinding dev-role-binding-cka -o yaml
# 获取 dev-role-binding-cka 查看绑定关系 确认绑定了dev-role-cka
k get dev-role-cka -o yaml 
# 获取role 确认设置权限是否有问题,有问题应该修改 verbs添加 create list get,resource 添加 services 和 pods
k edit role dev-role-cka
```

65. [RBAC问题排查2](https://killercoda.com/sachin/course/CKA/sa-cr-crb-issue-1)
> 掌握kubernetes 的rbac 模型 
```bash
k get sa prod-sa
# 获取prod-sa 看是否创建 确认已经创建
k get rolebinding prod-role-binding-cka -o yaml
# 获取 dev-role-binding-cka 查看绑定关系 确认绑定了dev-role-cka
k get prod-role-cka -o yaml 
# 获取role 确认设置权限是否有问题,有问题应该修改 verbs添加 create list get,resource 添加 services
k edit role prod-role-cka
```
66. [daemonSet问题排查](https://killercoda.com/sachin/course/CKA/ds-issue)

```bash 
k get po -o wide 
# 打印 pod 落在了哪些node上,图可知node01 已经有ds,controllplane 没有是因为有污点,那么可以让ds 生成的pod 有容忍污点的能力
k get no controlplane -o jsonpath-as-json='{.spec.taints}'
# 获取controlplane 节点的污点
k edit ds cache-daemonset 
# 添加 controlplane 污点 node-role.kubernetes.io/control-plane
```

67. [etcd 备份问题排查](https://killercoda.com/sachin/course/CKA/etcd-backup-issue)

```bash
k logs -f etcd-controlplane -n kube-system
# 检查ETCD 发现在不断地重启,日志链接不上kubelet 端口。初步判断kubelet 挂了(kubelet 端口10250)
systemctl start kubelet 
# etcd 备份并存储恢复日志
etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        --endpoints=localhost:2379 \
        snapshot save /opt/cluster_backup.db > backup.txt 2>&1
```
### 工作负载部署相关
68. [回滚应用练习](https://killercoda.com/sachin/course/CKA/rollback)

```bash
# 回滚版本到上一个
k rollout undo deploy redis-deployment  
# 保存回滚后的镜像名
k get deploy redis-deployment  -o jsonpath='{.spec.template.spec.containers[0].image}' > rolling-back-image.txt
# 扩容到 3 实例
k scale deploy redis-deployment --replicas=3
```

69.  [快速创建deployment](https://killercoda.com/sachin/course/CKA/deployment)
```bash
# 创建deployment 
k create deploy nginx-app-deployment --image=nginx --replicas=3
```
70.  [扩缩容deployment](https://killercoda.com/sachin/course/CKA/deployment-scale)
    
```bash
# 扩容到 3 实例
k scale deploy redis-deploy -n redis-ns --replicas=3
```
71. [deployment 引用secret](https://killercoda.com/sachin/course/CKA/deployment-secret)
```bash
# 快速创建secret
k create secret generic db-secret \
--from-literal=DB_Host=mysql-host \
  --from-literal=DB_User=root \
  --from-literal=DB_Password=dbpassword
# 编辑 deploy 保存,格式如下 替换掉三个变量
k edit deploy webapp-deployment
# - name: DB_Host
#   valueFrom:
#     secretKeyRef:
#       key: DB_Host
#      name: db-secret
```

72. [更新参数设置](https://killercoda.com/sachin/course/CKA/deployment-rollout)
```bash
# 快速创建模板,手动编辑新增滚动升级参数
kubectl create deploy cache-deployment  --replicas=2 --image=redis:7.0.13 --dry-run=none -o yaml > deploy.yml
# 部署
k apply -f deploy.yml
# 更新镜像
k patch deploy cache-deployment --type=json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"redis:7.2.1"}]'
# 查看更新历史
k rollout history deploy cache-deployment
# 观察得到2次
echo 2 > total-revision.txt
```
73. [pod和service练习](https://killercoda.com/sachin/course/CKA/pod-svc-1)
```bash
# 创建ubuntu pod 使用标签 app=os
k run ubuntu-pod --image=ubuntu -l app=os 
# 快速创建 service 
k expose pod ubuntu-pod --port=8080 --name=ubuntu-service
```
74. [configmap和deploy练习](https://killercoda.com/sachin/course/CKA/configmap-deploy)
```bash
# 快速创建configMap
k create cm webapp-deployment-config-map --from-literal=APPLICATION=web-app
# 通过edit 更新deployment 修改env引用
k edit deploy webapp-deployment
# - name: APPLICATION
#   valueFrom:
#     configMapKeyRef:
#       key: APPLICATION
#       name: webapp-deployment-config-map
```

75. [pod和service练习](https://killercoda.com/sachin/course/CKA/pod-svc)
```bash
# 快速创建模板
k run app-pod --image=httpd:latest --dry-run=client -o yaml > app-pod.yml
# 修改 app-pod.yml container name 和containerPort,然后apply
k apply -f  app-pod.yml
# 为pod 新增label app=app-lab
k label po app-pod app=app-pod
# 为pod 快速创建service 
k expose po app-pod --port=80 --target-port=80 --type=ClusterIP --selector=app=app-lab --name=app-svc
# port-forward 映射端口
k port-forward pod/app-pod 80:80
# curl 测试
curl localhost
```
76. [deployment 问题排查](https://killercoda.com/sachin/course/CKA/deployment-1)
```bash
# 直接apply 
k apply -f my-app-deployment.yaml
# 根据报错limit 大于request 应该写错了对调一下 
# 重新apply 镜像下载失败 检查镜像名称 修改为 nginx:latest
# 重新apply 仅有一个ready 另一个pending describe 
k describe po my-app-deployment-565ccc7569-hmwt5
# 发现controlplane 有污点 node-role.kubernetes.io/control-plane 禁止调度,为模板新增容忍度
# tolerations
# - key: node-role.kubernetes.io/control-plane
#   effect: NoSchedule
#   operator: Exists  
```
77. [部署历史](http://kkillercoda.com/sachin/course/CKA/deployment-history)
```bash
# 部署历史查询 得到三次
k rollout history deploy video-app 
# 查询第三次部署详情 得到镜像名称 redis:7.0.13
k rollout history deploy video-app --revision=3
# 按格式 REVISION_TOTAL_COUNT,IMAGE_NAME 输出到 app-file.txt
echo "3,redis:7.0.13" > app-file.txt
```
78. [pod 资源调整](https://killercoda.com/sachin/course/CKA/pod)
```bash 
# 通过edit 调整 resources.limits.memory = 50Mi
k edit po my-pod
# pod edit 无法直接更新 使用replace force 更新
k replace -f /tmp/kubectl-edit-2215633761.yaml --force
```








