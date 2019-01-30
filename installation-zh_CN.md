Harpia 使用说明
==================

Harpia 是一个完整的 Kubernetes 集群安装包，包含了 Kubernetes 集群的网络、Ingress、存储以及监控的基本配置。

## 准备工作

完成集群配置需要对 Kubernetes 和 Linux 有基本了解。

### 操作系统:

在运行任何脚本之前，请在集群的每台设备上安装好 Ubuntu 16.04 Xenial Xerus。尚未测试其他操作系统和版本。

### 网络

所有设备相互之间应该互通。安装与测试阶段需要每台设备都有公网连接，以便下载软件包和 Docker image。推荐在网络层进行安全加固，除了从特殊网段 SSH 之外，禁用从外网发起的连接。远程调整网络配置有风险，请谨慎操作。

### SSH

确保所有的设备都可以通过 SSH 访问。安装过程中可能会需要重复 SSH 到不同的设备，推荐在所有机器上设置好 ssh-key 并禁用 root 远程登录。请参考相关的 [Ubuntu 文档](https://help.ubuntu.com/lts/serverguide/openssh-server.html.en#openssh-keys)。

## 软件和软件源

安装脚本会将[阿里云的 Kubernetes软件源](https://mirrors.aliyun.com/kubernetes/)和
[清华大学的 Docker CE 软件源](https://mirrors.tuna.tsinghua.edu.cn/docker-ce/)加入系统设置，并安装以下软件的特定版本及其依赖:
 `docker`，`kubeadm`, `kubectl`, `kubelet`。

每台 Kubernetes node 上的 Docker 源将会被修改为 [Docker 中国镜像](https://docker-cn.com)。

在搭建 Kubernetes 集群的过程中会下载以下 Docker image:
`calico`, `nginx`，`rook/ceph`。

在测试过程中会使用以下 Docker image:
`mysql`, `cloudcmd`, `rook/ceph-toolbox`。

## 安装

### 获取脚本

	$ git clone --branch stable https://github.com/google/harpia.git

### 修改配置

安装脚本使用 [rook](https://rook.io/) 来配置 [Ceph](https://ceph.com/)。Ceph 将每台 Kubernetes node
上的物理硬盘组合成一个分布式文件系统。我们在配置文件 [`rook-ceph-cluster.yaml`](https://github.com/google/harpia/blob/master/setup/configs/storage/rook-ceph-cluster.yaml)
中设置 `deviceFilter`，
将物理硬盘分配给 Ceph 使用。配置文件中的注释解释了如何设置全局和单个 Kubernetes node 的 `deviceFilter`。详细信息请参考
[rook 配置文档](https://github.com/rook/rook/blob/master/Documentation/ceph-cluster-crd.md#storage-selection-settings)。

***在安装过程中，分配给 Ceph 的硬盘会被格式化，原有数据会被删除。***请确保设置了正确的 `deviceFilter`。

### 运行安装脚本

***请务必完成配置之后再运行脚本***

  1. 复制代码到每台设备上

		$ scp -r harpia/ remote.host:/tmp/

  3. 选择一台设备作为主节点（master)，在该设备上运行 `machine_init.sh` 和 `k8s_master_init.sh`

		$ ssh <the master host>
		master$ bash /tmp/harpia/machine_init.sh
		master$ bash /tmp/harpia/k8s_master_init.sh

	脚本运行完毕之后，可以用 `kubectl get cs` 来验证安装完成。

  2. 在其他设备上运行 `machine_init.sh`

		$ ssh <all other hosts>
		node $ bash /tmp/harpia/machine_init.sh

	之后在 ***master*** 上运行 `kubeadm token create --print-join-command`，并将输出的 `kubeadm join` 命令复制到 node 设备上运行。每台 node 设备需要生成单独的 `token`。

  3. 在 master 上运行 `kubectl get nodes`，所有已加入的 node 都应该显示 `Ready`。

## 疑难解答

To be added.

## 验证安装

### 存储系统

我们提供了脚本来检查存储系统是否可用。在 master 上运行

	$ bash verification/rook-ceph.sh

该脚本将分别测试 `Cephfs` 和 `Ceph Block Device (rbd)`。除此之外还可以使用 `rook/ceph-toolbox` 来手动检查 Ceph 的状态。如果要手动检查，请参考 [rook 文档](https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md)。
相关的配置文件有 [verification/configs/storage/rook-ceph-toolbox.yaml](https://github.com/google/harpia/blob/master/verification/configs/storage/rook-ceph-toolbox.yaml)。
