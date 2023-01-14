# CKA 模拟复习题目

## 准备 
>设置一些快捷方式提升操作速度
```bash
# 用 k 代替kubectl
alias k=kubectl 
# dry-run 来快速生成一个yaml 善用dry-run 可以提升编写yml 的速度
export do="--dry-run=client -o yaml"
# 快速且立即把pod 删掉,方便应用快速重建pod,删除创建错的资源
export now="--force --grace-period 0" 
```

## 调整 .vimrc 使用两个空格代替tab
```bash
set tabstop=2
set expandtab
set shiftwidth=2
```

## question 1 | context(上下文)
 
>You have access to multiple clusters from your main terminal through kubectl contexts. Write all those context names into /opt/course/1/contexts .
>Next write a command to display the current context into /opt/course/1/context_default_kubectl.sh , the command should use kubectl . Finally write a second command doing the same thing into /opt/course/1/context_default_no_kubectl.sh , but without the use of kubectl .

### 翻译
> 你的终端进入一个多集群环境,将这些不同的上下文写在 /opt/course/1/contexts 文件里;
接着在`/opt/course/1/context_default_kubectl.sh`写一个命令来显示当前的上下文,这个命令必须使用`kubectl`;
最后在`/opt/course/1/context_default_no_kubectl.sh`写第二个命令做同样的事情,但是不要使用`kubectl`


### 答案解析 

* `k get-contexts` 命令用于获取集群的所有上下文,获取完成后输出到文件中如 kubectl get-contexts -o name > /opt/course/1/contexts
* 使用基于jsonpath 的解析,该语法类似于 jq `k config view -o jsonpath="{.contexts[*].name}" | tr " " "\n" > /opt/course/1/contexts`

最终文件类似于
```conf
k8s-c1-H 
k8s-c2-AC 
k8s-c3-CCC
```

* 创建一个使用kubectl 的命令来显示当前的contexts,直接使用`kubectl config current-contexts`
* 如果不使用kubectl 可以使用读取当前 .kube/config 的 current 内容来确定 `sed -nE 's#^current-context:(.*)#\1#p' ~/.kube/config`
## question 2| schedule pod on master Node 

使用上下文: `kubectl config use-context k8s-c1-H`

>Create a single Pod of image httpd:2.4.41-alpine in Namespace default . The Pod should be named pod1 and the container should be named pod1-container . This Pod should only be scheduled on a master node, do not add new labels any nodes. Shortly write the reason on why Pods are by default not scheduled on master nodes into /opt/course/2/master_schedule_reason .

### 翻译
> 在 `default` namespace使用镜像 httpd:2.4.41-alpine 创建一个单独的pod,这个pod 要满足以下条件
1. pod名称叫pod1,
2. pod 内容其名称叫pod1-container
3. pod 要调度到一个 master 节点上,并且不能在任何节点新增标签
4. 简单写一下为什么pod 默认不会调度到master 节点上的原因到 `/opt/course/2/master_schedule_reason`

### 答案解析
* 我们通过explain 可以知道设置podName 和 container name 分别是 `metadata.name`和`spec.containers.name` 解决了第一和第二小点,
* 第三小点需要知道master 上面的共性标签以及污点信息,设置当前pod 能容忍master 上面的 no-schedule 污点,使用简单的标签选择器就能达到目的,也可以使用affinity(不加选择器或affinity可能调度到工作节点上)
* 为何应用一般不调度到master 节点是因为master 节点上一般会有 no-scheduler污点 而应用没有这个污点的容忍度
对应的yml 如下

```yml
apiVersion: v1 
kind: Pod 
metadata: 
  labels: 
    run: pod1 
  name: pod1 
spec: 
  containers: 
  - image: httpd:2.4.41-alpine 
    name: pod1-container # change 
  tolerations: # add 
  - effect: NoSchedule # add 
    key: node-role.kubernetes.io/master # add 
  nodeSelector: # add 
    node-role.kubernetes.io/master: "" # add
```
## question3| scale down StatefulSet
>There are two Pods named o3db-* in Namespace project-c13 . C13 management asked you to scale the Pods down to one replica to save resources. ***Record*** the action.

### 翻译
> 在namespace project-c13中有两个pod 名称是o3db-*.C13 管理员让你缩容到1个实例,来节省资源,记录这个缩容操作
### 答案解析
> 通过观察我们知道这个pod o3db-0,o3db-1 由statefulSet 所创建,那么直接使用kubectl scale 命令缩容,要使用--record 记录更新历史(会创建对应的注解)

`kubectl -n project-c13 scale sts o3db --replicas 1 --record`

## question4 |pod read if service is reachable
>Do the following in Namespace default . Create a single Pod named ready-if-service-ready of image nginx:1.16.1-alpine . Configure a LivenessProbe which simply runs true . Also configure a ReadinessProbe which does check if the url http://service-am-i-ready:80 is reachable, you can use wget -T2 -O- http://service-am-i-ready:80 for this. Start the Pod and confirm it isn't ready because of the ReadinessProbe. 
>Create a second Pod named am-i-ready of image nginx:1.16.1-alpine with label id: cross-server-ready . The already existing Service service-am-i-ready should now have that second Pod as endpoint. Now the first Pod should be in ready state, confirm that.

### 翻译
>按要求在默认namespace 做
* 使用镜像:nginx:1.16.1-alpine 创建一个游离的pod 名称是 `ready-if-service-ready`.
* 配置一个健康检查始终返回 true
* 配置一个就绪检查通过检查 http://service-am-i-ready:80 是否可达,你可以使用命令 `wget -T2 -O- http://service-am-i-ready:80`启动这个POD 然后确认他没有ready 因为就绪检查不通过
* 创建第二个pod 名称是:am-i-ready 使用镜像 nginx:1.16.1-alpine ,带有lable id:cross-server-ready 
* 此时当前存在的service 能识别到当前的pod 作为endpoint,所以使第一个pod 的就绪检查变为ready 验证它

### 答案解析

* 通过使用上文定义的 do 来dry-run 快速创建pod,`k run ready-if-service-ready --image=nginx:1.16.1-alpine $do > 4_pod1.yaml` 改过程会快速生成一个yml, 按照要求修改他的健康检查和就绪检查

```yml
apiVersion: v1 
kind: Pod 
metadata: 
  creationTimestamp: null 
  labels: 
    run: ready-if-service-ready 
  name: ready-if-service-ready 
spec:
 containers:
  - image: nginx:1.16.1-alpine
    name: ready-if-service-ready 
    resources: {} 
    livenessProbe: # add from here
     exec: 
       command: 
       - 'true' 
    readinessProbe: 
      exec: 
        command: 
        - sh - -c - 'wget -T2 -O- http://service-am-i-ready:80' # to here 
    dnsPolicy: ClusterFirst 
    restartPolicy: Always 
    status: {}
```
此时启动会发现应用处于running 状态无法ready 因为 只存在service 而不存在对应的endpoint,
* 创建第二个pod让service 能选择到这个pod 作为endpoint
`k run am-i-ready --image=nginx:1.16.1-alpine --labels="id=cross-server-ready"`

## question5|kubectl sorting
>There are various Pods in all namespaces. Write a command into /opt/course/5/find_pods.sh which lists all Pods sorted by their AGE ( metadata.creationTimestamp ). 
Write a second command into /opt/course/5/find_pods_uid.sh which lists all Pods sorted by field metadata.uid . Use kubectl sorting for both commands.
### 翻译
* 各个 namespace 中有各种pods,写一个命令到 `/opt/course/5/find_pods.sh`将所有pod 按AGE(metadata.createTimestamp)排列
* 写第二个命令在`/opt/course/5.find_pods_uids.sh`,它的作用是将所有pod 按照uid排序.使用kubectl  排序的两种方式
### 答案解析
1. 使用 `kubectl get pods --sort-by`


