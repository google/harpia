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

# Must be run with root access. Use sudo when needed.
# Requires /tmp/k8s-setup/binaries to have the deb packages to install.
# Requires /tmp/k8s-setup/configs/docker-daemon.json
# Optionally installs /tmp/k8s-setup/docker_images.tar if exists.

TMP_DIR="/tmp/k8s-setup"

# Setup iptables and only allow traffic from within the system.
# TODO(ditsing): how?

# Install all necessary packages.
bash ./install_debs.sh

# Update docker config.
mkdir -p /etc/docker
cp "$TMP_DIR/configs/docker-daemon.json" /etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker
## Load docker packages
if [[ -f "$TMP_DIR/docker_images.tar" ]]; then
  docker load --input "$TMP_DIR/docker_images.tar"
fi

# Disable swap for k8s.
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# TODO(ditsing): ssh?
# Setup ssh access, enable public key and disable password login.
## Restart ssh.

# Pull images with kubeadm and mark them as from k8s.gcr.io, for a smoother
# setup.
# Required both for master and worker nodes. Workers need docker image `pause`.
IMAGES=$(kubeadm config images pull --config "$TMP_DIR/configs/kubeadm-config.yaml" | sed -e 's/.* \([^ ]\+\)$/\1/')
for i in $IMAGES; do
  TAG=$(echo "$i" | sed -e 's/kunpengprod/k8s.gcr.io/')
  docker tag "$i" "$TAG"
done
