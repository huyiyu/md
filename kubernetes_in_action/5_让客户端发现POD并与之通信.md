# 让客户端发现 POD 并与之通信
## 为什么需要 Service 
* pod 是短暂的,他随时会因为各种原因启动或者关闭 —— 扩容或缩容,或者是健康检查过不了
* 客户端无法在 POD 启动前知道它的IP地址并预先配置
* 水平伸缩意味着多个 POD 提供了相同服务的能力,最好能负载均衡

## 介绍服务
> kubernetes 服务是为 ***一组功能相同的POD*** 提供 ***单一不变接入点*** 的资源,当服务存在时,它的IP地址和端口不会改变,客户端通过IP地址和端口号建立连接,这些连接会被路由到任意一个POD上。这样客户端不需要知道对应的POD的地址而是通过 Service IP 或者Service Name 代替。同时service 也是通过标签选择器来选择POD的
### 配置服务的会话亲和度
>可通过sessionAffininty 属性配置,该属性有None(默认值)和ClientIP两个值，clientIP配置后会将同一个Client IP的所有请求转发到同一个 POD 上
### 暴露多个端口
> 只需要在Ports 数组下新增不同的对象即可 port 表示当前service 暴露的端口 targetPort 表示Pod 的端口,nodeSelector是多个端口共用的,所以此时应考量是否所有选择的POD都有多个端口的服务暴露,否则可能不能正常提供服务。可通过在 Pod端为Port 取名的方式引用服务,这样可读性更强,并且方便修改端口号
### 服务发现
* pod开始运行时,Kubenetes 会初始化一系列环境变量指向现在存在的服务,如果你创建的服务 ***早于客户端 POD 创建***,POD 上的进程可以根据环境变量获得服务的IP地址和端口号。如果服务晚 于POD 创建则没有
* kubernetes 的默认组件 kube-dns 能察觉到提供内部的DNS解析,每个其他的POD的 /etc/resolv.conf 都会被默认修改为容器内部的DNS地址 所以客户端在知道服务名称的情况下也可以使用 (全限定域名)FQDN 来访问,并且,可以忽略后缀default.svc.cluster.local
### 无法ping通service IP
> 因为服务IP是一个虚拟IP 需要和端口结合才有意义,所以它PING 不通
## 连接集群外部的服务
> 服务的 Endpoint 是指服务和 POD 只见代理流量的桥梁,它用于保存使用标签选择器计算出来的,POD 的IP地址和端口号。意识到这一点后,我们可以通过创建没有标签选择器的Service并手动构建 endpoint 将service 连接向外部IP地址,此时Endpoint 的名称必须和service 名称相互匹配。
## 通过配置外部服务别名的方式请求
> 可以在集群内部设置一个服务的别名,并设置ExternalName指向外部服务的方式配置外部服务的别名,优点是隐藏外部服务的FQDN,统一内部服务的调用名称,便于内部POD 修改指向
## 将服务暴露给外部客户端
> 将服务暴露给外部客户端有三种方式

* 使用NodePort: 在每个集群节点上都打开一个端口,并将该端口的所有流量都重定向到基础服务。该服务仅在内部集群IP和端口上可以访问,但也可通过所有节点上的专用端口访问,此时多个节点都可以访问,如果能保证每个节点上都有对应的 POD 可以设置 `externalTrafficPolicy`为 Local 避免随机POD带来的不必要的网络跳转
* 使用LoadBalancer: 类似于NodePort 是各个云厂商对于NodePort 的不同生产实现,负载均衡器拥有一个独一无二可公开的IP,并将所有服务流量转发到服务内部                                                                       
* 使用Ingress: ingress 是一种外部访问的规则,使用Ingress 需要安装Ingress 控制器 具体下一节说明

## 通过Ingress 暴露服务
> 表示进入的行为,进入的权利,进入的手段
### 优点
>Ingress 相比NodePort 和 LoadBalancer 的优点主要体现在
* 它使用统一的主机名或IP的形式,只为需要暴露的服务申请目录路径
* 他能提供Cookie会话亲和相关的支持。
### Ingress 控制器 
> 创建Ingress 资源需要依赖Ingress控制器,官网提供了控制器的多种实现,需要先安装Ingress 控制器 https://kubernetes.io/docs/concepts/services-networking/ingress/

### 原理
> 通过域名或IP查找找到Ingress控制器,并向其发送Http请求,控制器从头部确定客户端访问的服务,由服务去查询关联的Endpoint获得POD IP 其中Rule 表示Ingress 的查找逻辑,是根据域名和对应URL查询服务的,可支持多个
### 配置Ingress TLS
> 本质上是配置控制器的TLS 控制器内部的请求走的是不加密的此时配置Ingress 的TLS属性,该属性需要声明使用的Secret 和使用Secret 的域名 Ingress 支持4层和七层的负载均衡
## POD 就绪后发出信号
> 从上文可知,Service 通过标签选择器获得了POD IP 并将其记录到Endpoint 内部。却并不是立马对流量进行转发的,需要等待POD本身发出就绪的信号之后,这个概念和存活探针相似,称为就绪探针并且实际应用也和存活探针相似,不同点在于存活探针做存活检查保证 POD控制器(replicaSet 或 DaemonSet等)维持的副本数,而就绪探针保证的是POD是否ready 可以接收流量
### 就绪探针类型
> 与存活探针一致,三种类型，并且也有daley延迟探测,不同的是就绪检测只会判断当前POD是否能接受流量,如果一直不处于ready状态,不会被重启只是接收不到重定向的流量,如果发现POD不能接受流量 应该查看是否ready 状态以及service 有没有将其加入Endpoint列表默认就绪探针检查周期是10s
### 就绪探针的实际作用
* 务必要定义就绪探针：否则POD 在启动时将立即成为流量入口,假如内部容器没有准备好,客户端将会接收到一大堆连接被拒绝的响应
* 不要将停止POD逻辑纳入到就绪探针:k8s会在接收到移除POD请求后立即将其从服务中移除

### 发现所有POD —— 包含未就绪的 POD
>   Service.spec.publishNotReadyAddresses 该属性配置成true 后 无论是否处于就绪状态都会被服务发现,之前使用的是注解方式。如今注解转正了

## 使用 Headless 服务发现独立的 POD
> Headless 服务是指,用户不需要一个Service 代理的虚拟IP,而是将域名通过DNS解析成 POD IP 此时使用 `nslookup` 查询服务名是可以返回多个A记录 操作便是ClusterIP 的值设置成None 此时便是一个无头服务

## 排除服务故障
* service IP 只能在集群内部使用
* 查看就绪探针的返回结果
* 使用FQDN不通过是尝试使用ServiceIP
* 检查是否连接到服务公开端口 而不是目标端口
* 尝试从POD IP先排查应用本身问题



## 一些常见的命令
```bash
# 快速新建服务
kubectl expose rc kubia --type=LoadBalancer --name [service]
# 查看服务列表
kubectl get svc 
# 从 POD 容器中执行一个命令 -- 表示 kubectl 参数的结束
kubectl exec [pod] -- [command]
# 查看服务的详细信息 
kubectl describe svc [service]
# 查看端点的详细信息 
kubectl describe endpoint [endpoint]
# 查看跨所有命名空间下的POD
kubectl get po --all-namespaces
# 获取Ingress 列表
kubectl get ingress
# 直接使用命令创建POD 而不是 ReplicationController
kubectl run [pod] --images=[image] --generator=run-pod/v1
```