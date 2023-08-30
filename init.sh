#!/usr/bin/env bash

NAMESPACE="test"
STRIMZI_VERSION="0.36.0"

[[ "${BASH_SOURCE[0]}" -ef "$0" ]] && echo "Usage: source init.sh" && exit 1

kubectl-kafka() {
  kubectl get po kafka-tools &>/dev/null || kubectl run kafka-tools -q --restart="Never" \
    --image="apache/kafka:latest" -- sh -c "trap : TERM INT; sleep infinity & wait"
  kubectl wait --for=condition=ready po kafka-tools &>/dev/null
  kubectl exec kafka-tools -itq -- sh -c "/opt/kafka/$*"
}

kubectl delete ns "$NAMESPACE" target --wait &>/dev/null
kubectl wait --for=delete ns/"$NAMESPACE" --timeout=120s &>/dev/null
kubectl create ns "$NAMESPACE"
kubectl config set-context --current --namespace="$NAMESPACE" &>/dev/null
curl -sL "https://github.com/strimzi/strimzi-kafka-operator/releases/download/$STRIMZI_VERSION/strimzi-cluster-operator-$STRIMZI_VERSION.yaml" \
  | sed -E "s/namespace: .*/namespace: $NAMESPACE/g" | kubectl create -f - --dry-run=client -o yaml | kubectl replace --force -f - &>/dev/null
echo "Done"
