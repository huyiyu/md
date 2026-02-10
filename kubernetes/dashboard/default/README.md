# 免鉴权 NodePort 暴露的 kubernetes dashboard
* 干掉了 https 认证证书生成
* 使用 clusterRoleBinding 绑定了集群管理员
* 使用NodePort 暴露了DashBoard 的端口