+++
author = "Michele Lacchia"
title = "Kubernetes tools and plugins for enhanced productivity"
tags = ["kubernetes", "containers", "big-list"]
category = "posts"
date = "2020-06-07"
hasCode = true
summary = "A list of useful Kubernetes tools for enhanced productivity."
+++

<figure>
    <img itemprop="image" title="A pipeline" src="/static/images/port-containers.jpg" />
    <div class="copyright">
        Photo by&nbsp;<a href="https://unsplash.com/@timelabpro?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Timelab Pro</a>&nbsp;on&nbsp;<a href="https://unsplash.com/s/photos/port-containers?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>.
    </div>
</figure>

`kubectl` is a great tool, but when the clusters start to multiply and each one
has several namespaces, staying productive can become a challenge. In this
short post I present some tools that I consider very useful when managing
Kubernetes clusters. The first three (kubectx, kubens, stern) are absolutely
essential, and I could not do without them anymore.

### kubectx and kubens
If you have multiple clusters, you can switch between them using the command

```shell
$ kubectl config use-context <name>
```

This procedure quickly becomes annoying when you start managing many different
clusters or the context names are not short. E.g. in GKE, the default context
name has the form `gke_<project id>_<region>-<zone>_<cluster name>`.

The [`kubectx`](https://github.com/ahmetb/kubectx) command allows you to
accomplish this task and related ones much more quickly and efficiently:

| Command               | Explanation                           |
|:----------------------|:--------------------------------------|
| `kubectx <name>`      | switch to the context `<name>`        |
| `kubectx -`           | switch to the previous context        |
| `kubectx <new>=<old>` | rename `<old>` to `<new>`             |
| `kubectx <new>=.`     | rename the current context to `<new>` |

If you install [`fzf`](https://github.com/junegunn/fzf), kubectx becomes
interactive:

<img src="/static/images/kubectx-interactive.gif" style="margin-bottom:2em">

The companion command [`kubens`](https://github.com/ahmetb/kubectx), allows you
to switch between namespaces:

| Command         | Explanation                      |
|:----------------|:---------------------------------|
| `kubens <name>` | switch to the namespace `<name>` |
| `kubens -`      | switch to the previous namespace |
| `kubens -c`     | show the current namespace       |

With `fzf`, kubens becomes interactive too. Both tools also support tab
completion.

### stern
The built-in command to tail logs, `kubectl logs`, has two significant
limitations:

1. it can only tail logs from one Pod at a time, and the Pod name has to be
   specified exactly &mdash; this is inconvenient when applications are
   deployed with multiple replicas; the Pod name will also change every time
   it's recreated.
2. If multiple containers are present within a Pod, the container name has to
   be specified exactly. It's not possible to tail logs from multiple
   containers at the same time.

To work around those limitations, [`stern`](https://github.com/wercker/stern)
was created. It makes log-tailing a breeze, allowing to tail logs from multiple
containers and Pods at the same time. Pods and containers are included and
excluded with regular expressions, and that makes stern incredibly flexible. It
can even filter on the message timestamps and output in several different
formats.

| Command                               | Explanation                                                           |
|---------------------------------------|-----------------------------------------------------------------------|
| `stern "web-\w"`                      | tail logs from all containers in Pods matching the `web-\w` regex     |
| `stern web -c nginx`                  | tail logs from the `nginx` container in Pods matching the "web" query |
| `stern -s 15min backend`              | tail logs newer than a relative duration like "2m" or "3h"            |
| `stern --tail 10 backend`             | show at most 10 lines from the backend Pods                           |
| `stern --all-namespaces -l app=nginx` | tail Pods from all namespaces matching the label selector `app=nginx` |
| `stern web -o json`                   | output logs in JSON format                                            |

### Polaris
[Polaris](https://github.com/FairwindsOps/polaris) is a static analysis tool
that ensures that a variety of best practices are respected. Notably, it also
includes a [validating
webhook](https://github.com/FairwindsOps/polaris#webhook) that can be installed
in your cluster to automatically check all workloads and reject those that
don't adhere to your policies.

### Popeye
[Popeye](https://github.com/derailed/popeye) scans your cluster for best
practices and potential issues. It aims to detect misconfigurations, like port
mismatches, dead or unused resources, metrics utilization, probes, container
images, RBAC rules, naked resources, etc. It should be noted that it's not a
static analysis tool, as it actually inspects the live cluster. For that
reason, the user running Popeye must have enough RBAC privileges to get/list
the resources that Popeye checks. Overall, Popeye is a good complement to
Polaris.

### krew
[`krew`](https://github.com/kubernetes-sigs/krew) is a plugin manager for
kubectl. As of the date of this post, there are more than [70
plugins](https://github.com/kubernetes-sigs/krew-index/blob/master/plugins.md)
available through krew. Many of the tool mentioned in this post are also
installable with krew. Installing new plugins is very easy and straightforward.

### RBAC manager and rbac-lookup
When RBAC policies start to become unmanageable, a tool like [RBAC
Manager](https://github.com/FairwindsOps/rbac-manager) becomes essential. The
RBAC Manager operator introduces new custom resources that allow a declarative
management style of RBAC policies. Instead of managing role bindings directly,
one can specify the desired RBAC state and the operator will take the necessary
actions to achieve that state.

[The example](https://github.com/FairwindsOps/rbac-manager#an-example) in the
README is clearer than any explanation. Suppose that we want to grant our user
Joe `edit` access to the `web` namespace and `view` access to `api` namespace.
With RBAC, that requires creating two role bindings. The first grants `edit`
access to the `web` namespace:

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: joe-web
  namespace: web
subjects:
- kind: User
  name: joe@example.com
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

The second grants `view` access to the `api` namespace:

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: joe-api
  namespace: api
subjects:
- kind: User
  name: joe@example.com
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
```

One can easily see how this approach can quickly grow out of control with many
users and many namespaces. With RBAC Manager, one can use a single custom
resource to achieve the same result:

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: joe-access
rbacBindings:
  - name: joe
    subjects:
      - kind: User
        name: joe@example.com
    roleBindings:
      - namespace: api
        clusterRole: view
      - namespace: web
        clusterRole: edit
```

The companion tool [`rbac-lookup`](https://github.com/FairwindsOps/rbac-lookup)
is very useful to inspect roles bound to any user or service account. When run
on GKE clusters, it can also show IAM roles.
