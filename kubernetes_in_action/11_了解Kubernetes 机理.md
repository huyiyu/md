# 了解Kubernetes 机理
## 了解架构

* 控制平面
    * etcd分布式持久化存储
    * api 服务器
    * 调度器
    * 控制器管理器
* 工作节点
    * kubelet
    * kube-proxy
    * container runtime
* 附加组件
    * kubenetes DNS 服务器
    * ingress 控制器
    * Heapster
    * 容器网络接口插件

* **组件间如何通信**: 各个组件之间不会直接通信,都是通过apiServer 间接通信。如:各个组件通过调用api-server修改etcd中的状态信息。
* **组件如何运行**: etcd和api-server 可以多节点并行工作,但是control-manager 和kube-scheduler每次只能有一个节点在工作，其他处于待命状态。kubelet 是唯一没有部署到容器内部的组件。
* **kubenetes如何使用etcd**: kubenetes 创建的所有对象都要存储到etcd上,它是一个响应快,分布式,一致的key-value存储,唯一能和etcd通信的是api-server 其他服务间接通过api-server查看修改删除内容,优点是增强乐观锁系统，验证系统的健壮性。
* **etcd一致性保证**: raft一致性算法保证了只有超过半数的节点确认,更新才会生效,所以etcd要是奇数台
* **api服务器做了什么**:
    * 通过认证插件认证客户端
    * 通过授权插件授权客户端
    * 通过准入控制插件验证修改资源请求,包含以下几种
        * AlwaysPullImages: 强制每次部署时拉镜像
        * ServiceAccount: 未明确定义账号的使用默认账户
        * NamespaceLifecycle: 防止在命名空间中创建正在被删除的pod,或在不存在的命名空间创建pod
        * ResourceQuota:某个命名空间中的资源分配限制
* **api-server 通知资源变更**: 启动各种控制器,让控制器订阅事件,并在资源变更时通知对应的控制器
* **调度器工作**: 订阅 pod创建,为创建的POD分配调度节点
    * 默认调度算法
        * 查找可用节点
            * **硬件资源条件** 是否满足
            * **是否耗尽资源** 是否报告过内存硬盘压力参数
            * **是否要求被调度到指定节点** 是否是当前节点
            * **标签选择器** 是否有
            * 要求绑定指定的主机**端口是否被占用**
            * 是否有对应的存储**卷的资源**
            * 如果有污点,能否容忍**污点**
            * 是否满足节点/pod 的**亲缘性/非亲缘性规则**
        * 选择最优节点,有多个节点循环分配
            * 根据符合条件的node 的pod 数量优先选择 pod少的节点
* **控制器管理器中的控制器**:确保集群的资源数量朝着api-server 指示的状态收敛,然后将状态写入资源的 status 部分 由不同的控制器完成,每个控制器不会直接通信而是通过订阅api-server 知道了状态的变更
    * replication 管理器: 通过订阅api-server 副本变更事件,触发控制器重新检查副本数量,作出相应操作,不会主动创建POD,而是创建pod 清单发布到api-server 让调度器和kubelet去做具体事情 
    * replicaSet，DaemonSet,job控制器: 这三个控制器,类似replication管理器
    * deployment 控制器:负责使deployment 实际状态和 对应的 deployment api 的期望同步,当新增或修改deployment时,通过对应的升级策略,创建replicatSet 同时伸缩新旧replicaSet 直到旧的POD都被新pod 代替。
    * statefulSet 控制器:类似于 rs,rc,ds,job 控制器,statefulSet控制器用于实现statefulSet 资源修改后pod 的变化
    * node 控制器: 使节点对象列表保持和实际机器列表一致,同时监控节点的健康状态
    * service 控制器: 在loadBalancer类型服务被创建或删除时,从基础设施服务请求，释放负载均衡器。
    * endpoint 控制器: 定期根据匹配标签选择器的pod IP，端口更新端点列表
    * namespace 控制器:当收到删除namespace 删除的通知时,控制器通过api-server 删除所有归属该命名空间的资源
    * persistentVolume 控制器:保存一个有顺序的持久卷列表，对于每种访问模式按照升序排列，返回列表的第一个卷
    * 其他
* **kubelet**:
    * 在api-server 创建一个Node 资源注册该节点,
    * 持续监控api-server是否把该节点分配给pod,然后启动pod 容器，具体是告诉具体容器运行时(docker coreOS Rkt)来从特定的镜像运行容器
* **kube-proxy 作用**: 经历了三种版本变更
    * userspace: 为了拦截发往服务IP的连接,代理配置了 iptables 规则,重定向连接到代理服务器
    * iptables: 仅仅通过iptables 规则链重定向数据包到一个随机选择的pod 而不会传递到一个实际的代理服务器,只会在那和空间处理，减少了状态切换
    * ipvs: kubenetes 1.11 版本选择基于ip set的高性能负载均衡,使用更高效的数据结构HASH表,允许几乎无限的规模扩张
* **插件**:
    * DNS:替换每个容器 `/etc/reslv.conf` 文件使DNS指向容器的 dns 服务,kube-dns 通过订阅api-server 中service 和endpoint 的变动,以及dns记录的变更，使客户端总能获取到最新的dns信息
    * Ingress控制器: 运行一个反向代理服务器,根据集群中定义的Ingress Service以及endpoint 资源来配置该控制器,尽管Ingress资源定义指向一个service，Ingress控制器会直接将流量赚到服务的pod而不经过服务

## 控制器如何协作
1. kubectl 发送一个创建deployment 资源的请求, 
2. api-server 接收到这个请求并把具体期望存入etcd，并创建了 deployment 对象并通知 deployment 控制器,
3. deployment 控制器订阅了相关事件,进行滚动升级调用api-server 创建一个新的 replicaSet 对象,存入etcd 并通知 replicaset控制器 同时视情况进行 双replicaSet的伸缩
4. replicaSet 控制器订阅了相关事件,扫描期望的副本数,创建POD对象,存入etcd 并通知kube-scheduler
5. kube-scheduler 订阅了pod 创建事件,将pod 选择调度到某个最佳节点,修改 nodeName 值。调用api-server 存入etcd，并通知kubelet
6. 对应节点上的kubelet 订阅了相关事件,通知容器运行时运行容器
## 了解运行中的 POD
> 每个POD中有一个`pause`基础设施容器用于保存当前pod的命名空间和网络配置,保证其他容器重启后能有和之前一致的命名空间(pod内共享)
## 跨pod 网络
* 同一个pod内容器共享网络端口:
* 同节点pod通信: 基础设施容器启动之前,回味容器创建一个虚拟的 ethernet 接口对,一端连接pod,一端连接主机网络命名空间,主机网络命名空间的接口会使用**容器运行时**配置的网桥,从网络桥接中取IP赋值给容器内的eth0接口,同节点的机器间接通过网桥连接到一起互相通信。
* 不同节点pod通信:跨节点POD IP地址必须是唯一的,所以必须使用非重叠地址段(不在同一个子网),上述网桥连接到物理网络接口上,而每个节点物理网络接口必须处于同一个网段内,这样可以通过物理网络接口再一次转发到对应的节点中。为了实现这一切需要引入网络插件CNI,常用CNI有 flannel,calico,romana,weave Net等
## 服务是如何实现的
> 当在 api-server 主动创建一个service 时,虚拟IP便会立刻分配给他。之后很短时间内，api-server会通知所有运行在工作节点上的kube-proxy客户端,有一个服务被创建了。然后每个kube-proxy都会让该服务在自己运行的节点上可寻址(分为不同的实现,userspace,iptables,ipvs)主要是修改iptables 规则，确保每个目的地微服务的IP端口对的数据包被解析,目的地址被修改,
同时监控service 和endpoint 的修改对应更新规则.

包目的地初始设置为对应的service IP和端口。发送到网络之前,节点的内核会根据配置在该节点的iptables规则处理数据包，内核会检查数据包是否匹配这些iptables规则。原先kube-proxy 更新的规则会导致service IP和端口被替换成随机的pod 的ip和端口

## 运行高可用集群
### 让应用用变得高可用
* 运行多实例来减少宕机的可能性
* 对不能水平扩展的应用使用领导选举机制
### 让控制平面变的高可用
* 运行etcd 集群: etcd 维护奇数台,raft 协议保证一致性
* 运行多实例api-server: api-server 无状态,直接横向扩容
* 确保调度器和控制器的高可用:调度器和控制器依赖领导机制,必须一台工作其他待命
* 选举机制原理:所有调度器实例都会尝试创建一个endpoint资源,包含`holderIdentity`字段,包含了当前领导者的名字,第一个成功将姓名填入改字段的实例将成为领导者。乐观并发保证了竞争资源中仅有一个会胜出,根据是否写成功,判断自己是否是领导者。

## 一些常用命令
```bash
# 查看控制平面
kubectl get componentstatuses
# 查询发布的时间,并保持watch
kubectl get events --watch
```


