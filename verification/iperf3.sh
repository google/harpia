#!/bin/bash
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

TMP_DIR="/tmp/k8s-setup"

# Deploy two iperf3 server pods.
kubectl apply -f "${TMP_DIR}/verification/configs/network/iperf3.yaml"
kubectl wait --for=condition=available deployment iperf3

# Test from the first pod to the second.
pods=($(kubectl get pod -l app=iperf3 -o custom-columns=:metadata.name --no-headers))
src_pod="${pods[1]}"
dst_pod="${pods[2]}"
dst_ip="$(kubectl get pod ${dst_pod} -o custom-columns=:status.podIP --no-headers)"
kubectl exec "${src_pod}" -- iperf3 -c "${dst_ip}"

# Remove the test pods.
kubectl delete -f "${TMP_DIR}/verification/configs/network/iperf3.yaml"
