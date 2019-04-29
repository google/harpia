Harpia 使用说明
==================

Harpia 是一套完整的 Kubernetes 集群安装与管理方案，包含了 Kubernetes 集群的运行时、网络、存储以及监控的基本配置。

## 先决条件

完成集群的安装与配置，需要您对 Kubernetes、Linux 以及 YAML 有基本了解。

### 节点

您需要至少一台拥有完全控制权的物理机或虚拟机来搭建 Kubernetes 集群。为了保障服务的可靠性与可扩展性，
建议您至少准备三台机器作为 Kubernetes **主节点**，一台以上机器作为**计算节点**。

您还需要单独的一台计算机作为安装时的**控制节点**，通常您的 Linux 工作站就可以胜任。

<!-- TODO(yfcheng) 机器硬件需求与推荐。 -->

如果您无法获得所需的资源，建议您选用 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)，
[Tencent Kubernetes Engine](https://intl.cloud.tencent.com/product/tke) 等云端 Kubernetes 解决方案。

### 网络

所有节点相互之间应该能够在三层互通。安装与测试阶段需要每台节点都可以访问 Internet，以便下载软件包和容器镜像。
目前尚不支持离线安装。

安装程序可以在中国网络环境中工作。安装过程中使用的软件源包括[清华大学开源软件镜像](https://mirrors.tuna.tsinghua.edu.cn/)、
[中科大开源软件镜像](http://mirrors.ustc.edu.cn/)、[Docker CN](https://registry.docker-cn.com)
和 [Nvidia 中国](https://cn.download.nvidia.com/)等。

## 修改配置

安装脚本使用 [Rook](https://rook.io/) 来配置 [Ceph](https://ceph.com/) 分布式存储系统。
Ceph 将集群中可用的物理磁盘组合在一起，提供一个分布式文件系统。

为了指定 Ceph 所使用的物理磁盘，您必须修改配置文件 [`rook-ceph-cluster.yaml`](https://github.com/google/harpia/blob/master/setup/configs/storage/rook-ceph-cluster.yaml)
中的 `deviceFilter` 选项。配置文件中的注释解释了如何设置全局的或每个节点分别的 `deviceFilter`。详细信息请参考
[Rook 配置文档](https://rook.io/docs/rook/v0.9/ceph-cluster-crd.html#storage-selection-settings)。

在安装过程前，请确保您为 Ceph 所分配的磁盘不含有任何数据，分区或分区表。如果您分配的磁盘中已含有数据，
请运行 `sudo wipefs -a /dev/sdx` 命令，清空相应磁盘。**在此过程中，原有数据会被删除。**

## 运行安装脚本

***请务必完成配置之后再运行脚本***

  1. 复制代码到每台设备上

         $ scp -r harpia/ remote.host:/tmp/

  1. 选择一台设备作为主节点（master)，在该设备上运行 `machine_init.sh` 和 `k8s_master_init.sh`

         $ ssh <the master host>
         master$ bash /tmp/harpia/machine_init.sh
         master$ bash /tmp/harpia/k8s_master_init.sh

     脚本运行完毕之后，可以用 `kubectl get cs` 来验证安装完成。

  1. 在其他设备上运行 `machine_init.sh`

         $ ssh <all other hosts>
         node $ bash /tmp/harpia/machine_init.sh

     之后在 ***master*** 上运行 `kubeadm token create --print-join-command`，并将输出的 `kubeadm join` 命令复制到 node 设备上运行。每台 node 设备需要生成单独的 `token`。

  1. 在 master 上运行 `kubectl get nodes`，所有已加入的 node 都应该显示 `Ready`。

## 安装 NVIDIA GPU 节点

请从 [NVIDIA 官网](https://www.nvidia.com/Download/index.aspx)下载 GPU 驱动，并在所有
GPU 节点上安装。安装后可能需要重启 GPU 节点。

Harpia 的安装过程中已部署了名为 `nvidia-gpu-device-plugin` 的 DaemonSet，用于向 Kubernetes 报告
GPU 状态。请为所有具有 NVIDIA GPU 的节点打上 `nvidia.com/gpu` 标签：

```shell
$ kubectl label node <node> nvidia.com/gpu=true
```

之后这些节点会自动运行这个插件，并可以被调度需要 GPU 的工作负载。

## 疑难解答

To be added.

## 验证安装

### 存储系统

我们提供了脚本来检查存储系统是否可用。在 master 上运行

    $ bash verification/rook-ceph.sh

该脚本将分别测试 `CephFs` 和 `Ceph Block Device (rbd)`。除此之外还可以使用 `rook/ceph-toolbox` 来手动检查 Ceph 的状态。如果要手动检查，请参考 [rook 文档](https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md)。
相关的配置文件有 [verification/configs/storage/rook-ceph-toolbox.yaml](https://github.com/google/harpia/blob/master/verification/configs/storage/rook-ceph-toolbox.yaml)。

如需测试 CephFS 与 RBD 的性能，请运行 `verification/rook-ceph-benchmark.sh` 。
对于千兆以太网互联的集群，期望顺序读取速度在 130MiB/s 或以上。

### Pod 互联网络

请运行 `verification/iperf3.sh` 来测试 Pod 间的互联网络性能。对于千兆以太网，期望性能应在
900Mbits/sec 以上。
