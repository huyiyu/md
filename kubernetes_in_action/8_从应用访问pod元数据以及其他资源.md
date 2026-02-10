# 从应用访问pod元数据以及其他资源
> 应用往往需要获取运行环境的一些不能预先知道的信息,如当前POD IP 当前主机名或者POD自身的名称。downward API允许通过环境变量或文件传递POD的元数据,这种方式将在Pod定义和状态中取得的数据作为环境变量和文件的值，如图8.1所示。
downward API方式使得我们不必通过修改应用或者使用shell脚本的方式去获取数据在传递给环境变量的方式暴露数据

## 可用的元数据
* pod 的名称
* pod 的IP
* pod 所在的命名空间
* pod 运行节点的名称
* pod 运行所归属的服务账号名称
* 每个容器请求CPU和内存的使用量
* 每个容器请求CPU和内存的限制
* pod 的标签
* pod 的注解
## 使用环境变量暴露pod 元信息
>可以使用 `fieldRef.fieldPath` 配置对应环境变量对应的Downward API 对于CPU 和内存的暴露值单位会根据`divisor`为单位计算相应的值。一个致命的问题是：当pod 元数据如标签 注解被修改时,环境变量 ***不能自动更新*** 
## 使用downward API 卷来传递元数据
> 通过卷挂载API的方式会为每一个ITEM生成对应的文件,并且当元数据更新时内容会自动更新,当使用容器级元数据时,应当指定容器名称。因为我们对于卷的定义是基于POD的

## 与Kubenetes api-server 交互
> 当需要知道其他POD的信息或者整个集群中其他资源的信息时,downward API 无能为力,此时便可使用和API server 交互的方式做到。


### 从客户端与 api-server 交互
>首先获取到集群 api-server 暴露的url,其次使用kube-proxy 处理鉴权相关的内容,便可以直接喝kubenetes 直接通信了 。api-server 提供了一套完整的restful 请求,直接通过本地代理端口通信即可
### 从POD内部和 api-server 交互
>从POD内部交互需要解决三个问题
* 确定 api-server 的位置: 所有namespace 中都存在一个service 名称叫kubenetes 该服务指向kubernetes api-server 根据第五章的内容,可以使用DNS 服务去查询或使用 环境变量去查询
* 确定对方是api-server:每个 kubernetes 集群会自动创建一个secret default-token-xyz 并挂载到每个pod 的/var/run/secrets/kubernetes.io/service-account目录下,该目录包含CA证书 ca.crt
* 确定当前pod 已经认证: 上文提到的secrets 挂载目录下的token文件作为集群凭证可以访问集群 通过 export TOKEN使用它

### 通过 ambassador 容器简化 API 服务器交互
> 在POD中共享容器网络端口,如果想简化和API-SERVER交付方式可以考虑多运行一个容器来执行kubectl proxy。此时便不必自己去处理证书和token的内容，而是直接访问localhost:8081,流量会通过 ambassdor 转发到 api-server 。Dockerfile 如下:
```Dockerfile
FROM alpine
RUN apk update && \
    apk add curl && \
    curl -L -O https://dl.k8s.io/v1.8.0/kubernetes-client-linux-amd64.tar.gz && \
    tar zvxf kubernetes-client-linux-amd64.tar.gz kubernetes/client/bin/kubectl && \
    mv kubernetes/client/bin/kubectl / && \
    rm -rf kubernetes && \
    rm -f kubernetes-client-linux-amd64.tar.gz
ADD kubectl-proxy.sh /kubectl-proxy.sh
ENTRYPOINT /kubectl-proxy.sh
```
```bash
#!/bin/sh
API_SERVER="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT"
CA_CRT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
/kubectl proxy --server="$API_SERVER" --certificate-authority="$CA_CRT" --token="$TOKEN" --accept-paths='^.*'
```



## 一些常用的命令
```bash
# 获得集群URL信息
kubectl cluster-info
# 设置代理,不用自己处理鉴权而由kube-proxy 代替 
kubectl proxy
# 提供POD 访问api-server 的环境变量
export CURL_CA_BUNDLE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
export TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# 通过 curl 访问集群接口
curl -H "Authorization: Bearer ${TOKEN}" https://kubernetes 
```
