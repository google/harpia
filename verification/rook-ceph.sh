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

TMP_DIR="/tmp/k8s-setup/"

first_pod_with_label() {
  kubectl get pod -l "$1" -o custom-columns=:metadata.name --no-headers | head -1
}

# Write a file into Cephfs.
CEPHFS_CONFIG="${TMP_DIR}/verification/configs/storage/rook-ceph-filesystem-flex-volume.yaml"
kubectl create -f "${CEPHFS_CONFIG}"
kubectl wait --for=condition=Ready -l "app=rook-ceph-filesystem" pod
#   Write the file via one pod.
kubectl exec "$(first_pod_with_label "app=rook-ceph-filesystem")" -- bash -c 'echo hello world > /mnt/cephfs/hello.txt'
kubectl delete -f "${CEPHFS_CONFIG}"
kubectl wait --for=delete -l "app=rook-ceph-filesystem" pod --timeout=120s

kubectl create -f "${CEPHFS_CONFIG}"
kubectl wait --for=condition=Ready -l "app=rook-ceph-filesystem" pod
#   Read via a different pod.
cephfs_text="$(kubectl exec "$(first_pod_with_label "app=rook-ceph-filesystem")" -- cat /mnt/cephfs/hello.txt)"
if [[ "${cephfs_text}" == "hello world" ]]; then
  echo "Cephfs test passed."
else
  echo "Cephfs test failed. please check your setup."
fi
kubectl delete -f "${CEPHFS_CONFIG}"

# Starting a MySQL instance to make sure that RBD works.
RBD_CONFIG="${TMP_DIR}/verification/configs/storage/rook-ceph-rbd-mysql.yaml"
kubectl apply -f "${RBD_CONFIG}"
kubectl wait --for=condition=Ready -l "app=rook-ceph-rbd" pod --timeout=60s
mysql_text="$(kubectl exec "$(first_pod_with_label "app=rook-ceph-rbd")" -i -- mysql -N -u root -ptest-instance-please-delete 2> /dev/null <<- EOM
  CREATE DATABASE menagerie;
  USE menagerie;
  CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);
  INSERT INTO pet VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);
  SELECT name FROM pet;
  DROP DATABASE menagerie;
EOM
)"
if [[ "${mysql_text}" == "Puffball" ]]; then
  echo "RBD test passed."
else
  echo "RBD test with mysql failed, please check your setup."
fi
kubectl delete -f "${RBD_CONFIG}"
