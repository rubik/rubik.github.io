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

The code for this web application, as well as the Dockerfile's and the manifest
files are available at
[rubik/kubernetes-tutorial](https://github.com/rubik/kubernetes-tutorial).


## Provisioning a Kubernetes cluster
If you would like to follow along, and I highly recommend doing so, you need to
be able to connect to a Kubernetes cluster. The are two easy ways.

#### Google Kubernetes Engine (GKE)
You can create a brand new project on [Google
Cloud](https://cloud.google.com/), enable GKE and Container Registry and
provision a new Kubernetes cluster.


## Deployments
We'll start by writing the manifest files for the nginx and Go instances. These
two components are both completely stateless: these instances don't need a
stable network identity or persistent storage. They could be scaled up and down
at any moment without issues.

For these reasons, the **Deployment** controller is the right abstraction in
this case. Here is the manifest file for the nginx instance:
