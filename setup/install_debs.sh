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

KUBE_VERSION="1.11.3"
DOCKER_VERSION="18.06"

# Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
## Download GPG key.
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg | apt-key add -

## Add docker apt repository.
add-apt-repository \
    "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
## Install docker
apt-get update && apt-get install -y docker-ce="$(apt-cache madison docker-ce | grep ${DOCKER_VERSION} | head -1 | cut -d ' ' -f 4)"
apt-mark hold docker-ce

# K8s
apt-get install -y apt-transport-https curl
## Download GPG key.
curl -fsSL https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
## Add k8s apt repository.
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update && apt-get install -y kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubelet=${KUBE_VERSION}-00
apt-mark hold kubeadm kubectl kubelet
