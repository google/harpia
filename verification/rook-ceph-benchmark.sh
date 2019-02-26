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

kubectl apply -f "${TMP_DIR}/verification/configs/storage/fio-config.yaml"

# Benchmark RBD.
kubectl apply -f "${TMP_DIR}/verification/configs/storage/rbd-fio.yaml"
echo "Benchmarking RBD..."
kubectl wait --for=condition=complete --timeout=20m job/rbd-fio
kubectl logs -f job/rbd-fio
kubectl delete -f "${TMP_DIR}/verification/configs/storage/rbd-fio.yaml"

# Benchmark CephFS.
kubectl apply -f "${TMP_DIR}/verification/configs/storage/cephfs-fio.yaml"
echo "Benchmarking CephFS..."
kubectl wait --for=condition=complete --timeout=20m job/cephfs-fio
kubectl logs -f job/cephfs-fio
kubectl delete -f "${TMP_DIR}/verification/configs/storage/cephfs-fio.yaml"

kubectl delete -f "${TMP_DIR}/verification/configs/storage/fio-config.yaml"
