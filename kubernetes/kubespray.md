# 使用kuberspray 离线部署攻略
## 初始条件
1. 最少三台干净的2C4G机器(物理机或虚拟机)
2. 一台带有docker的机器(最好不要是windows)
## 离线包下载
1. 带docker 的机器运行以下命令
```bash
# 生成离线环境下需要下载的镜像和文件
docker run --name generator \
    quay.io/kubespray/kubespray:v2.23.1 \
    /kubespray/contrib/offline/generate_list.sh
# 把生成的文件复制出来
docker cp generator:/kubespray/contrib/offline/temp .
```
根据temp中的目录下载以下文件和镜像,大概是
```bash
# file.list
https://dl.k8s.io/release/v1.27.7/bin/linux/amd64/kubelet
https://dl.k8s.io/release/v1.27.7/bin/linux/amd64/kubectl
https://dl.k8s.io/release/v1.27.7/bin/linux/amd64/kubeadm
https://github.com/etcd-io/etcd/releases/download/v3.5.9/etcd-v3.5.9-linux-amd64.tar.gz
https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
https://github.com/projectcalico/calico/releases/download/v3.25.2/calicoctl-linux-amd64
https://github.com/projectcalico/calico/archive/v3.25.2.tar.gz
https://github.com/cilium/cilium-cli/releases/download/v0.15.0/cilium-linux-amd64.tar.gz
https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.27.1/crictl-v1.27.1-linux-amd64.tar.gz
https://storage.googleapis.com/cri-o/artifacts/cri-o.amd64.v1.27.1.tar.gz
https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz
https://github.com/opencontainers/runc/releases/download/v1.1.9/runc.amd64
https://github.com/containers/crun/releases/download/1.8.5/crun-1.8.5-linux-amd64
https://github.com/containers/youki/releases/download/v0.1.0/youki_0_1_0_linux.tar.gz
https://github.com/kata-containers/kata-containers/releases/download/3.1.3/kata-static-3.1.3-x86_64.tar.xz
https://storage.googleapis.com/gvisor/releases/release/20230807/x86_64/runsc
https://storage.googleapis.com/gvisor/releases/release/20230807/x86_64/containerd-shim-runsc-v1
https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz
https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-linux_amd64.tar.gz
https://github.com/containerd/containerd/releases/download/v1.7.5/containerd-1.7.5-linux-amd64.tar.gz
https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.4/cri-dockerd-0.3.4.amd64.tgz
https://github.com/lework/skopeo-binary/releases/download/v1.13.2/skopeo-linux-amd64
https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64
# image.list
docker.io/mirantis/k8s-netchecker-server:v1.2.2
docker.io/mirantis/k8s-netchecker-agent:v1.2.2
quay.io/coreos/etcd:v3.5.9
quay.io/cilium/cilium:v1.13.4
quay.io/cilium/operator:v1.13.4
quay.io/cilium/hubble-relay:v1.13.4
quay.io/cilium/certgen:v0.1.8
quay.io/cilium/hubble-ui:v0.11.0
quay.io/cilium/hubble-ui-backend:v0.11.0
docker.io/envoyproxy/envoy:v1.22.5
ghcr.io/k8snetworkplumbingwg/multus-cni:v3.8
docker.io/flannel/flannel:v0.22.0
docker.io/flannel/flannel-cni-plugin:v1.1.2
quay.io/calico/node:v3.25.2
quay.io/calico/cni:v3.25.2
quay.io/calico/pod2daemon-flexvol:v3.25.2
quay.io/calico/kube-controllers:v3.25.2
quay.io/calico/typha:v3.25.2
quay.io/calico/apiserver:v3.25.2
docker.io/weaveworks/weave-kube:2.8.1
docker.io/weaveworks/weave-npc:2.8.1
docker.io/kubeovn/kube-ovn:v1.11.5
docker.io/cloudnativelabs/kube-router:v1.5.1
registry.k8s.io/pause:3.9
ghcr.io/kube-vip/kube-vip:v0.5.12
docker.io/library/nginx:1.25.2-alpine
docker.io/library/haproxy:2.8.2-alpine
registry.k8s.io/coredns/coredns:v1.10.1
registry.k8s.io/dns/k8s-dns-node-cache:1.22.20
registry.k8s.io/cpa/cluster-proportional-autoscaler:v1.8.8
docker.io/library/registry:2.8.1
registry.k8s.io/metrics-server/metrics-server:v0.6.4
registry.k8s.io/sig-storage/local-volume-provisioner:v2.5.0
quay.io/external_storage/cephfs-provisioner:v2.1.0-k8s1.11
quay.io/external_storage/rbd-provisioner:v2.1.1-k8s1.11
docker.io/rancher/local-path-provisioner:v0.0.24
registry.k8s.io/ingress-nginx/controller:v1.8.1
docker.io/amazon/aws-alb-ingress-controller:v1.1.9
quay.io/jetstack/cert-manager-controller:v1.11.1
quay.io/jetstack/cert-manager-cainjector:v1.11.1
quay.io/jetstack/cert-manager-webhook:v1.11.1
registry.k8s.io/sig-storage/csi-attacher:v3.3.0
registry.k8s.io/sig-storage/csi-provisioner:v3.0.0
registry.k8s.io/sig-storage/csi-snapshotter:v5.0.0
registry.k8s.io/sig-storage/snapshot-controller:v4.2.1
registry.k8s.io/sig-storage/csi-resizer:v1.3.0
registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.4.0
docker.io/k8scloudprovider/cinder-csi-plugin:v1.22.0
docker.io/amazon/aws-ebs-csi-driver:v0.5.0
docker.io/kubernetesui/dashboard:v2.7.0
docker.io/kubernetesui/metrics-scraper:v1.0.8
quay.io/metallb/speaker:v0.13.9
quay.io/metallb/controller:v0.13.9
registry.k8s.io/kube-apiserver:v1.27.7
registry.k8s.io/kube-controller-manager:v1.27.7
registry.k8s.io/kube-scheduler:v1.27.7
registry.k8s.io/kube-proxy:v1.27.7
```
> 补充,可以通过命令批量下载,由于镜像比较多可以生成下载命令类似以下
```bash
awk '{print "curl -LO "$1";"}' files.list
awk '{print "docker pull "$1";"}' images.list
```
## 上传至私服仓库
可使用nexus 随附 docker-compose.yml 如下
```yml
version: "3.0"
services:
  nexus:
    image: sonatype/nexus3
    ports:
    - 8081:8081
    - 80:8082
    volumes:
    - ./data:/nexus-data
    restart: always
```
>然后自己操作新建 docker 仓库和 raw 仓库,自己调试直到能正常下载,总结经验就是直到curl 可从仓库下载,docker pull 可下载

## 准备运行环境
```bash
# 1. 创建一个kubespray容器
docker run --name code -it --rm quay.io/kubespray/kubespray:v2.23.1 bash 
# 2. 不停止这个窗口再打开另一个窗口,
docker cp code:/kubespray .
# 3. 关闭容器退出重新创建
docker run --rm -it --name startup  \
    -v $(pwd)/kubespray:/kubespray \
    -v /root/.ssh/:/root/.ssh  \
    registry.huyiyu.icu/repository/k8s-docker/k8s/kubespray:v2.23.1 bash

# 4. 提前配置生成公钥到每台机器并输入密码
ssh-keygen -t rsa -C huyiyu@k8s.com.cn
ssh-copy-id root@192.168.2.108
ssh-copy-id root@192.168.2.109
ssh-copy-id root@192.168.2.110
# 5. 生成部署文件
declare -a IPS=(192.168.2.108 192.168.2.109 192.168.2.110)
cp -rfp inventory/sample inventory/mycluster
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
# 6. 如果之前尝试安装过k8s 卸载他们
ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root reset.yml
```
## 修改配置文件
### 1. 修改日志输出 
>文件位于: `inventory/mycluster/group_vars/all/all.yml`
`sed -r -i 's/(unsafe_show_logs: ).*/\1true/g'  inventory/mycluster/group_vars/all/all.yml`
### 2. 修改下载地址和镜像地址 
>文件位于 `kubespray/inventory/mycluster/group_vars/all/offline.yml` ***按自身情况修改***

```yml 
---
registry_host: "registry.huyiyu.icu/repository/k8s-docker"
files_repo: "http://admin:huyiyu12345@registry.huyiyu.icu:8081/repository/k8s-file/k8s"
kube_image_repo: "{{ registry_host }}"
gcr_image_repo: "{{ registry_host }}"
github_image_repo: "{{ registry_host }}"
docker_image_repo: "{{ registry_host }}"
quay_image_repo: "{{ registry_host }}"
## Kubernetes components
kubeadm_download_url: "{{ files_repo }}/kubeadm"
kubectl_download_url: "{{ files_repo }}/kubectl"
kubelet_download_url: "{{ files_repo }}/kubelet"
# CNI Plugins
cni_download_url: "{{ files_repo }}/cni-plugins-linux-{{ image_arch }}-{{ cni_version }}.tgz"
# cri-tools
crictl_download_url: "{{ files_repo }}/crictl-{{ crictl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
# [Optional] etcd: only if you use etcd_deployment=host
etcd_download_url: "{{ files_repo }}/etcd-{{ etcd_version }}-linux-{{ image_arch }}.tar.gz"
# [Optional] Calico: If using Calico network plugin
calicoctl_download_url: "{{ files_repo }}/calicoctl-linux-{{ image_arch }}"
# [Optional] Calico with kdd: If using Calico network plugin with kdd datastore
calico_crds_download_url: "{{ files_repo }}/calico-3.25.2.tar.gz"
# [Optional] helm: only if you set helm_enabled: true
helm_download_url: "{{ files_repo }}/helm-{{ helm_version }}-linux-{{ image_arch }}.tar.gz"
# [Optional] runc: if you set container_manager to containerd or crio
runc_download_url: "{{ files_repo }}/runc.{{ image_arch }}"
# [Optional] containerd: only if you set container_runtime: containerd
containerd_download_url: "{{ files_repo }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"
nerdctl_download_url: "{{ files_repo }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
# [Optional] Krew: only if you set krew_enabled: true
krew_download_url: "{{ files_repo }}/krew-{{ host_os }}_{{ image_arch }}.tar.gz"
```
### 3. 修改内网镜像登录
> 默认kubespray 会安装 containerd 并进行 nerdctl 下载,而 nerdctl 使用的认证文件是 `~/.docker/config.json`
1. 首先要保证配置支持不安全的仓库 insecure-registry, 修改`inventory/mycluster/group_vars/all/containerd.yml` 修改33行和43行的内容

```yml
containerd_registries_mirrors:
  - prefix: registry.huyiyu.icu
    mirrors:
      - host: http://registry.huyiyu.icu
        capabilities: ["pull", "resolve"]
        skip_verify: true

containerd_registry_auth:
  - registry: registry.huyiyu.icu
    username: admin
    password: huyiyu12345
```
2. 保证自动对内网镜像仓库登录, 有三种方案
* 最笨的方案: **!!!报错下载镜像失败**后,在执行机器上执行 `nerdctl -n k8s.io login -u username -p password`
* 稍聪明点的方案, 使用ansible shell 模块发送上面命令到每台k8s机器,修改 `roles/container-engine/containerd/tasks/main.yml` 的第128行新增以下内容(注意缩进task)
```yml
    - name: Containerd | Create registry directories
      file:
        path: "/root/.docker"
        state: directory
        mode: 0755
    - name: Containerd | huyiyu made add .docker config.json to solve nerdctl login problem
      copy:
        src: config.json
        dest: /root/.docker/config.json  
```
复制 config.json
```json
{
	"auths": {
        /*内网仓库的映射*/
		"registry.huyiyu.icu": {
            /*用户名:密码的base64编码*/
			"auth": "YWRtaW46aHV5aXl1MTIzNDU="
		}
	}
}
```
* 最聪明的方案,放开认证免登录就能获取镜像,nexus 这里一大堆坑无法达到
### 4. 修改addons 扩展相关

> 直接修改 `kubespray/inventory/mycluster/group_vars/k8s_cluster/addons.yml`中的配置,看情况决定修改具体内容


## 执行脚本部署
```bash
ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml
```

## 校验
>等待执行完成,执行`kubectl get all --all-namespaces`

