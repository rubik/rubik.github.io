+++
author = "Michele Lacchia"
title = "Kubernetes tools and plugins for enhanced productivity"
tags = ["kubernetes", "containers", "big-list"]
category = "posts"
date = "2020-06-02"
summary = "A list of useful Kubernetes tools for enhanced productivity."
+++

<div class="img-with-copyright">
<img itemprop="image" title="A pipeline" src="/static/images/port-containers.jpg" />
<div class="copyright"><span>Photo by <a href="https://unsplash.com/@timelabpro?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Timelab Pro</a> on <a href="https://unsplash.com/s/photos/port-containers?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>.<span style="clear:both"></span></span></div>
</div>

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

### Popeye

### Polaris

### krew

### RBAC manager and rbac-lookup
