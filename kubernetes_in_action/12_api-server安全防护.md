# api-server 的安全防护
>上一个章节主要讲到,调用api-server 有三个阶段：认证，鉴权，准入控制。首先经过认证插件列表，列表中每个插件都可以检查这个请求和尝试确认谁在发送请求。列表中插件列表依次判断具体请求来源，一旦有插件识别了用户的具体用户名，组信息，用户ID 其他插件将放行直接进入鉴权阶段，目前主要的认证方式有

* 客户端证书
* 请求头的token
* 基础的 http 认证
* 其他

## 用户和组
### 用户
>kubernetes 区分了两种连接到api 服务器的客户端 **POD**,**真实用户**。这两种客户端都会使用上述的认证插件进行认证,用户应该被管理到用户系统中,而pod 使用service-account 这种资源认证,没有资源代表用户账号,这也说明了不能通过api 服务器创建，更改，删除用户
### 组
>正常用户会属于一个或多个组。组可以一次给多个用户赋予权限，而不是单独给用户赋权。有一些系统生成的特殊的组有特殊含义
* system:unauthenticated 组用于所有认证插件都不会认证客户端身份的请求
* system:authenticated 组会分配给一个成功通过认证的用户
* system:serviceaccounts 组包含所有在系统中的serviceAccount
* system:serviceaccounts:<namespace> 组包含了所有在特定命名空间的serviceAccount
## serviceAccount 介绍
> 从第八章我们了解到,pod可以通过自身挂载的CA证书和TOKEN 与api-server 通信,证书token便是由serviceAccount 提供的,apiserver通过识别token 对应访问者为一个serviceAccount。每个namespace创建时都会产生一个名称为default 的serviceAccount,一个serviceAccount


## 一些常用命令
```bash
# 查看服务账号
kubectl get sa
# 创建一个服务账号 name 叫 other
kubectl create sa other
```