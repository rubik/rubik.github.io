+++
author = "Michele Lacchia"
title = "A complete Kubernetes tutorial, part III: best practices"
tags = ["kubernetes", "containers"]
category = "posts"
date = "2020-05-19"
summary = "A complete Kubernetes tutorial series covering all the basics."
draft = true
+++


#### Health checks
Note that Kubernetes reports that our Pods are fully ready: `1/1` means that one
container (out of a total of one) in each Pod is ready. But how does Kubernetes
know when the nginx container is ready to accept requests? By default,
Kubernetes marks a Pod as ready and begins to send traffic when all its
containers start, and restarts the containers when they crash. While this can
be acceptable for some simpler deployments, a more robust approach is necessary
for production deployments.

For example, container might need some warm up time before it gets to an
operational state. This could mean some requests are dropped if Kubernetes
considers the container ready when it's not. To remedy, we can configure
readiness and liveness probes.

* **Readiness** probes are designed to let Kubernetes know when a Pod is ready
  to accept traffic. A common misconception is that readiness probes are only
  active during startup. This is not true: Kubernetes keeps testing for
  readiness during the whole lifetime of the Pod, and pauses and resumes
  routing to the Pod according to the readiness probe response.
* **Liveness** probes indicate wheter a container is alive or not: if it's not
  it will be restarted by Kubernetes. This probe can be used to detect
  deadlocks or other broken states that don't necessarily result in a crash.

There are three types of probes: HTTP checks, TCP checks, and checks performed
by running commands inside the container. For our nginx container, we'll use
the second one. This is accomplished by adding the following configuration in
the `spec.template.spec.containers.0` object of our manifest:

```yaml
readinessProbe:
  tcpSocket:
    port. 80
  periodSeconds: 2
livenessProbe:
  tcpSocket:
    port: 80
  initialDelaySeconds: 20
  periodSeconds: 30
```

We configure the same health check in both cases, with a different frequency.
If the container is unresponsive for a longer period of time, it will be
restarted. More details on the probe types and all the options are found
[here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).
