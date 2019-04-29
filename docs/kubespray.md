Use Kubespary to Setup and Manage Kubernetes Cluster
====================================================

[Kubespray](https://kubespray.io) may be used in Harpia to setup and manage
Kubernetes clusters. For any questions related to Kubespray, you can reference
to the code and documentation of Kubespay.

## Setup

### Install OS

You can install any OS supported by Kubespray on nodes, e.g. Debian 9, Ubuntu
18.04, CentOS 7, etc. But if you want to run workloads using NVIDIA GPU in your
cluster, please choose Ubuntu 18.04 or CentOS 7.

We recommend to install the same OS on all the nodes to simplify configuration
and upgrade.

During installation, please create a non-root user, which is used to login and
maintenace. Ensure the user can get root priviledge with sudo.

### Configure SSH

During installation, the control node controls installation on other nodes via
SSH. You have to configure SSH authentication between the control node and other
nodes, so that control node can SSH to other nodes without password. Please
reference to
[Ubuntu Documentation](https://help.ubuntu.com/lts/serverguide/openssh-server.html.en#openssh-keys)
to configure it. To ensure security, we recommend to disable root login.

### Configure password-less sudo

To automate the installation, you need to enable password-less sudo on all nodes
. For example in Ubuntu 18.04, run `sudo visudo` and find the following line in
the opened file:
```
%sudo   ALL=(ALL:ALL) ALL
```
change it into:
```
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
```
and save it.

### Configure Firewall

<!-- TODO(yfcheng)
Detailed instructions to setup firewall both before and after installation.
-->

Before installation, please disable firewall on all the nodes. It's dangerous to
configure the network remotely, please be careful.

We recommend to secure the network with firewall **after installation**. Block
income network connection from the outside, except SSH from specific subnet. But
you should **disable the firewall during installation**.

### Prepare the control node

During installation, Packages like `git`、`ansible`、`pip` should be available in
the control node. Please install them according to your distribution. If you are
using Ubuntu or Debian, you can install them via:
```shell
$ sudo apt install -y git ansible python-pip
```

On the control node, download the source code of Harpia and Kubespray:
```shell
$ git clone https://github.com/kubernetes-sigs/kubespray.git
$ (cd kubespray; git checkout 9e8e069)
$ git clone https://github.com/google/harpia.git
```

Then install the required packages of Kubespray:
```shell
$ cd kubespray
kubespray $ pip install --user -r requirements.txt
```

### Configure Kubespray

Copy the sample configuration directory of Harpia `setup/inventory/9e8e069` to
the `inventory/harpia` directory of Kubespray:
```shell
kubespray $ cp -rfp ../harpia/setup/inventory/9e8e069 inventory/harpia
```

Fill information of nodes into `inventory/harpia/hosts.ini`, including address,
name, role (whether it's a master node), etc. You can do it following comments
in that file, or auto-generated it with the following command:
```shell
kubespray $ declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
kubespray $ CONFIG_FILE=inventory/harpia/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```
Fill IP address of all the nodes inside the parenthese after `IPS` in the above
command.

Finally, please carefully check the files under `inventory/harpia/group_vars`,
and change options as you want.

Especially, You have to
[prepare Pod IP range and Service IP range](https://kubernetes.io/docs/setup/scratch/#network-connectivity)
for Kubernetes cluster. Those two IP ranges should not overlap with physical IP
range. You may also want to
[prepare a domain](https://kubernetes.io/zh/docs/concepts/services-networking/dns-pod-service/)
for Kubernetes cluster, which is used in domains of Services. Please change
`inventory/harpia/group_vars/k8s-cluster/k8s-cluster.yml`:
* `kube_service_addresses` into your Kubernetes Service IP range.
* `kube_pods_subnet` into your Kubernetes Pod IP range.
* `cluster_name` into your Kubernetes domain.

If you want to enable NVIDIA GPU support on one or more nodes, please uncomment
`nvidia_accelerator_enabled`, `nvidia_gpu_nodes`, `nvidia_driver_version`, and
`nvidia_gpu_flavor` in the file
`inventory/harpia/group_vars/k8s-cluster/k8s-cluster.yml`. And change them into
appropriate values. If you are using Ubuntu on GPU nodes, please also uncomment
`docker_storage_options` at the head of
`inventory/harpia/group_vars/all/docker.yml`.

### Create Kubernetes cluster

Kubernetes cluster will be installed automatically by Kubespray.

On the control node, please run:
```shell
kubespray $ ansible-playbook -i inventory/harpia/hosts.ini --become --become-user=root cluster.yml
```

Influenced by the performance of network and nodes, the installation process may
last tens of minutes or even more. Please be patient. The setup command is
idempotent, so if there are errors during installation, please check the error
message of Kubespray, fix it and re-run the command.

### Access the Kubernetes cluster

The installed Kubernetes cluster can be access by `kubectl` or Kubernetes
Dashboard.

Copy the `/etc/kubernetes/admin.conf` file in the first master node to the
`~/.kube/config` directory in the control node. Then execute `kubectl get cs` to
verify accessing it via `kubectl`, and check the status of the cluster. If
everything goes right, you will see output like:
```
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-1               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
```

If you want to access the cluster via Kubernetes Dashboard, you have to first
create a cluster admin user in Kubernetes. Inside source code of Harpia, install
`setup/configs/admin.yaml`:
```shell
harpia $ kubectl apply -f setup/configs/admin.yaml
```

Run the following command, and copy the value of `token` in the output. This is
your credential to Kubernets cluster, please keep it secure.
```shell
$ kubectl -n kube-system describe secret \
  $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

Finally, run `kubectl proxy` on the control node and open
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
with your browser. Choose "Token" and fill in the credential you have just
copied. You should be able to login Kubernetes Dashboard.
