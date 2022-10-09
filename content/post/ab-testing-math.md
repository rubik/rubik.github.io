---
author: "Michele Lacchia"
title: "A/B testing math"
date: "2022-10-08"
tags: ["math", "ab-tests"]
hasmath: true
summary: "Mathematical framework underlying online A/B testing"
---

A/B testing, also referred to as "split testing", is a randomized
experimentation process wherein two or more versions of a variable (web page,
page element, etc.) are shown to different segments of website visitors at the
same time to determine which version leaves the maximum impact and drives
business metrics. This post explores the mathematical framework behind
statistical A/B testing, and it assumes some basic knowledge about random
variables and calculus.

## Statistical models

An A/B test's underlying statistical model comprises the following elements:

* a substantive hypothesis to be tested -- including distributional assumptions
  on the random variables involved
* a specification of the hypothesis testing method, i.e. a target significance
  level $\alpha \in (0, 1)$
*

## Binary responses
### Model
We'll first describe one of the simplest cases encountered in online A/B tests:
a binary response variable, such as whether a conversion happened or not for a
particular user. Let $X_i, Y_i, i = 1, \ldots, n$ be the conversion data for
the $i$-th user in variants A and B respectively. We'll model a conversion with
a [Bernoulli random
variable](https://en.wikipedia.org/wiki/Bernoulli_distribution) with parameter
$p$, which takes the value $1$ with probability $p$ and value $0$ with
probability $1 - p$:

$$
\begin{align\*}
X_i &\sim \mathrm{Bernoulli}(p_0)\\\\
Y_i &\sim \mathrm{Bernoulli}(p_1)
\end{align\*}
$$

We'll further assume that different observations in the same test arm are
_independent_. This assumption is key because...

The goal of our A/B experiment is to evaluate the hypothesis test

$$
\begin{align\*}
H_0&: \delta = 0\\\\
H_a&: \delta \neq 0
\end{align\*}\quad\quad\delta = p_1 - p_0
$$

where the null hypothesis $H_0$ is that there's no difference in the
data-generation processes of $X_i$ and $Y_i$ ($p_0 = p_1$).

Let's define the sample mean to be

$$
\bar X_i = \frac 1n \sum_{i = 1}^n X_i,\quad
\bar Y_i = \frac 1n \sum_{i = 1}^n Y_i
$$

It can be observed that in this case it corresponds to the _conversion rate_ of
each variant.

Since the conversion variables are independent and have finite mean and variance, we can apply the [Central Limit Theorem](https://en.wikipedia.org/wiki/Central_limit_theorem#Classical_CLT) which states that, as $n$ approaches infinity, the distribution of $\sqrt n (\bar X_n - p_0)$ approaches that of a normal variable with mean $0$ and standard deviation $\mathrm{Var}(X_i) = p_0(1 - p_0)$. The same holds for $\bar Y_n$ and $\sqrt n (\bar Y_n - p_1)$. Hence in practice, for a sufficiently large $n$,

$$
\begin{align}
\begin{split}
\bar X_n &\sim \mathcal N(p_0, p_0^2{(1 - p_0)}^2 / n)\\\\
\bar Y_n &\sim \mathcal N(p_1, p_1^2{(1 - p_1)}^2 / n)
\end{split}
\end{align}
$$

We are interested in the difference of sample means, $\Delta_n = \bar Y_n - \bar X_n$. As $\Delta_n$ is a linear combination of normal variables, it's also normally
distributed:

$$
\Delta_n \sim \mathcal N(\delta, \sigma_{\Delta n}^2),\quad\quad \sigma_{\Delta n}^2 = \frac{p_0^2{(1 - p_0)}^2 + p_1^2{(1 - p_1)\}^2}{n}
$$

We can then define our test statistic:

$$
Z_n = \frac{\Delta_n - \delta}{\sigma_{\Delta n}}
$$

and it's easy to verify that $Z_n \sim \mathcal N(0, 1)$. Since the standard
deviation $\sigma_{\Delta n}$ is unknown, we'll need to replace it with a suitable
estimator. From $(1)$, we know that the sample means $\bar X_n$ and $\bar Y_n$
are unbiased estimators of the proportions $p_0$ and $p_1$. Thus we can define

$$
\begin{align\*}
\hat \sigma_{\Delta n}^2 = \frac{\bar X_n^2{(1 - \bar X_n)}^2 + \bar Y_n^2{(1 - \bar Y_n)\}^2}{n}
\end{align\*}
$$

Our revised test statistic is now

$$
Z_n^\prime = \frac{\Delta_n - \delta}{\hat \sigma_{\Delta n}}
$$

This statistic is no longer distributed as a standard normal variable, but
rather as a Student's t variable with $n - 1$ degrees of freedom. However, the
density of a Student's t variable approaches the density of a standard normal
as $n$ tends to infinity. In practice, the difference between the two is
considered minimal at $n > 30$. In online controlled experiments we usually
deal with much larger samples, and thus we can safely use the normal
approximation.
