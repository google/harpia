#!/bin/bash
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
set -e

TMP_DIR="/tmp/k8s-setup/"

# Test CephFS
kubectl apply -f "${TMP_DIR}/verification/configs/storage/cephfs-volume.yaml"
kubectl wait --for=condition=available deployment cephfs-volume

pods=($(kubectl get pod -l app=cephfs-volume -o custom-columns=:metadata.name --no-headers))
pod_a="${pods[0]}"
pod_b="${pods[1]}"

# Write a file into CephFS inside Pod A, and read it out from Pod B.
kubectl exec "${pod_a}" -- /bin/sh -c "echo 'hello world' > /mnt/cephfs/hello.txt"
cephfs_text="$(kubectl exec "${pod_b}" -- /bin/sh -c "cat /mnt/cephfs/hello.txt")"
if [[ "${cephfs_text}" == "hello world" ]]; then
  echo "CephFS test passed."
else
  echo "CephFS test failed. Please check your setup."
fi
kubectl exec "${pod_a}" -- /bin/rm /mnt/cephfs/hello.txt

kubectl delete -f "${TMP_DIR}/verification/configs/storage/cephfs-volume.yaml"

# Test RBD
kubectl apply -f "${TMP_DIR}/verification/configs/storage/rbd-volume.yaml"
kubectl wait --for=condition=available deployment rbd-volume

# Write a file into RBD and read it out.
pod=$(kubectl get pod -l app=rbd-volume -o custom-columns=:metadata.name --no-headers)
kubectl exec "${pod}" -- /bin/sh -c "echo 'hello world' > /mnt/rbd/hello.txt"
rbd_text="$(kubectl exec "${pod}" -- /bin/sh -c "cat /mnt/rbd/hello.txt")"
if [[ "${rbd_text}" == "hello world" ]]; then
  echo "RBD test passed."
else
  echo "RBD test failed. Please check your setup."
fi

kubectl delete -f "${TMP_DIR}/verification/configs/storage/rbd-volume.yaml"
