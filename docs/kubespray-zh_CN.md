使用 Kubespary 建立与管理 Kubernetes 集群
======================================

Harpia 可以使用 [Kubespray](https://kubespray.io) 进行 Kubernetes 基本集群的安装与管理。
过程中的任何有关 Kubespray 的问题，都可以参考 Kubespay 的代码与文档。

## 建立集群

### 安装操作系统

您可以选择在节点上安装任何 Kubespray 支持的操作系统，例如 Debian 9、Ubuntu 18.04、CentOS 7
等等。但若您在集群中运行使用 NVIDIA GPU 的工作负载，请选择 Ubuntu 18.04 或 CentOS 7。

建议您在所有的节点上安装同样的操作系统，以便于统一配置与更新。

安装过程中，请建立一个非 root 用户用于登录与管理操作，并确保该用户可以通过 sudo 获取 root 权限。

### 配置 SSH

安装时，控制节点需要通过 SSH 远程控制其他节点进行安装。您需要配置控制节点与其他节点之间的 SSH 密钥认证，
保证从控制节点可以无需密码 SSH 登录其他节点。配置方法请参考 [Ubuntu 文档](https://help.ubuntu.com/lts/serverguide/openssh-server.html.en#openssh-keys)。
为了安全，推荐禁用 root 远程登录。

### 配置无密码 sudo

为了自动化安装过程，需要在所有节点上开启无密码 sudo。
例如在 Ubuntu 18.04 中，运行 `sudo visudo` 命令，找到打开的文件中的
```
%sudo   ALL=(ALL:ALL) ALL
```
将其更改为
```
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
```
并保存。

### 配置防火墙

<!-- TODO(yfcheng)
Detailed instructions to setup firewall both before and after installation.
-->

在安装前，请关闭所有节点上的防火墙。远程调整网络配置有风险，请谨慎操作。

推荐在**安装后**使用防火墙进行网络加固，除了从特殊网段 SSH 之外，禁用从外网发起的连接。
**但安装过程中，请关闭防火墙。**

### 准备控制节点

安装过程中需要控制节点上有 `git`、`ansible`、`pip` 等软件包。请根据控制节点系统发行版选择安装方式。
若为 Ubuntu 或 Debian，则可以通过以下命令安装：
```shell
$ sudo apt install -y git ansible python-pip
```

<!-- TODO(yfcheng)
The v2.8.3 version of Kubespray is in-capble of setting up GPU in China. Upgrade
the version when https://github.com/kubernetes-sigs/kubespray/pull/4247 is
released.
-->

在控制节点上，下载 Harpia 与 Kubespray 源代码到本地：
```shell
$ git clone https://github.com/kubernetes-sigs/kubespray.git
$ (cd kubespray; git checkout 9e8e069)
$ git clone https://github.com/google/harpia.git
```

然后安装 Kubespray 必要的软件包：
```shell
$ cd kubespray
kubespray $ pip install --user -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 配置 Kubespray

复制 Harpia 的样例配置目录 `setup/inventory/9e8e069` 到 Kubespray 的 `inventory/harpia`：
```shell
kubespray $ cp -rfp ../harpia/setup/inventory/9e8e069 inventory/harpia
```

将所有节点信息填入 `inventory/harpia/hosts.ini`，这包括节点地址、名称、角色（是否为主节点）等。
您可以选择参考文件中的注释修改，或使用以下命令自动完成：
```shell
kubespray $ declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
kubespray $ CONFIG_FILE=inventory/harpia/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```
其中 `IPS` 后面的括号中应填入所有节点的 IP 地址。

最后，请仔细查看 `inventory/harpia/group_vars` 下的所有文件，并按需求更改其中的选项。

特别地，您需要为 Kubernetes 集群[准备 Pod IP 段与 Service IP 段](https://kubernetes.io/docs/setup/scratch/#network-connectivity)。
这两个 IP 段与物理 IP 段必须两两不重叠。您可能还需要为 Kubernetes 集群[准备一个域名](https://kubernetes.io/zh/docs/concepts/services-networking/dns-pod-service/)，
用于为 Service 提供 DNS 名称。请更改 `inventory/harpia/group_vars/k8s-cluster/k8s-cluster.yml` 中的：
* `kube_service_addresses` 选项为您的 Kubernetes Service IP 段。
* `kube_pods_subnet` 选项为您的 Kubernetes Pod IP 段。
* `cluster_name` 选项为您的 Kubernetes 域名。

如果您希望在某些或全部节点上开启 NVIDIA GPU 支持，请取消
`inventory/harpia/group_vars/k8s-cluster/k8s-cluster.yml` 文件中
`nvidia_accelerator_enabled`、`nvidia_gpu_nodes`、`nvidia_driver_version`
与 `nvidia_gpu_flavor` 的注释，并修改为合适的值。同时，如果您在 GPU 节点上使用的是 Ubuntu
系统，请一并取消 `inventory/harpia/group_vars/all/docker.yml` 文件开头 `docker_storage_options`
一项的注释。

### 创建 Kubernetes 集群

Kubernetes 集群安装过程全程由 Kubespray 自动完成。

请在控制节点运行：
```shell
kubespray $ ansible-playbook -i inventory/harpia/hosts.ini --become --become-user=root cluster.yml
```

受网络与节点性能影响，安装过程可能会持续数十分钟或更长，请耐心等候。安装命令是幂等的，因此如果安装中途出现错误，
请检查 Kubespray 输出的错误信息，修正后重新运行安装命令即可。

### 访问 Kubernetes 集群

安装好的 Kubernetes 集群可以通过 `kubectl` 或 Kubernetes Dashboard 访问。

将第一台主节点上的
`/etc/kubernetes/admin.conf` 文件复制到控制节点上的 `~/.kube/config`。之后运行
`kubectl get cs` 命令，验证是否可通过 `kubectl` 访问集群，并查看集群状态。若正常，应得到类似下面的输出：
```
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-1               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
```

若希望通过 Kubernetes Dashboard 访问集群，则需要首先在 Kubernetes 中创建一个集群管理员用户。
请进入 Harpia 源码目录，并安装 `setup/configs/admin.yaml`：
```shell
harpia $ kubectl apply -f setup/configs/admin.yaml
```

然后运行如下命令，并复制出 `token` 一项的值。这即为您访问 Kubernetes 的凭据，请妥善保管。
```shell
$ kubectl -n kube-system describe secret \
  $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

最后，在控制节点上运行 `kubectl proxy` 并用浏览器打开
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
，选择"Token"一项并填入刚刚刚复制的凭据，即可登录 Kubernetes Dashboard。
