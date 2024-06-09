#!/bin/bash

# a9s create cluster a8s --yes
kubectl create namespace demo
sleep 1
a9s create pg instance --name clustered --replicas 3 -n demo --yes
a9s pg apply --file $WS/postgres/a9s-postgresql-app-demo-data/demo_data.sql -i clustered -n demo --yes
a9s pg apply -i clustered -n demo --sql "select count(*) from posts" --yes
a9s create pg backup --name clustered-bu-1 -i clustered -n demo --yes
a9s create pg servicebinding --name sb-sample -n demo -i clustered --yes

kubectl apply -k $(a9s cluster pwd)/a8s-demo/demo-app -n demo

sleep 20
a9s pg apply -i clustered -n demo --sql "delete from posts" --yes
a9s pg apply -i clustered -n demo --sql "select count(*) from posts" --yes
sleep 2
a9s create pg restore -n demo -i clustered -b clustered-bu-1 --name clustered-re-1 --yes
sleep 20
a9s pg apply -i clustered -n demo --sql "select count(*) from posts" --yes 