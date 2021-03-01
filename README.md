# a8s Demo

**WIP**

# IMPORTANT

Please read the following information so we do not mess up the a9s PaaS system.

- When working with a9s Kubernetes on a9s PaaS, we need to ensure no `volumes`
are left behind. Therefore, ensure `kubectl get pvc` and `kubectl get sc` are
empty.

# Demo Script

## Setup Private Registry

FIXME: Does not work yet. a9s Kubernetes cannot use a9s Harbor's private projects.

```shell
export CF_HARBOR_INSTANCE_NAME=a8s-images-dev
export CF_HARBOR_INSTANCE_SERVICE_KEY=demo

cf service-key ${CF_HARBOR_INSTANCE_NAME} ${CF_HARBOR_INSTANCE_SERVICE_KEY}
```

```shell
export DOCKER_SERVER="service-key-dashboard_url-entry" # without https
export DOCKER_USERNAME="service-key-username-"
export DOCKER_PASSWORD="service-key-password-entry"
export DOCKER_EMAIL=${DOCKER_USERNAME}@anynines.com

kubectl create secret docker-registry a8s-registry --docker-server=${DOCKER_SERVER} --docker-username=${DOCKER_USERNAME} --docker-password=${DOCKER_PASSWORD} --docker-email=${DOCKER_USERNAME}@anynines.com
```

## Install a8s Operators

```shell
kubectl apply -f deployment/cluster-operators.yaml
kubectl get pods -w --namespace postgresql-system # 2/2 should appear after some time
```

The a8s Backup Manager components require AWS credentials.

Insert AWS access credentials into the following files:
- `./access-key-id`
- `./secret-access-key`

Install a8s Backup Manager components:

```shell
kubectl create secret generic aws-credentials \
      --from-file=./access-key-id \
        --from-file=./secret-access-key
```

```shell
kubectl apply -f deployment/a8s-backup-manager.yaml
kubectl get pods --namespace a8s-system # 2/2 should be ready after some time
```

Then we need to apply some RBAC files so the current binding user can work with
the new custom resourecs:

```shell
kubectl apply -f rbac/a8s-instance-user-role.yaml

vim rbac/a8s-instance-user-binding.yaml # and set your binding user
kubectl apply -f rbac/a8s-instance-user-binding.yaml

kubectl get PostgreSQL # should work  without throwing a permission error
```


## Instance Creation, Usage and Deletion

```shell
cat deployment/instance.yaml

kubectl apply -f deployment/instance.yaml

kubectl get pods -w

kubectl get PostgreSQL
```

Next we want to deploy a PostgreSQL demo app (`a9s-postgresql-app`) that will
use the new PostgreSQL instance to store data.

```shell
cat deployment/demo-app-deployment.yaml
```

First we need to get the credentials to connect to the PostgreSQL database.

```
kubectl get secret postgres.credentials.demo-pg-cluster -o 'jsonpath={.data.password}' |  base64 -d
```

Then we set the credentials for the demo app.

```shell
vim deployment/demo-app-secret.yaml # use base64 encoded password
kubectl apply -f deployment/demo-app-secret.yaml
```

Deploy the app:

```shell
kubectl apply -f deployment/demo-app-deployment.yaml
kubectl apply -f deployment/demo-app-service.yaml

kubectl get pods -w
```

Expose the app to the outside world:

```shell
vim deployment/demo-app-ingress.yaml # TODO: change values
kubectl apply -f deployment/demo-app-ingress.yaml
```

```shell
open https://demo-apps-DASHBOARD_URL
```

Create a new blog post entry.

Next we'll create a backup of the current database:

```shell
cat deployment/backup.yaml

kubectl apply -f deployment/backup.yaml
```

In order to test restore, we'll first create another blog entry and then
restore to the latest backup.

```shell
kubectl apply -f deployment/recovery.yaml
```

Delete service instance:
```shell
kubectl delete -f deployment/instance.yaml

kubectl get pods -w

kubectl get PostgreSQL
```

# Requirements

In order to demonstrate the a9s Data Services product , we need the following
things:
- Kubernetes to demonstrate the product on
- this repo that contains some yaml manifests

The images for the demo are currently stored on a temporary a9s Harbor service
instance on a9s PaaS. This will be changed in the future to provide a more
reliable solution.

## Kubernetes

## Setup a9s Kubernetes

Login to a9s PaaS to the appropriate CF org+space.

Create an a9s Kubernetes instance:

```shell
export INSTANCE_ID=1
export INSTANCE_PREFIX=a8s-demo

export INSTANCE_NAME=${INSTANCE_PREFIX}-${INSTANCE_ID}

export PLAN_NAME=kubernetes-1-master-1-worker-small

cf cs a9s-kubernetes ${PLAN_NAME} ${INSTANCE_NAME}

cf csk ${INSTANCE_NAME} demo
cf service-key ${INSTANCE_NAME} demo
```

Create kubectl config to access the new a8s Kubernetes instance:

```shell
export KUBECONFIG=kube.config.${INSTANCE_NAME}

echo "paste here the copied kubeconfig" > ${KUBECONFIG}

kubectl get pods # should work
```

Setup storage for persistent volumes:
```shell
kubectl apply -f deployment/a9s-kubernetes-storageclass.yaml
kubectl describe StorageClasses
```

## Images

There is an a9s Harbor instance on a9s PaaS.

The CF service key `demo` has read-only access to the project `demo`
on a9s PaaS.

```
# org anynines / space dsteam as concourse...
cf service a8s-images-dev
cf service-key a8s-images-dev demo
```


### Push Images Step (Optional)

This step shows how to use a9s Harbor to host (dev) images in the Harbor
registry.


```shell
export VERSION=0.2.0
export PROJECT=demo
export REGISTRY=c4aeb71c-dd2a-4e6e-9385-1c3bb839307c.de.a9s.eu # a9s Harbor dashboard_url

docker login ${REGISTRY} # with a CF service key that has write access to the project

docker tag controller ${REGISTRY}/${PROJECT}/postgresql-controller:${VERSION}
docker tag backup-agent ${REGISTRY}/${PROJECT}/backup-agent:${VERSION}

docker push ${REGISTRY}/${PROJECT}/postgresql-controller:${VERSION}
docker push ${REGISTRY}/${PROJECT}/backup-agent:${VERSION}
```

# TODOs

- [x] demo app (a9s-postgresql-app)
- [ ] get sales engineer involved
- [ ] hosted registry solution so the location of the image stays the same ->
  a9s Harbor as per a8s meeting 2021-02-24
- [ ] automate some many manual steps, maybe via `kustomize` run!?
- [x] a8s Backup Manager integration
- [ ] service bindings
- [ ] What is the future product name?
- [ ] master switchover
- [ ] setup a demo user on a9s PaaS? -> sales engineer
- [ ] step that describes 1password credentials for org/space on a9s PaaS
