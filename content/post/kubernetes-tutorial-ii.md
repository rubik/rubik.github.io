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
otherwise; the second one increments the value associated to a user.

For example, the following could be a valid HTTP session, assuming that our
application is running on localhost:1323 and that we have
[HTTPie](https://httpie.org/) installed:

```shell
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

(The GET method is the default one and can be omitted; localhost is also the
default host.)

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
applications in real scenarios, so I chose to include it. E.g. nginx could also
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
done, you should expect charges in the order of a few dollars. You can even use
Google Cloud's own [Pricing
calculator](https://cloud.google.com/products/calculator/) to estimate the
charges.

If you choose to do this, you will need to take the following steps to prepare
your environment:

1) install the [Google Cloud SDK](https://cloud.google.com/sdk/install);

2) install the kubectl tool with `gcloud components install kubectl`;

3) create a Kubernetes cluster from [the
console](https://console.cloud.google.com/kubernetes) --- note that it may take a
few minutes for your cluster to become ready and operational;

4) save the cluster credentials on your computer with `gcloud container
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

1) install `kubectl` --- [instructions
here](https://kubernetes.io/docs/tasks/tools/install-kubectl/);

2) install Minikube --- [instructions
here](https://kubernetes.io/docs/tasks/tools/install-minikube/);

3) run `minikube start` to create a local cluster.


## Deployments
We'll start by writing the manifest files for the nginx and Go instances. These
two components are both completely stateless: these instances don't need a
stable network identity or persistent storage. They could be scaled up and down
at any moment without issues.

For these reasons, the **Deployment** controller is the right abstraction in
this case. Here is the manifest file for the nginx instance:
