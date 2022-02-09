## 开始使用kubernetes 和docker
### POD 描述
> 一个POD 是**一组**紧密相关的容器,他们总是一起运行在同一个工作节点和同一个Linux 名称空间中,每个 POD 就像一台独立的逻辑机器独立拥有自己的IP,主机名,进程等,运行独立的应用程序。应用程序可以是单个进程，运行在单个容器中,也可以是一个主应用进程和其他支持进程。每个进程在自己的容器中运行。一个 POD 上的所有容器都运行在同一个物理节点上,而不同 POD 中的容器,即使当前调度在同一个节点上,下一次可能会出现在不同的工作节点上。pod 按照中文翻译是豆荚,表示他像豆荚一样包裹着里面的豆子(容器)

### kubectl 原理
> 当运行kubectl 相关命令时,kubectl 会发送HTTP请求访问API-server 告诉服务端客户端的期望,客户端根据期望比如创建一个replicationController,接着 replicationController是一个POD控制器,它会根据期望创建对应的POD,POD被kube

### 使用service 访问 POD
> 要让 POD 可以被访问,必须用服务对象公开它,而要让POD从外部能被访问,需要创建一个特殊的LoadBalancer类型的服务,如果是常规服务,只能从外部访问它，而loadBalancer 创建的服务会在外部创建一个负载均衡,可以通过这个公共IP访问集群内部
### ReplicationController 和 POD 和 Service 是如何组合在一起的
> k8s 不会直接创建和使用容器,它的基本构件是POD,同时也不能直接创建POD。而是通过`kubectl run` 命令创建出来一个 replicationController,它是一个POD控制器,用于创建POD实例,并使得POD的副本始终以一个固定的数量运行在k8s集群中,如果POD因为各种原因死亡(被删除,健康检查不通过),ReplicationController 会重新创建POD副本。同时为了从外部能访问POD,需要让 k8s 将 replicationController 管理的POD 通过 service 组件对外暴露,Service 管理当POD在集群的节点间不断飘移时,始终能代理到相关的流量,提供一个不变的Service IP和service-name 解决不断变化的POD IP的问题
