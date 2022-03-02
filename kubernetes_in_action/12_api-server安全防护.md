# api-server 的安全防护

> 上一个章节主要讲到,调用api-server 有三个阶段：认证，鉴权，准入控制。首先经过认证插件列表，列表中每个插件都可以检查这个请求和尝试确认谁在发送请求。列表中插件列表依次判断具体请求来源，一旦有插件识别了用户的具体用户名，组信息，用户ID 其他插件将放行直接进入鉴权阶段，目前主要的认证方式有

* 客户端证书
* 请求头的token
* 基础的 http 认证
* 其他

## 用户和组

### 用户

> kubernetes 区分了两种连接到api 服务器的客户端 **POD**,**真实用户**。这两种客户端都会使用上述的认证插件进行认证,用户应该被管理到用户系统中,而pod 使用service-account 这种资源认证,没有资源代表用户账号,这也说明了不能通过api 服务器创建，更改，删除用户

### 组

> 正常用户会属于一个或多个组。组可以一次给多个用户赋予权限，而不是单独给用户赋权。有一些系统生成的特殊的组有特殊含义

* system:unauthenticated 组用于所有认证插件都不会认证客户端身份的请求
* system:authenticated 组会分配给一个成功通过认证的用户
* system:serviceaccounts 组包含所有在系统中的serviceAccount
* system:serviceaccounts:`<namespace>` 组包含了所有在特定命名空间的serviceAccount

### serviceAccount 介绍

> 从第八章我们了解到,pod可以通过自身挂载的CA证书和TOKEN 与api-server 通信,证书token便是由serviceAccount 提供的,apiserver通过识别token 对应访问者为一个serviceAccount。每个namespace创建时都会产生一个名称为default 的serviceAccount,一个serviceAccount提供了当前应用可以挂载的secret相关的内容,而serviceAccount的token 是api 识别当前请求方的根据，在pod 模板上设置 `serviceAccountName`来决定 POD 使用哪个serviceAccount  一个serviceAccount包含以下内容。

automountServiceAccountToken: 是否自动挂载token 默认为 `true`
imagePullSecrets: 下载镜像所需的secret 列表
secrets: pod 运行时所使用的持有的密钥,一般token 也会存在这里

## 通过基于角色的权限控制加强集群安全

> 1.6版本之前提供的token默认权限非常大，不安全容易被攻击。1.8版本之后授权比较安全。

### RBAC 授权插件

> kubernetes 的apiserver 接口严格遵循restful 协议,rbac 插件根据restful 接口形式判断,当前用户想要执行的操作(查看svc,修改secret等),除了对资源的crud,也包含对非资源url的管理 如healthz 这样的接口。
> kubernetes的rbac插件通过读取 role clusterRole roleBinding clusterRoleBinding 四个对象实现了对资源的控制。role和clusterRole 实现了对资源的绑定,描述了拥有当前角色的账号能操作什么,roleBinding和ClusterRoleBinding决定了哪些账号(serviceAccount 或user 或group)绑定到了对应的角色上。其中角色和角色绑定是命名空间内的资源,而集群角色和集群角色绑定是全局资源。接下来讲述一下使用方面的区别

* Role: 用于描述并管理命名空间内的资源的对象,命名空间内的资源(如 服务,持久卷声明，部署，有状态副本集等) 仅能使用roleBinding 绑定,且resource 只能关联命名空间内资源
* ClusterRole: 用来描述并管理全局范围内的资源, 全局资源(命名空间，节点，持久卷 等)可以使用特定命名空间的roleBinding 表示允许授权当前命名空间内的资源,也可以使用clusterRoleBinding 认为是绑定全局资源,同时resource 既能关联全局资源,也能关联空间内资源表示一个在多空间公用的role模板
* roleBinding: 用来将role或clusterRole 绑定给 serviceAccount 或其他资源的连接对象,使用roleBinding 绑定
* ClusterRoleBinding:只能用于关联clusterRole 表示全局资源的关联

### Role和ClusterRole 的核心清单属性

`rule.ApiGroups`: 对API分组的设置,只要当前请求匹配api分组中的任何一个都允许通过
`rule.nonResourceURLs`:针对非资源请求的url 支持这个* 通配符，clusterRoleBinding 绑定才生效
`rule.resourceNames`:具体的资源名称 为空表示都允许
`rule.resources`:资源类型 * 表示所有资源都允许
`rule.verb`: 访问的行为 支持 watch list get post delete put 等 * 表示都接受

### RoleBinding 和ClusterRoleBinding 的核心清单属性

`roleRef`: 指向对应的 Role 或 ClusterRole  指定一个
`roleRef.apiGroup`: 对应的对象的api分组
`roleRef.kind`:对应对象类型 可能是Role或ClusterRole
`roleRef.name`:对应对象具体名称
`subjects`: 指向对应的serviceAccount或User 或Group  可以指定多个
`subjects.apiGroup`: 对应的访问者的 api分组
`subjects.kind`: 对应访问者的类型 一般是User Group ServiceAccount
`subjects.name`: 对应访问者的名称
`subjects.namespace`:对应访问者所属命名空间 如果访问者是User 或Group这种没有命名空间的要报错

* 一个roleBinding(或clusterRoleBinding)只能绑定一个Role 但可以绑定多个subject
* 尽管serviceAccount 和 role和RoleBinding 是有所属命名空间的,但是pod 可以跨命名空间引用其他空间的serviceAccount 这样就拥有了访问其他命名空间甚至管理员权限
* 一个ServiceAccount 想访问集群资源或非资源url 一定要用 clusterRoleBinding 绑定ClusterRole
* 一个RoleBinding 可以绑定定义命名空间内资源的clusterRole 用于访问具体命名空间内的资源,此时Cluster 作为命名空间内资源模板角色存在
* 一个ClusterRoleBinding 可以绑定命名空间内资源的 clusterRole 用于访问所有命名空间内的资源

| 访问的资源                               | 角色类型    | 绑定类型           |
| ---------------------------------------- | ----------- | ------------------ |
| 集群级别资源                             | ClusterRole | ClusterRoleBinding |
| 非资源型URL                              | ClusterRole | ClusterRoleBinding |
| 在任何命名空间的资源                     | ClusterRole | ClusterRoleBinding |
| 在具体命名空间的资源(在多个命名空间重用) | ClusterRole | RoleBinding        |
| 在具体命名空间的资源(不需要重用)         | Role        | RoleBinding        |

### 比较重要的默认的 集群角色和常用的原则
* 用 view 角色设置允许对资源的只读访问
* 用 edit 集群角色允许对资源的读写修改,但不允许读写修改role 和roleBinding 也不允许读写修改Secret 防止权限扩散
* 用 admin 角色赋予一个命名空间全部的控制权
* 用 cluster-admin 得到完全的控制
### 理性授予权限
> 授权要慎重,能不给尽量不给,假设你的应用可能被入侵,为每个pod 创建特定serviceAccount

## 一些常用命令

```bash
# 查看服务账号
kubectl get sa
# 创建一个服务账号 name 叫 other
kubectl create sa other
```
