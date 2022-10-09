---
author: "Michele Lacchia"
title: "A/B testing math"
date: "2022-10-08"
tags: ["math", "ab-tests"]
hasmath: true
summary: "Mathematical framework underlying online A/B testing using a frequentist approach."
---

A/B testing, also referred to as "split testing", is a randomized
experimentation process wherein two or more versions of a variable (web page,
page element, etc.) are shown to different segments of website visitors at the
same time to determine which version leaves the maximum impact and drives
business metrics. This post explores the mathematical framework behind
statistical A/B testing, and it assumes some basic knowledge about random
variables and calculus.

#### Table of contents

* [Statistical models](#statistical-models)
* [Binary responses](#binary-responses)
    * [Model](#model)
    * [Example](#example)
* [Continuous responses](#continous-responses)
    * [Model](#model-2)
    * [Example](#example-2)

## Statistical models

An A/B test's underlying statistical model comprises the following elements:

* a substantive hypothesis to be tested -- including distributional assumptions
  on the random variables involved
* a specification of the hypothesis testing method, i.e. a target significance
  level $\alpha \in (0, 1)$

### Table of error types

<table>
    <tbody>
        <tr>
            <th rowspan="2" colspan="2"></th>
            <th colspan="2">Null hypothesis $H_0$ is</th>
        </tr>
        <tr style="border-bottom:solid 2px black">
            <th>True</th>
            <th>False</th>
        </tr>
        <tr>
            <th rowspan="2" style="padding-right:10px;border-bottom:none">Decision about<br> null hypothesis $H_0$</th>
            <th style="border-bottom:none">Don't reject</th>
            <td style="text-align:center;">
                <p>Correct inference<br> (true negative)</p>
                <p>Probability $= 1 - \alpha$</p>
            </td>
            <td style="text-align:center;">
                <p>Type II error<br> (false negative)</p>
                <p>Probability $= \beta$</p>
            </td>
        </tr>
        <tr>
            <th style="border-bottom:none">Reject</th>
            <td style="text-align:center;">
                <p>Type I error<br> (false positive)</p>
                <p>Probability $= \alpha$</p>
            </td>
            <td style="text-align:center;">
                <p>Correct inference<br> (true positive)</p>
                <p>Probability $= 1 − \beta$</p>
            </td>
        </tr>
    </tbody>
</table>

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
_independent_. This assumption is key because... TODO

The goal of our A/B experiment is to evaluate the hypothesis test

$$
\begin{align\*}
H_0&: \delta = 0\\\\
H_a&: \delta \neq 0
\end{align\*}\quad\quad\delta = p_1 - p_0
$$

where the null hypothesis $H_0$ is that there's no difference in the
data-generation processes of $X_i$ and $Y_i$ ($p_0 = p_1$). We seek to reject the
null hypothesis with type I error $\alpha \in (0, 1)$.

Let's define the sample mean to be

$$
\bar X_i = \frac 1n \sum_{i = 1}^n X_i,\quad
\bar Y_i = \frac 1n \sum_{i = 1}^n Y_i
$$

It can be observed that in this case it corresponds to the _conversion rate_ of
each variant.

Since the conversion variables are independent and have finite mean and
variance, we can apply the [Central Limit
Theorem](https://en.wikipedia.org/wiki/Central_limit_theorem#Classical_CLT)
which states that, as $n$ approaches infinity, the distribution of $\sqrt n
(\bar X_n - p_0)$ approaches that of a normal variable with mean $0$ and
standard deviation $\mathrm{Var}(X_i) = p_0(1 - p_0)$. The same holds for $\bar
Y_n$ and $\sqrt n (\bar Y_n - p_1)$. Hence in practice, for a sufficiently
large $n$,

$$
\begin{align}
\begin{split}
\bar X_n &\sim \mathcal N(p_0, p_0(1 - p_0) / n)\\\\
\bar Y_n &\sim \mathcal N(p_1, p_1(1 - p_1) / n)
\end{split}
\end{align}
$$

We are interested in the difference of sample means, $\Delta_n = \bar Y_n -
\bar X_n$. As $\Delta_n$ is a linear combination of normal variables, it's also
normally distributed:

$$
\Delta_n \sim \mathcal N(\delta, \sigma_{\Delta n}^2),
\quad\quad \sigma_{\Delta n}^2 = \frac{p_0(1 - p_0) + p_1(1 - p_1)}{n}
$$

We can then define our test statistic:

$$
Z_n = \frac{\Delta_n}{\sigma_{\Delta n}}
$$

and it's easy to verify that $Z_n \sim \mathcal N(\delta, 1)$, a standard
normal distribution under $H_0$ (i.e. $\delta = 0$). However, since the
standard deviation $\sigma_{\Delta n}$ depends on $p_0$ and $p_1$, which are
unknown, we'll need to replace it with a suitable estimator. From $(1)$, we
know that the sample means $\bar X_n$ and $\bar Y_n$ are unbiased estimators of
the proportions $p_0$ and $p_1$. Thus we can define

$$
\begin{align\*}
\hat \sigma_{\Delta n}^2 = \frac{\bar X_n(1 - \bar X_n) + \bar Y_n(1 - \bar Y_n)}{n}
\end{align\*}
$$

Our revised test statistic is now

$$
Z_n^\prime = \frac{\Delta_n}{\hat \sigma_{\Delta n}}
$$

This statistic is no longer distributed as a normal variable, but
rather as a Student's t variable with $n - 1$ degrees of freedom. However, the
density of a Student's t distribution approaches the density of a normal
distribution as $n$ tends to infinity. In practice, the difference between the
two is considered minimal at $n > 30$. In online controlled experiments we
usually deal with much larger samples, and thus we can safely use the normal
approximation.

We now define a "rejection rule" based on the statistic $Z_n^\prime$ to achieve
the desired type I error rate; we'll reject the null hypothesis $H_0$ when the
test statistic is too large (in absolute value, for a two-sided test), i.e.
when $|Z_n^\prime| > c$ for some value $c \in \mathbb R$. The probability of
making a two-sided type I error, i.e. of rejecting $H_0$ when it's in fact
true, is

$$
\begin{aligned}
\alpha &= \operatorname{Pr}(\text{Reject } H_0 \mid H_0 \text{ is true}) =\\\\
&= \operatorname{Pr}(|Z_n^\prime| > c \mid H_0 \text{ is true}) =\\\\
&= \operatorname{Pr}\left(\left|\frac{\Delta_n}{\hat \sigma_{\Delta n}}\right| > c\\;\middle|\\;\delta = 0\right) =\\\\
&= \Phi(-c) + (1 - \Phi(c)) =\\\\
&= 1 - \Phi(c) + 1 - \Phi(c) =\\\\
&= 2 - 2\Phi(c)
\end{aligned}
$$

where $\Phi$ is the cumulative density function of the standard normal, and we
used the symmetry of the standard normal density around $0$. Thus, the critical
value that we should use to decide whether to reject the null hypothesis $H_0$
is

$$
2 - 2\Phi(c) = \alpha \implies c = \Phi^{-1}(1 - \alpha/2),
$$

which is sometimes written as $z_{1 - \alpha/2}$.

So far we ignored the sample size $n$: how many observations are enough? To
find a suitable sample size we turn to the type II error $\beta$, and we seek
to determine the conditions under which it can be kept sufficiently low. By
definition:

$$
\begin{aligned}
\beta &= \operatorname{Pr}(\text{Accept } H_0 \mid H_0 \text{ is false}) =\\\\
&= \operatorname{Pr}(|Z_n^\prime| \leq c \mid H_0 \text{ is false}) =\\\\
&= \operatorname{Pr}\left(\left|\frac{\Delta_n}{\hat \sigma_{\Delta n}}\right| \leq c\\;\middle|\\;\delta \neq 0\right) =\\\\
\end{aligned}
$$

Observe that:

1.
