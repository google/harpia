Harpia Manual
==================

Harpia is a full stack solution to install and manage Kubernetes clusters,
including basic configuration of Kubernetes runtime, networking, storage, and
monitoring.

## Prerequisites

To finish installation of cluster, you need basic knowledge of Kubernetes, Linux
and YAML.

### Node

You need at least one virtual/physical machine which you have fully control to
setup the Kubernetes cluster. To ensure reliability and extensibility, it's
recommended to have at least three machines as Kubernetes **master node**, and
more than one machines as **compute node**.

You need a separate machine as you **control node** during installation. This
can be your Linux workstation at most times.

<!-- TODO(yfcheng) Hardware requirement and recommendation. -->

If you cannot get the required resources, we recommend cloud Kubernetes
solutions like
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) and
[Tencent Kubernetes Engine](https://intl.cloud.tencent.com/product/tke).

### Networking

All nodes should be reachable from each other in the third layer. In order to
download software packages and container images, all nodes must have access to
the Internet during installation and verification. Offline installation is not
supported now.

## Configuring

The installation script uses [Rook](https://rook.io/) to setup
[Ceph](https://ceph.com/) as a distributed storage system. Ceph combines all the
available disks in the cluster to provide a distributed file system.

To specify which disks are going to be used by Ceph, you should change the
`deviceFilter` option in the config file
[`rook-ceph-cluster.yaml`](https://github.com/google/harpia/blob/master/setup/configs/storage/rook-ceph-cluster.yaml)
. It's explained in the comment how to set a global or node-by-node
`deviceFilter`. See more at
[Rook Config Guide](https://rook.io/docs/rook/v0.9/ceph-cluster-crd.html#storage-selection-settings).

Before installation, please ensure all the disks assigned to Ceph don't contain
any data, partition, or partition table. If there are data already in your disk,
you can run `sudo wipefs -a /dev/sdx` to clean it. **DATA WILL BE ERASED.**

## Run the setup script

***You should only run the script after configuring.***

  1. Copy the code to each node.

         $ scp -r harpia/ remote.host:/tmp/

  1. Choose a node as master, run `machine_init.sh` and `k8s_master_init.sh`.

         $ ssh <the master host>
         master$ bash /tmp/harpia/machine_init.sh
         master$ bash /tmp/harpia/k8s_master_init.sh

     Once finished, use `kubectl get cs` to verify it.

  1. Run `machine_init.sh` on the other nodes.

         $ ssh <all other hosts>
         node $ bash /tmp/harpia/machine_init.sh

     After that, on ***master node***, run
     `kubeadm token create --print-join-command`, copy the output `kubeadm join`
     command and run it on other nodes. Each node should have separated `token`.

  1. On master node, run `kubectl get nodes`. All node should be displayed as
     `Ready`.

## Setup NVIDIA GPU nodes

Please download GPU driver from the
[NVIDIA official website](https://www.nvidia.com/Download/index.aspx), and
install it on every GPU node. Reboot may be required after installation.

During the installation of Harpia, a DaemonSet named `nvidia-gpu-device-plugin`
is deployed to your cluster. It's used to report GPU stats to Kubernetes. Please
add `nvidia.com/gpu` label to all NVIDIA GPU nodes:

```shell
$ kubectl label node <node> nvidia.com/gpu=true
```

After that, those nodes will automatically have the plugin running. GPU
workloads can be scheduled on them.

## FAQ

To be added.

## Verification

### Storage

We provide a script to check the availability of storage. On the master, run:

    $ bash verification/rook-ceph.sh

This script will test `CephFs` and `Ceph Block Device (rbd)`. Another way to
test Ceph is to run `rook/ceph-toolbox` manually. If you want to do this, please
check
[Documentation of Rook](https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md)
. Related configuration is
[verification/configs/storage/rook-ceph-toolbox.yaml](https://github.com/google/harpia/blob/master/verification/configs/storage/rook-ceph-toolbox.yaml)

To test the performance of CephFS and RBD, please run
`verification/rook-ceph-benchmark.sh`. For clusters with Gigabit Ethernet, the
expected sequential read throughput is above 130MiB/s.

### Pod Interconnect Network

Please run `verification/iperf3.sh` to test the performance of the interconnect
network between Pods. For Gigabit Ethernet, the expected speed is above
900Mbits/sec.
