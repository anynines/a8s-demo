#!/bin/bash


echo "Creating dummy service in consumer cluster"
kubectl apply --context kind-klutch-consumer -f 2-service.yaml

namespace=$(kubectl get ns --context kind-klutch-management --no-headers -o custom-columns=":metadata.name" | grep -e "kube-bind-[[:alnum:]]\{5\}-default")
echo "Briding management cluster network from namespace ${namespace}"
kubectl port-forward --context kind-klutch-management --namespace ${namespace} service/example-pg-instance-master 5432
