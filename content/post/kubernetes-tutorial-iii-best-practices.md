+++
author = "Michele Lacchia"
title = "A complete Kubernetes tutorial, part III: best practices"
tags = ["kubernetes", "containers"]
category = "posts"
date = "2020-05-01"
summary = "A complete Kubernetes tutorial series covering all the basics."
+++

## Preface
The goal of this tutorial series is to allow the reader to start deploying on
Kubernetes with a basic understanding of Kubernetes architectural principles.
If you don't know what Kubernetes is or how it works, I highly recommend
reading [part I](/post/kubernetes-tutorial/) of this series. [Part
II](/post/kubernetes-tutorial-ii-deploying-an-app/) walks you through a sample
deployment by explaining the most important steps.

In this post, we list a few best practices to follow when managing a Kubernetes
cluster. I believe it's important to follow best practices right away when one
starts learning a new technology. This is the last post in this tutorial
series. The other posts are listed below:

* Part I: [Kubernetes basic concepts](/post/kubernetes-tutorial/)
* Part II: [A practical and realistic example](/post/kubernetes-tutorial-ii-deploying-an-app/)
* Part III: Best practices (this post)

#### Table of contents
* [Application development](#application-development)
    * [Health checks](#health-checks)
    * [Graceful shutdown](#graceful-shutdown)
    * [Declarative management and versioning](#declarative-management-and-versioning)
* [Cluster management](#cluster-management)
    * [Namespaces](#namespaces)
    * [Resource limits and requests](#resource-limits-and-requests)
    * [Scaling](#scaling)
    * [Pod topology](#pod-topology)
* [Security](#security)
    * [Role-based access control](#role-based-access-control-rbac)
    * [Container security](#container-security)

## Application development
### Health checks
By default, Kubernetes marks a Pod as ready and begins to send traffic when all
its containers start, and restarts the containers when they crash. While this
can be acceptable for some simpler deployments, a more robust approach is
necessary for production deployments.

For example, a container might need some warm-up time before it gets to an
operational state. This could mean some requests are dropped if Kubernetes
considers the container ready when it's not. To remedy, we can configure
readiness and liveness probes.

* **Readiness** probes are designed to let Kubernetes know when a Pod is ready
  to accept traffic. A common misconception is that readiness probes are only
  active during startup. This is not true: Kubernetes keeps testing for
  readiness during the whole lifetime of the Pod, and pauses and resumes
  routing to the Pod according to the readiness probe response.
* **Liveness** probes indicate whether a container is alive or not: if it's not
  it will be restarted by Kubernetes. This probe can be used to detect
  deadlocks or other broken states that don't necessarily result in a crash.

There are three types of probes: HTTP checks, TCP checks, and checks performed
by running commands inside the container. The following is an example
configuration of Readiness and Liveness probes:

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

### Graceful shutdown
When a Pod is terminated, Kubernetes does two things in parallel:

1. it sends the SIGTERM signal to the containers in the Pod, so it's important
   that they handle it correctly and start shutting down the application;
2. it invokes the [preStop
   hook](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-details)
   inside the containers that define it. This hook should be implemented if the
   containers cannot handle SIGTERM for some reason, or if there are multiple
   containers in the Pod and the order in which they shut down matters.

It's also important to ensure that the application does not shut down
immediately upon receiving SIGTERM. It might take some time before kube-proxy
or the Ingress controller are notified of the endpoint change, and traffic
could still reach the Pod even though it's marked as terminated.

### Declarative management and versioning
Kubernetes objects can be created, updated, and deleted by storing multiple
object configuration files in a directory and using `kubectl apply` to
recursively create and update those objects as needed. The `kubectl diff`
command gives a preview of the changes that the `apply` subcommand will make.
The `kubectl delete` command also accepts manifest files.

The configuration can be written in JSON or YAML files, with the latter being
the preferred format if humans have to read and update the configuration. This
object management is called "declarative", and it's the opposite of the
"imperative" style in which changes are requested directly with the `run`,
`create`, `scale` and `patch` subcommands. Declarative management has several
advantages over the imperative methodology:

* object configuration can be stored and versioned in source control system
  like Git, making reviewing, debugging and auditing much easier;
* object configuration can be integrated with other processes like Git hooks or
  CI/CD pipelines;
* existing configuration can be used as a template for new objects, ensuring
  consistency and making the process quicker.

Lastly, it's recommended to annotate the objects with the
`kubernetes.io/change-cause` annotation at each configuration update, or at
least the most important ones. By doing that, one can review the revision
history of any object with the command `kubectl rollout history`. For example:

```shell
$ kubectl rollout history deployment/api
deployment.extensions/api
REVISION  CHANGE-CAUSE
1         v0.1.0 - 9ffcfee
2         v0.2.0 - 4f2f949
3         v0.2.1 - 011d68f
4         v0.2.2 - b9806cc
```

## Cluster management
### Namespaces
Namespaces are also called "virtual clusters" by the [Kubernetes
documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).
These virtual clusters are backed by the same physical cluster, and they are
all logically isolated from each other. Isolation helps with the cluster
organization and security.

The first three Namespaces created in a cluster are `default`,
`kube-system`, and `kube-public`. These namespaces are not reserved and it's
possible to deploy to them, but it's best not to do that.

* `default` is for objects that are not explicitly assigned to a Namespace;
  deploying everything in there is going to clutter your cluster and it will
  become hard to administer very quickly;
* `kube-system` is for all objects related to the Kubernetes system. Deploying
  to this Namespace can damage the functionality of the cluster, so it
  shouldn't be done except in rare cases;
* `kube-public` is readable by all users and it's created by kubeadm &mdash;
  it's best not to touch it.

In bigger projects, Namespaces are useful to separate different teams or
projects into separate environments. In small clusters (e.g. a single
small application), I find them very useful to split different environments
(e.g. staging, production). Namespaces can be isolated at the network level
with
[NetworkPolicies](https://github.com/ahmetb/kubernetes-network-policy-recipes).
Furthermore, a cluster administrator can restrict resource consumption and
creation on a Namespace basis, using
[LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/) and
[ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
policies.

### Resource limits and requests
Resource requests indicate how much of each resource a Container needs to run.
The most common resources to specify are CPU and memory. For a complete list,
consult the
[documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits).
It's best to always specify those with the minimum requirements. If resource
requests are not specified, Kubernetes assumes that a Container has a memory
and CPU utilization of zero. That could potentially lead Kubernetes to schedule
too many Pods on the same node and exhaust all the resources.

It's also possible to specify resource limits that containers cannot exceed.
Whether it's better to specify them or not should be decided case by case, as
the container runtime might terminate containers which attempt to exceed the
limits. CPU resources, for example, are compressible. When they are exhausted,
the kernel will start throttling the processes. That might be a more desirable
behavior than termination.

If you are unsure about the resource usage of your Containers, you can run the
[Vertical Pod
Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#quick-start)
in the "Off" mode and inspect the recommendations.

### Scaling
The local filesystem in a container should never be used to persist data. If
you do that, each Pod in a ReplicaSet will potentially have a different state.
As a consequence, it won't be possible to leverage horizontal scaling
strategies in a consistent way.

Kubernetes supports several scaling strategies:

* the [Horizontal Pod
  Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
  scales the applications across Pods, so it's usually a good fit for stateless
  applications and should be the preferred scaling strategy;
* the [Vertical Pod
  Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
  scales the application by adding resources to single Pods, so it can be used
  if the application cannot be scaled horizontally (note that it's still in
  beta at this time);
* the [Cluster
  Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
  scales the whole cluster by adding or removing worker nodes. This scaling
  strategy makes sense when the workloads are highly variable and can see rapid
  demand spikes. When demand changes gradually the other scaling strategies
  should be preferred.

### Pod topology
Multiple replicas are not enough to guarantee high availability. If all the
replicas are scheduled on the same node, the node becomes the single point of
failure. Inter-pod [affinity and
anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity)
rules can be used to instruct Kubernetes to constrain which nodes are eligible
for scheduling based on Pods that are already running on nodes rather than
based on node labels.

For example, we can use an anti-affinity rule to disallow scheduling on nodes
that are already running Pods that match the specified label selector:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: web
      topologyKey: 'kubernetes.io/hostname'
```

(Note that the requirement specified above is a *hard* requirement &mdash; the
corresponding *soft* requirement can be specified with
`preferredDuringSchedulingIgnoredDuringExecution`).

For additional safety, it's recommended to set
[PodDisruptionBudgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
that limit the number of Pods of a replicated application that can be down
simultaneously. This prevents voluntary disruptions from happening, e.g. a node
drain request from the cluster administrator that would evict too many Pods.
Disruption Budgets cannot prevent involuntary disruptions but they do count
against the budget. Note that at this time Disruption Budgets are in beta.

## Security
### Role-based access control (RBAC)
In a computer system, access should be regulated according to the security
principle of least privilege: users and programs should not have any more
permissions than they need to accomplish their tasks. In Kubernetes, that is
accomplished with [RBAC
policies](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).
Implementing RBAC policies properly can easily get out of hand, and that's
where an operator like [RBAC
Manager](https://github.com/FairwindsOps/rbac-manager) can help.

### Container security
There are several best practices regarding container security:
* disallow root user execution
* disallow privileged containers
* disallow changes to kernel parameters
* disallow the use of the host network
* require read-only root filesystem

All of these best practices can be enforced with [Pod Security
Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/?utm_source=thenewstack&utm_medium=website),
which at this time are still in beta. An alternative is to use a policy
management framework like [Kyverno](https://kyverno.io/) to validate, mutate
and generate workload configurations. Kyverno works by installing an admission
controller webhook receiver. The GitHub repository contains a lot of [sample
resources](https://github.com/nirmata/kyverno/tree/master/samples) that enforce
the above best practices and many more.

## Conclusion
This post concludes the tutorial series. I hope this list of best practices did
not overwhelm you. I also wrote this as a reference for myself. By all means,
do not start implementing everything immediately, but use this list as a
starting point to learn new Kubernetes concepts and workflows. Some of them, on
the other hand, are quite critical (e.g. keeping all your configuration in
versioned YAML files), and you should definitely start adopting them
immediately.
