#!/bin/bash -eu
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Setup a K8s master node. This script should be run after the machine is
# properly setup.
#
# See also machine_init.sh .

TMP_DIR="/tmp/k8s-setup"

# Initialize master from kubeadm configuration
kubeadm init --config $TMP_DIR/configs/kubeadm-config.yaml

# Config kubectl
mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Install Calico network layer.
kubectl apply -f $TMP_DIR/configs/calico.yaml --kubeconfig="/etc/kubernetes/admin.conf"
kubectl apply -f $TMP_DIR/calico/rbac-kdd.yaml --kubeconfig="/etc/kubernetes/admin.conf"

# Start a nginx ingress controller.
kubectl apply -f $TMP_DIR/configs/ingress-nginx-controller.yaml --kubeconfig="/etc/kubernetes/admin.conf"

# Setup Ceph with rook
# Before running those command, make sure the storage device configuration in rook-ceph-cluster.yaml is correct.
kubectl create -f $TMP_DIR/configs/storage/rook-ceph-operator.yaml --kubeconfig="/etc/kubernetes/admin.conf"
kubectl create -f $TMP_DIR/configs/storage/rook-ceph-cluster.yaml --kubeconfig="/etc/kubernetes/admin.conf"
kubectl create -f $TMP_DIR/configs/storage/rook-ceph-rbd.yaml --kubeconfig="/etc/kubernetes/admin.conf"
kubectl create -f $TMP_DIR/configs/storage/rook-ceph-filesystem.yaml --kubeconfig="/etc/kubernetes/admin.conf"
