+++
author = "Michele Lacchia"
title = "A complete Kubernetes tutorial, part II: deploying an application"
tags = ["kubernetes", "containers"]
category = "posts"
date = "2019-11-13"
summary = "A complete Kubernetes tutorial series covering all the basics."
+++

## Preface
The goal of this tutorial series is to allow the reader to start deploying on
Kubernetes with a basic understanding of Kubernetes architectural principles.
If you don't know what Kubernetes is or how it works, I highly recommend
reading [part I](/post/kubernetes-tutorial/) of this series.

In this post, we dive into a practical example. We'll see many of the concepts
explained in the first part of the series. This is the structure of the series:

* Part I: [Kubernetes basic concepts](/post/kubernetes-tutorial/)
* Part II: A practical and realistic example (this post)
* Part III: Best practices (still WIP)

## Introduction
The application that we will deploy is a simple web application that, while
minimal, is supposed to mimic a real-world architecture. It exposes two
endpoints, `GET /users/:id` and `POST /users/:id`: the former returns the
numeric value associated to a user, if present in the database, and 0
otherwise; the second one increments the value associated to a user. There's an
additional endpoint, `GET /healthz`, which simply returns a check mark and it's
used to test the connectivity to the application.

For example, the following could be a valid HTTP session, assuming that our
application is running on localhost:1323 and that we have
[HTTPie](https://httpie.org/) installed (I prefer it over cURL):

```shell
# the GET method is the default one and can be omitted;
# localhost is also the default host
$ http :1323/users/249  # user 249 is not in the database, so the we get 0
0
$ http POST :1323/users/249  # we increment the value associated with user 249
1
$ http POST :1323/users/249
2
$ http POST :1323/users/249
3
$ http :1323/users/249
3
$ http :1323/users/32
0
```

We will not get into the details of how the Go application works, as that is
completely orthogonal to the deployment, thanks to containers.

The architecture of this web application is quite simple: an nginx instance
proxies all the traffic to a Go web server, which communicates with a Redis
instance to store and retrieve data.

<figure>
<img src="/static/images/Kubernetes tutorial - Architecture.png" alt="Architecture of the application we will deploy" />
<figcaption>
    <strong>Fig. 1</strong>&emsp;An HTTP client interacts with the nginx instance,
    which proxies all the traffic to the web application. We will also set up
    the Redis instance and the corresponding persistence volume to make sure
    our Redis data is not lost.
</figcaption>
</figure>

This application is of course a contrived example. In this case, an nginx
instance isn't even strictly needed. However, nginx instances (or anything
equivalent, for that matter) are frequently used to proxy the actual web
applications in real scenarios, so I chose to include it. nginx could also
serve static files, if your application needs them.

The code for this web application, as well as the Dockerfile's and the manifest
files are available at
[rubik/kubernetes-tutorial](https://github.com/rubik/kubernetes-tutorial).


## Provisioning a Kubernetes cluster
If you would like to follow along, and I highly recommend doing so, you need to
be able to connect to a Kubernetes cluster. The are two easy ways.

#### Google Kubernetes Engine (GKE)
The easiest way, which I recommend for this tutorial, is to create a brand new
project on [Google Cloud](https://cloud.google.com/) and enable GKE to
provision a new Kubernetes cluster. At the end of the tutorial, you can delete
the project and all its resources to avoid recurring charges. Note that unless
you are enjoying your free tier, you will nonetheless incur charges with this
method. On GKE, the master node is managed for free by Google Cloud, but you
will pay for the Compute instances you use, as well as for any cloud load
balancers you request.

However, if you follow the tutorial and you delete the project when you are
done, you should expect charges in the order of a few dollars at most. You can
even use Google Cloud's own [Pricing
calculator](https://cloud.google.com/products/calculator/) to estimate the
charges.

If you choose to do this, you will need to take the following steps to prepare
your environment:

1. install the [Google Cloud SDK](https://cloud.google.com/sdk/install);
2. install the kubectl tool with `gcloud components install kubectl`;
3. create a Kubernetes cluster from [the
console](https://console.cloud.google.com/kubernetes) --- note that it may take a
few minutes for your cluster to become ready and operational;
4. save the cluster credentials on your computer with `gcloud container
clusters get-credentials CLUSTER_NAME`, where `CLUSTER_NAME` is the name of the
cluster you have created in step 3.

You are now ready to follow the tutorial. At end, don't forget to clean up by
deleting your cluster, any resources associated to it (e.g. load balancers) and
your project (if you have created a brand new one for this tutorial).

#### Minikube
Alternatively, you can also run a single-node cluster on your local machine
with [Minikube](https://github.com/kubernetes/minikube). Not all features all
supported out-of-the-box --- e.g. to expose a load balancer you will need to use
the `minikube tunnel` command. However, this is a valid alternative if you
don't want to use GKE.

You will need to take the following steps to prepare your environment:

1. install `kubectl` --- [instructions
here](https://kubernetes.io/docs/tasks/tools/install-kubectl/);
2. install Minikube --- [instructions
here](https://kubernetes.io/docs/tasks/tools/install-minikube/);
3. run `minikube start` to create a local cluster.


## Deployments
We'll start by writing the manifest files for the nginx and Go instances. These
two components are both completely stateless: these instances don't need a
stable network identity or persistent storage. They could be scaled up and down
at any moment without issues.

For these reasons, the
[**Deployment**](/post/kubernetes-tutorial/#controller-objects) controller is
the right abstraction in this case. Let's create the manifest the nginx
instance:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - args: ['nginx', '-g', 'daemon off;']
        image: c1524db4f1/kubernetes-tutorial-frontend:v0.2.0
        imagePullPolicy: Always
        name: nginx
        ports:
        - containerPort: 80
      restartPolicy: Always
```

This manifest file instructs Kubernetes to create a Deployment called
`frontend`. Each Pod managed by the Deployment will be created according to the
spec template: it will be built from the image
`c1524db4f1/kubernetes-tutorial-frontend:v0.2.0` and will expose port 80.
We specified `replicas: 2` for redundancy and availability: our frontend
Deployment will manage two nginx instances. Additionally, we define the restart
policy as "Always". This ensures that the container will be restarted in all
cases (even if it exists with a success code). We want our nginx instance to be
always up, so that's the appropriate policy. Other possible values are
OnFailure and Never.

Observe that the `spec.selector` field is mandatory: the Deployment needs to
know which Pods to manage. In this case, it controls all the Pods with label
`app=web`. All the Pods created by this spec have that label, as defined by
`spec.template.metadata.labels`.

The actual application is packaged in the Docker image
[c1524db4f1/kubernetes-tutorial-frontend](https://hub.docker.com/repository/docker/c1524db4f1/kubernetes-tutorial-frontend),
which was created specifically for this tutorial. Similarly, the backend app's
image is
[c1524db4f1/kubernetes-tutorial-backend](https://hub.docker.com/repository/docker/c1524db4f1/kubernetes-tutorial-backend).

Let's submit this manifest file to Kubernetes. We do so by saving the manifest
file to `deploy/frontend/20-deployment.yaml` and running

```shell
$ kubectl apply -f deploy/frontend/20-deployment.yaml
```

We can check the status of this Deployment with

```shell
$ kubectl get deployments
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   2/2     2            2            4s
```

The API informs us that the Deployment `frontend` is up to date, available, and
its Pods are all ready. We can also query the state of all the Pods (by
default, this will only display Pods in the `default` namespace):

```shell
$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
frontend-557854f87f-924f8   1/1     Running   0           7s
frontend-557854f87f-fvmgb   1/1     Running   0           7s
```

These Pods have a special name because they were created by the Deployment
controller. Their status is Running, so all is fine. Other possible status
values are:

* Pending: if the configuration has been accepted by the Kubernetes API, but
  one or more containers have not been created; a Pod could remain in Pending
  state forever if it cannot be scheduled (e.g. there are no available nodes or
  ports) --- more details are found with the command `kubectl describe pod <pod
  name>`;
* Success: if all containers in the Pod have terminated successfully, and will
  not be restarted;
* Failure: if at least one container in the Pod has terminated in failure, i.e.
  it exited with a non-zero exit code or it was forcefully terminated by the
  system;
* Unknown: if the state of the Pod is not known to the control plane; this
  could indicate the presence of communication issues.

#### Deployment updates
Finally, let's consider Deployment updates. If we make changes to the manifest
file, we can push the update with `kubectl apply -f <manifest-file>`.
Kubernetes will compare the old version with the new one and, if it finds any
differences, it will take steps to reach the desired state.

If we update the image version, for example, the Deployment controller will
create a new set of Pods with the new container image, and will gradually scale
up the new replica set. At the same time, it will scale down the replica set
with the previous version. This update strategy is called **RollingUpdate**.
There are other strategies available. Notably, the **Recreate** one, which is
quite handy during development. It consists in terminating all the running
instances and then recreating them with the newer version.

While the **RollingUpdate** strategy can prevent downtime, if configured
appropriately, that's not possible with the **Recreate** one. Let's configure
our update to prevent downtime. We'll add the following configuration to the
`spec` object:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

With the above parameters, the frontend Deployment will create one additional
Pod during the update and it will ensure that no Pods are unavailable at any
time. Additional update strategies are discussed
[here](https://blog.container-solutions.com/kubernetes-deployment-strategies).


> **Heads up!** The pods in the old replica sets are terminated and the traffic
> switches to the new pods when they are ready. But how does Kubernetes know
> when the new pods are ready to accept traffic? It actually doesn't, and it
> will consider the new pods ready as soon as the container process starts. Of
> course, that is rarely the desired behavior, so we can instruct Kubernetes to
> poll the pods periodically in order to determine if they are ready or not,
> alive or not. That is accomplished by setting up health checks.


#### Final configuration
With those improvements, the configuration for our frontend Deployment looks
like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web
      service: nginx
  template:
    metadata:
      labels:
        app: web
        service: nginx
    spec:
      containers:
      - args: ['nginx', '-g', 'daemon off;']
        image: c1524db4f1/kubernetes-tutorial-frontend:v0.2.0
        imagePullPolicy: Always
        name: nginx
        ports:
        - containerPort: 80
      restartPolicy: Always
```

After submitting the manifest with

```shell
$ kubectl apply -f deploy/frontend/20-deployment.yaml
```

we see that the number of Pods immediately increases to three (due to
`maxSurge: 1`). When the new Pod is ready, Kubernetes starts terminating the
old Pods and creating new ones. This process happens gradually one by one,
because we specified `maxUnavailable: 0`, which forces Kubernetes to maintaing
two fully ready Pods at any time (as we set `replicas: 2`). Had we specified
`maxUnavailable: 1`, Kubernetes would have upgraded two Pods at a time.

For our application, we'll create a similar Deployment manifest. It is
essentially the same, so we will not discuss it in detail. We save the
following configuration in `deploy/backend/20-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web
      service: app
  template:
    metadata:
      labels:
        app: web
        service: app
    spec:
      containers:
      - args: ['/bin/app']
        image: c1524db4f1/kubernetes-tutorial-backend:v0.2.0
        imagePullPolicy: Always
        name: app
        ports:
        - containerPort: 1323
      restartPolicy: Always
```

This manifest is almost identical to the previous one, with the only
differences being the container image and command.

After deploying, this is the output of `kubectl get pods`:

```shell
NAME                        READY   STATUS    RESTARTS   AGE
backend-78d87dd74b-pk7tr    1/1     Running   0          14m
backend-78d87dd74b-wth2f    1/1     Running   0          14m
frontend-59f5cf4948-96drd   1/1     Running   0          23m
frontend-59f5cf4948-gcrll   1/1     Running   0          23m
```

We didn't deploy those Pods directly. Instead, they are managed by the
Deployment controllers. We can inspect the currently active deployments by
running `kubectl get deployments`:

```shell
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
frontend                    2/2     2            2           23m
backend                     2/2     2            2           14m
```

<figure>
<img src="/static/images/kubernetes-tutorial-ii-Architecture - 1.png" alt="Status of the cluster after the deployments" />
<figcaption>
    <strong>Fig. 2</strong>&emsp;This is how the cluster looks like at this
    point. We have deployed the frontend and backend components of our
    architecture, but they are currently doing nothing as there is no
    networking between them or the external world.
</figcaption>
</figure>

## Networking between Pods
We are now ready to set up the Services that will allow our Pods to
communicate. We will create a LoadBalancer Service for the nginx Pods, since
they need to be reached from outside the cluster, and a ClusterIP service for
the Go application. If you need to, you can refresh your knowledge about
Kubernetes services [here](/post/kubernetes-tutorial/#services).

This is the manifest that declares the LoadBalancer service for our nginx Pods:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  ports:
  - name: "80"
    port: 80
    targetPort: 80
  selector:
    app: web
    service: nginx
```

This manifest specifies that the Service is a LoadBalancer and that it needs to
forward traffic from port 80 (`port`), to port 80 (`targetPort`) of the
selected Pods. We select Pods that have the labels `app: web` and `service:
nginx`, which are the same ones we used in the nginx Deployment.

As before, we save this manifest to `deploy/frontend/30-service.yaml` and
submit it to the Kubernetes API with

```shell
$ kubectl apply -f deploy/frontend/30-service.yaml
```

As mentioned above, for the Go application we'll deploy a ClusterIP service.
That's because it's proxied by nginx, so all its traffic comes from inside the
cluster. The manifest file is quite simple like the previous one:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  type: ClusterIP
  ports:
  - name: "1323"
    port: 1323
    targetPort: 1323
  selector:
    app: web
    service: app
```

We save it in `deploy/backend/30-service.yaml` and deploy it:

```shell
$ kubectl apply -f deploy/backend/30-service.yaml
```

We can inspect the status of the running Services (again, in the `default`
namespace, which is the one we're working with) with the following command:

```shell
$ kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
app          ClusterIP      10.97.226.151   <none>        1323/TCP       1m10s
nginx        LoadBalancer   10.97.210.57    <pending>     80:31494/TCP   1m14
```

As we can see, the ClusterIP has no external IP, while the LoadBalancer shows
"pending". That's because my cluster is local and runs through Minikube. If we
were communicating with a cloud Kubernetes installation (e.g. GKE), the load
balancer would be provisioned automatically and the external IP would appear
after a few seconds. In this case, howerver, we need to run `minikube tunnel`
in a separate shell in order to obtain an external IP. After launching that
command separately, we can check the status of our Services again:

```shell
$ kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
app          ClusterIP      10.97.226.151   <none>         1323/TCP       1m24s
nginx        LoadBalancer   10.97.210.57    10.97.210.57   80:31494/TCP   1m28s
```

We can now test the connectivity to our application:

```shell
$  http 10.97.210.57/healthz
HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 3
Content-Type: text/plain; charset=UTF-8
Date: Sun, 24 Nov 2019 18:02:31 GMT
Server: nginx/1.17.5

✓
```

This response is generated by our Go application, which in turn is proxied by
the nginx instances. This is a good point to learn about a new command:
`kubectl logs`. It allows us to read the logs produced by our Pods:

```shell
$ kubectl logs frontend-99d9cfbc9-dbbdj
192.168.99.1 - - [24/Nov/2019:18:02:31 +0000] "GET /healthz HTTP/1.1" 200 3 "-" "HTTPie/1.0.3"
$ kubectl logs frontend-99d9cfbc9-dknvq
$
```

As we can see, our request was routed through the Pod
`frontend-99d9cfbc9-dbbdj`, while the other Pod hasn't served any traffic yet.
We can fetch the output of our backend pods too, although the Go application is
configured not to log accesses, so we only see the program start output:

```shell
$ kubectl logs backend-78d87dd74b-pk7tr

   ____    __
  / __/___/ /  ___
 / _// __/ _ \/ _ \
/___/\__/_//_/\___/ v3.3.10-dev
High performance, minimalist Go web framework
https://echo.labstack.com
____________________________________O/_______
                                    O\
⇨ http server started on [::]:1323
```

<figure>
<img src="/static/images/kubernetes-tutorial-ii-Architecture - 2.png" alt="Status of the cluster after the deployments" />
<figcaption>
    <strong>Fig. 3</strong>&emsp;The cluster can now communicate with the
    external world and the pods are communicating between them. It's now a
    functional cluster. The user endpoints are not working yet, as they depend
    on Redis.
</figcaption>
</figure>


## Adding persistence
The cluster is now functional, but to make the tutorial more realistic we are
going to add persistence through Redis. That will enable us to use the users
endpoints which we described at the beginning of the post.

Before deploying the Redis container, we will take care of storage. In
Kubernetes, storage resources are represented by **PersistentVolume** objects.
These resources are consumed by **PersistentVolumeClaim** objects, just like
Pods consume node compute resources. Therefore, we start by deploying the
following PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    service: redis
  name: redis-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

In the above specification, there are two important configuration options.

The **access mode** describes how the volume is mounted; the possible values
are:

1. `ReadWriteOnce` &ndash; the volume can be mounted as read-write by a
 single node
2. `ReadOnlyMany` &ndash; the volume can be mounted as read-only by many
 nodes
3. `ReadWriteMany` &ndash; the volume can be mounted as read-write by many
 nodes

Not every storage provider supports all the access modes. E.g. an
[`awsElasticBlockStore`](https://kubernetes.io/docs/concepts/storage/volumes/#awselasticblockstore)
volume only supports `ReadWriteOnce`, whereas a
[`gcePersistentDisk`](https://kubernetes.io/docs/concepts/storage/volumes/#gcepersistentdisk)
supports both `ReadWriteOnce` and `ReadOnlyMany`. Importantly, a volume can
only be mounted using one access mode at a time, even if it supports many.

The **resources request** specifies how much storage we request &mdash; we ask
for 10GB in this case. If in the future we need more storage, we can request a
larger volume for a PersistentVolumeClaim by editing the configuration and
applying it again. Kubernetes will resize the existing volume instead of
creating a new PersistentVolume.  Currently, one can only resize volumes
containing a filesystem if the filesystem is XFS, ext3 or ext4.

We save the PersistentVolumeClaim configuration in
`deploy/redis/10-persistentvolumeclaim.yaml` and we apply it with the usual
command:

```shell
$ kubectl apply -f deploy/redis/10-persistentvolumeclaim.yaml
```

We can verify that the volume was provisioned by inspecting the volume claims
and the volumes:

```shell
$ kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
redis-data   Bound    pvc-75fc6d82-7b14-40b5-beb3-e50c6015323a   10Gi       RWO            standard       30s
```

The `STATUS` column indicates that the claim is bound to a volume, which is
shown in the `VOLUME` column. We can request information about that particular
volume as follows:

```shell
$ kubectl get pv pvc-75fc6d82-7b14-40b5-beb3-e50c6015323a
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   REASON   AGE
pvc-75fc6d82-7b14-40b5-beb3-e50c6015323a   10Gi       RWO            Delete           Bound    default/redis-data   standard
```

Note that the `RECLAIM POLICY` is set to `Delete`. That means that if the
PersistentVolumeClaim is deleted, Kubernetes will remove both the Volume it is
bound to, as well as the associated storage asset. The other option is
`Retain`. With this mode, the PersistentVolume object will not be deleted, but
the volume will be considered "released". The cluster administrator will need
to perform [manual
reclamation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#retain)
of the resource.

We are finally ready to deploy Redis with persistence enabled. Since our Redis
instance needs to save data to persistence storage, it's a stateful
application. The correct abstraction for this kind of applications is the
**StatefulSet** controller. Like a Deployment controller, it takes care of
manageing Pods in a ReplicaSet. However, Pods controlled by a StatefulSet are
not interchangeable: each Pod has a unique identifier that is maintained no
matter where it is scheduled.

## Recap

## What we didn't cover
* If you don't want to use a managed solution like Google Kubernetes Engine
  (GKE) or Amazon Elastic Kubernetes Service (EKS), you will have to set up
  Kubernetes yourself on VMs or bare metal, and that is not simple.  If you are
  interested, I recommend you read the
  [`kubeadm`](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
  documentation or the excellent [Kubernetes The Hard
  Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) series by
  Kelsey Hightower.
