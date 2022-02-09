# 运行于Kubernetes 中的容器
## POD 介绍
> POD 是一组并置的容器,代表了Kubernetes 中的基本构建模块,实际项目中我们并不会去部署容器,更多的是针对一组POD容器进行部署和操作。然而并不意味着一个POD要包含多个容器 ———— 实际上只包含一个单独容器也是非常常见的。但是同一个POD内的容器一定运行于同一个节点上,POD内部的容器是不会跨多个工作节点。同一个POD中的容器做到了部分隔离,他们共享命名空间,IP,端口空间(所以同一个POD内不同容器会有端口冲突问题)。但是有不同的文件系统，这是kubernetes 通过配置Docker实现的,此外POD 间可以通过I P的形式相互访问,这也证明了POD内部是没有NAT网络协议存在的
### 为什么需要POD
>多个容器比单个容器多进程要好,因为我们不需要在轻量级容器内部维护多个进程的存活重启,运行,日志管理等内容
### 通过POD合理管理容器
> 官方建议将POD看作独立的机器,每个机器只托管一个特定的应用,因为POD非常轻量,我们可以在几乎不导致任何额外开销的前提下拥有尽可能多的POD,虽然一个POD内部支持多个容器,但这种方式并不值得推荐,比如数据库和服务器就没有必要非要部署在同一台主机上,同理也不推荐将其部署在同一个POD内部。而是应该使用不同的POD 去管理它,从逻辑上说不通。此外，POD是阔缩容的基本单位,如果将不相关的两个容器部署在同一个POD中,那在扩大和缩小容器中将变得极不灵活。
### 何时在POD中部署多个容器
> 当出现应用需要一个主进程和其他辅助进程时,可以考虑在一个POD中部署多个容器,这个时候我们要考虑三个因素
* 他们需要在一起运行还是可以在不同主机上
* 他们代表的是一个整体还是相互独立的组件
* 他们必须一起扩缩容还是可以分别进行
## 使用YAML或JSON 描述文件创建POD
> 使用命令同样可以创建POD,缺点在于无法全面描述你想创建的POD的全貌(因为命令参数毕竟较少,太长的命令也不方便)。此外,使用YAML描述能更好的进行版本管理,充分利用版本管理带来的便利性
### POD 定义的主要部分
* ***metadata***:包含名称,命名空间标签和关于容器的其他的元信息
* ***spec***:包含POD启动的实际说明,如使用镜像,挂载卷,和其他数据
* ***status***:包含当前POD运行时的状态信息,如IP地址启动时间等

## 使用标签组织 POD
> 微服务环境使得部署的POD数量轻松超过 100 个或者可能更多,他们可能是副本或者不同发布版本,要有有效管理这么多POD的的方式,标签是一组key-value 形式的元信息,它可以加到任何资源上,用来选择具有确切资源的标签,同时也支持类似SQL的查询语句,我们可以在创建POD的过程中指定标签,运行时修改标签的方式让k8s 的资源带上标签
### 标签的作用
1. 通过标签选择器列出 pod 子集
2. 使用标签选择器约束POD的调度: 如果想对POD应该调度到哪个节点具有发言权,不应该指定特定的节点,而是应该描述调度到pod的节点应该满足什么条件(健壮性考虑)

## 注解
>注解也是key-value 与标签非常相似,但是注解不是为了保存某种标识存在的,不能像标签一样对对象进行分组,它一般用于标识一些源信息以及K8S 将alpha和beta版本新特性使用，一旦所需要的新特性上线,就会废弃相关注解转而使用新的字段标识。
## 命名空间
>kubernetes 命名空间简单的为对象名称提供了一个作用域,浅显的理解就是将一套集群分割成了相互隔离的环境,ß方便我们在不同命名空间里可以使用相同的名称，一般用于拆分环境如 QA 开发 生产等;命名空间是否提供网络隔离取决于 Kubernetes 所使用的网络方案。当网络方案不提供命名空间的网络隔离时,假如A空间的POD知道了B空间的pod 的IP 那么他们是可以互联的


### 一些常用的命令
```bash 
# 显示更详细的信息(通常包含工作节点 IP等)
kubectl get po [pod] -o wide
# 使用yaml 的格式查看当前POD的描述信息
kubectl get po [pod] -o yaml 
# 查看yaml 中某个key 的帮助文档,使用,子节点等
kubectl explain *.*.*
# 通过某个描述文件创建某种资源
kubectl create -f **.yaml
# 查看某个POD 的日志
kubectl logs [pod] 
# 查看 POD 中某个容器的日志
kubectl logs [pod] -c [container]
# 将pod 端口代理到本地机器 用于端口调试
kubectl port-forward kubia-manual 8080:8080

# 添加标签
kubectl label po [pod] key=value
# 修改标签 --overwrite是必要的,防止你想新增过程中无意修改了值
kubectl label po [pod] key=value --overwrite
# 通过标签过滤 key=value
kubectl get po -l key=value
# 查询拥有标签 key的
kubectl get po -l key
# 查询不具有标签key的
kubectl get po -了’!key‘
# 为节点添加标签,之后可以使用nodeSelector 去选择标签
kubectl label node [node] key=value
# 添加和修改注解(注解key命名建议带上域名避免冲突)
kubectl annotate pod [pod] key=value

# 获取命名空间列表
kubectl get ns 
# 创建命名空间
kubectl create namespace [namespace]
# 从指定空间获取pod列表,不指定为default 命名空间
kubectl get po -n [namespace]
# 从某个命名空间创建资源
kubectl create -f [file] -n [namespace]

# 按名称删除 pod
kubectl delete po [pod]
# 按标签删除 pod 同样value 可以不写 那就删除所有有key 标签的
kubectl delete po -l key=value
# 通过删除整个命名空间来删除pod
kubectl delete ns [namespace]
# 删除命名空间所有pod但是不删除命名空间
kubectl delete po --all -n [namespace]
# 删除命名空间几乎所有的资源 第一个all 表示所有资源类型,第二个all 表示所有资源实例
kubectl delete all --all
```