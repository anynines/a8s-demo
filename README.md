# a8s Demo

This repo is **WIP**.
The goal is to provide instructions to demo the new a8s product in the future.

# IMPORTANT

Please read the following information so we do not mess up the a9s PaaS system.

- When working with a9s Kubernetes on a9s PaaS, we need to ensure no `volumes`
are left behind. Therefore, ensure `kubectl get pvc` and `kubectl get sc` are
empty.

# Demo Script

## Setup Private Registry

TODO: a9s Kubernetes can use a9s Harbor's private projects. But the current
demo does use a public project.

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
kubectl apply --filename deployment/cluster-operators.yaml
kubectl get pods --watch --namespace postgresql-system # 2/2 should appear after some time
# TODO: we should provide commands how to wait till the system settles down
# after installation.
```

Next we want to install a8s Backup Manager to backup and restore later on in
the demo the a8s data service instance.

The a8s Backup Manager components require AWS credentials to manage
backup files on S3.

FIXME: store them in 1password somewhere? Discuss with sales engineer
how approach certain things.
For the time being, you need an AWS access key id and secret access key for
the bucket `a8s-postgresql` in the region `eu-central-1` with read-write
permissions.

Insert AWS access credentials into the following files:
- `./access-key-id`
- `./secret-access-key`

**WATCH OUT** to not commit those files.

```shell
kubectl create secret generic aws-credentials \
      --from-file=./access-key-id \
        --from-file=./secret-access-key
```

Install a8s Backup Manager components:
```shell
kubectl apply --filename deployment/a8s-backup-manager.yaml
kubectl get pods --watch --namespace a8s-system # 2/2 should be ready after some time
# TODO: we should provide commands how to wait till the system settles down
# after installation
```

Next, we need to install the service binding controller. Run the following commands:

```shell
kubectl apply --filename deployment/a8s-service-binding-controller.yaml # deploy the service binding controller.
kubectl get pods --watch --namespace a8s-system --selector service-binding-controller # observe the deployment to see when it's done.
```

After the last command, wait until the output shows that 2/2 containers are up and running:

```shell
NAME                                                  READY   STATUS    RESTARTS   AGE
service-binding-controller-manager-594d7fbf68-vwwx5   2/2     Running   0          30s
```

Finally, we need to apply some RBAC files so the current binding user can work with
the new custom resources:

```shell
kubectl apply --filename rbac/a8s-instance-user-role.yaml

vim rbac/a8s-instance-user-binding.yaml # set your binding user from `cf service-key ${INSTANCE_NAME} demo`

kubectl apply --filename rbac/a8s-instance-user-binding.yaml

kubectl get PostgreSQL # should work  without throwing a permission error
# the above cmd is optional to see we have access on that particular Kubernetes
# provider to the custom resource PostgreSQL
```


## Instance Creation, Usage and Deletion

Let's spawn up a new a8s data service instance:

```shell
cat deployment/instance.yaml

kubectl apply --filename deployment/instance.yaml

kubectl get pods --watch
kubectl get PostgreSQL
# TODO: we should probably provide commands/exaplanation here what to expect
# after we spawn up a new instance
```

Next we want to deploy a PostgreSQL demo app (`a9s-postgresql-app`) that will
use the new PostgreSQL instance to store data.

```shell
cat deployment/demo-app-deployment.yaml
```

First, we need to create a service binding resource that will configure a user for the demo app in
the PostgreSQL database and store the credentials for that user in a Kubernetes API secret.

```shell
cat deployment/service-binding.yaml # show the service binding manifest and explain it
kubectl apply --filename deployment/service-binding.yaml # create the service binding manifest
kubectl get sb --output yaml --watch # check whether the service binding has been successfully created; "sb" is shorthand for "servicebinding"
```

The last command outputs the whole YAML for the service binding, which is very verbose. You should
just comment on the status fields of the service bindings, which should look like this:

```shell
... other fields ...

status:
  implemented: true
  instanceUID: 2f4cee2d-d098-4c37-9f75-2a279079728b
  secret:
    name: sb-sample-service-binding
    namespace: default

... other fields ...
```

If the service binding was successfully configured, you should see `status.implemented: true`.

We need also need to create a database demo on our own for the demo app:

```shell
kubectl exec demo-pg-cluster-0 --container postgres -- "psql" "-U" "postgres" "-c" "CREATE DATABASE demo;"
```

Finally, we can deploy the app:

```shell
kubectl apply --filename deployment/demo-app-deployment.yaml
kubectl apply --filename deployment/demo-app-service.yaml

kubectl get pods --watch
# TODO: we should provide commands to wait for the demo app
```

Expose the app to the outside world:

```shell
vim deployment/demo-app-ingress.yaml
# change DASHBOARD_URL placeholder to the url part after `https://dashboard-apps`
# from `dashboard_url`'s property in `cf service-key ${INSTANCE_NAME} demo`.

kubectl apply --filename deployment/demo-app-ingress.yaml
```

```shell
open https://demo-apps-DASHBOARD_URL
```

Create a new blog post entry.

Next we'll create a backup of the current database:

```shell
cat deployment/backup.yaml

kubectl apply --filename deployment/backup.yaml
```

In order to test restore, we'll first create another blog entry and then
restore to the latest backup.

```shell
kubectl apply --filename deployment/recovery.yaml
```

Delete service instance:
```shell
kubectl delete --filename deployment/instance.yaml

kubectl get pods --watch
kubectl get PostgreSQL
# TODO: explanation what to expect here/what to wait for
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
kubectl apply --filename deployment/a9s-kubernetes-storageclass.yaml
kubectl describe StorageClasses
```

## Images

This step will be obsolete once the a8s team has a production ready private
registry.

Currently, there is an a9s Harbor instance on a9s PaaS.

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
- [ ] use a9s Harbor private registry
- [ ] hosted registry solution so the location of the image stays the same ->
  a9s Harbor as per a8s meeting 2021-02-24
- [ ] automate some many manual steps, maybe via `kustomize` run!?
- [x] a8s Backup Manager integration
- [x] service bindings
- [ ] What is the future product name?
- [ ] master switchover
- [ ] setup a demo user on a9s PaaS? -> sales engineer
- [ ] step that describes 1password credentials for org/space on a9s PaaS
