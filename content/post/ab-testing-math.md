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


## Statistical inference
Statistical inference is the application of statistical methods to learn the
characteristics of a data-generating mechanism which can be used to support
causal claims and predictions.


There are two kinds of errors one must guard against in designing a
hypothesis test, and therefore an A/B test.

The first, called the Type I error, consists in rejecting the null hypothesis
$H_0$ when it's in fact true. When comparing two conversion rates for instance,
it'd be equivalent to declaring that the difference between them is real when in fact the difference is zero. This
kind of error has been given the greater amount of attention in elementary
statistics books, and hence in practice. It is typically guarded against simply
by setting the significance level $\alpha$ for the chosen statistical test, at a
suitably small probability such as $0.01$ or $0.05$.

This kind of control is not totally adequate, because a literal Type I error
probably never occurs in practice. The reason is that the two populations
giving rise to the observed samples will inevitably differ to some extent, albeit
possibly by a trivially small amount. No matter how small the difference in
conversion rates is between the two underlying populations, provided it is
nonzero, samples of sufficiently large size can virtually guarantee statistical
significance. Assuming that an investigator desires to declare significant only
differences that are of practical importance, and not merely differences of any
magnitude, he should impose the added safeguard of not employing
sample sizes that are larger than he needs to guard against the second kind
of error.

The second kind of error, called the Type II error, consists in failing to
declare the two conversion rates significantly different when in fact they are
different. As just pointed out, such an error is not serious when the
proportions are only trivially different. It becomes serious only when the
proportions differ to an important extent. The practical control over the Type
II error must therefore begin with the investigator's specifying just what
difference is of sufficient importance to be detected, and must continue with
the investigator's specifying the desired probability of actually detecting it.
This probability, denoted $1 - \beta$, is called the **power** of the test; the
quantity $\beta$ is the probability of failing to find the specified difference
to be statistically significant.

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

## Binary responses with equal sample sizes
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

The goal of our A/B experiment is to evaluate the two-tailed hypothesis test

$$
\begin{align\*}
H_0&: \theta = 0\\\\
H_a&: \theta \neq 0
\end{align\*}\quad\quad\theta = p_1 - p_0
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
\Delta_n \sim \mathcal N(\theta, \sigma_{\Delta n}^2 n^{-1}),
\quad\quad \sigma_{\Delta n}^2 = p_0(1 - p_0) + p_1(1 - p_1)
$$

We can then define our test statistic:

$$
Z_n = \frac{\Delta_n \sqrt{n}}{\sigma_{\Delta n}}
$$

and it's easy to verify that $Z_n \sim \mathcal N(\theta \sigma_{\Delta n}^{-1}
\sqrt{n}, 1)$, a standard normal distribution under $H_0$. However, since the
standard deviation $\sigma_{\Delta n}$ depends on $p_0$ and $p_1$, which are
unknown, we'll need to replace it with a suitable estimator. From $(1)$, we
know that the sample means $\bar X_n$ and $\bar Y_n$ are unbiased estimators of
the proportions $p_0$ and $p_1$. Thus we can define

$$
\begin{align\*}
\hat \sigma_{\Delta n}^2 = \bar X_n(1 - \bar X_n) + \bar Y_n(1 - \bar Y_n)
\end{align\*}
$$

Our revised test statistic is now

$$
Z_n^\prime = \frac{\Delta_n \sqrt{n}}{\hat \sigma_{\Delta n}}
$$

This statistic is no longer distributed as a normal variable, but
rather as a Student's t variable with $n - 1$ degrees of freedom. However, the
density of a Student's t distribution approaches the density of a normal
distribution as $n$ tends to infinity. In practice, the difference between the
two is considered minimal at $n > 30$. In online controlled experiments we
usually deal with much larger samples, and thus we can safely use the normal
approximation and assume $Z_n^\prime \sim \mathcal N(\theta \hat \sigma_{\Delta
n}^{-1} \sqrt{n}, 1)$.

We now define a "rejection rule" based on the statistic $Z_n^\prime$ to achieve
the desired type I error rate; we'll reject the null hypothesis $H_0$ when the
test statistic is too large (in absolute value, for a two-sided test), i.e.
when $|Z_n^\prime| > c$ for some value $c \in \mathbb R$. The probability of
making a two-sided type I error, i.e. of rejecting $H_0$ when it's in fact
true, is

$$
\begin{aligned}
\alpha &= \operatorname{Pr}(\text{Reject } H_0 \mid H_0 \text{ is true}) =\\\\
&= \operatorname{Pr}(|Z_n^\prime| > c \mid \theta = 0) =\\\\
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
\begin{align}
c = \Phi^{-1}(1 - \alpha/2),
\end{align}
$$

which is sometimes written as $z_{1 - \alpha/2}$.

So far we ignored the sample size $n$: how many observations are enough? To
find a suitable sample size we turn to the type II error $\beta$, and we seek
to determine the conditions under which it can be kept sufficiently low.

We are going to calculate the power at $\theta = \delta > 0$, our
minimum effect of interest. The power of the test will be higher for higher
values of $\theta$, and lower for lower values.

$$
\begin{aligned}
1 - \beta &= 1 - \operatorname{Pr}(\text{Accept } H_0 \mid H_0 \text{ is false}) =\\\\
&= 1 - \operatorname{Pr}(|Z_n^\prime| \leq c \mid \theta \neq 0) =\\\\
&= \operatorname{Pr}(|Z_n^\prime| > c \mid \theta = \delta) =\\\\
&= \operatorname{Pr}(Z_n^\prime > c \mid \theta = \delta) + \operatorname{Pr}(Z_n^\prime < -c \mid \theta = \delta)
\end{aligned}
$$

Observe that at $\theta = \delta$, the second probability is going to be
vanishingly small, and can be ignored for practical purposes. Therefore:

$$
\begin{aligned}
1 - \beta &\approx \operatorname{Pr}(Z_n^\prime - \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n} > c -\delta\hat \sigma_{\Delta n}^{-1} \sqrt{n}) =\\\\
&= 1 - \Phi(c - \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n})
\end{aligned}
$$

Recall from $(2)$ that we found that in order to limit the type I error at
the desired significance level $\alpha$, the critical value $c$ must be equal
to $\Phi^{-1}(1 - \alpha/2)$. Therefore,

$$
\begin{aligned}
\Phi^{-1}(1 - \beta) &= \Phi^{-1}(1 - \Phi(\Phi^{-1}(1 - \alpha/2) - \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n})) =\\\\
&= \Phi^{-1}(\Phi(-\Phi^{-1}(1 - \alpha/2) + \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n})) =\\\\
&= -\Phi^{-1}(1 - \alpha/2) + \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n}\\\\
\end{aligned}
$$

Before presenting the final expression for $n$, note that $\hat \sigma_{\Delta n}$ depends on $\bar X_n$ and $\bar Y_n$, which are observable only after the experiment is completed. Thus we can define

$$
s^2 = P_0 (1 - P_0) + P_1 (1 - P_1)
$$

as a replacement for $\hat \sigma_{\Delta n}^2$, where $P_0$ and $P_1$ are
hypothesized by the designer of the experiment and are such that $P_1 - P_0 =
\delta$. In practice, $P_0$ is derived from existing available data (such as
conversion data from Google Analytics or a similar tracking tool), and $P_1$ is
calculated after defining the minimum effect of interest $\delta$. Ideally,
historical data should be:

* recent enough to be representative for the A/B test;
* without outliers (like holidays for an e-commerce site); and
* from a time period that is a multiple of the business cycle (to avoid
  seasonality effects).

Finally we can solve for $n$ and obtain

$$
\begin{align}
n = \frac{{\left[\Phi^{-1}(1 - \alpha/2) + \Phi^{-1}(1 - \beta)\right]}^2 s^2}{\delta^2}
\end{align}
$$

Observe that the sample size $n$ required to attain power $1 - \beta$ and
maintain significance $\alpha$:

1. is directly proportional to the variance $\hat \sigma_{\Delta n}^2$
2. is inversely proportional to the square of the minimum effect of interest
   $\delta$

This makes intuitive sense as, all else being equal, data with higher variance
will make the same effect of interest $\delta$ more difficult to detect with
the given significance level. Similarly, smaller effects are going to require a
bigger sample for the same $\alpha$ and $1 - \beta$.

In practice, as found by [Haseman (1978)](https://doi.org/10.2307/2529595),
the sample size calculated using the normal approximation above
results in values that are too low, in the sense that the power of the test is
lower than $1 - \beta$ at $\theta = \delta$.
[Casagrande, Pike, and Smith (1978b)](https://doi.org/10.2307/2530613) derived
the following adjustment (called "continuity correction"),

$$
\begin{align}
n^\star = \frac{n}{4}{\left(1 + \sqrt{1 + \frac{4}{n \delta}}\right)}^2
\end{align}
$$

which provides values very close to the exact sample size. The exact
calculation of the sample size requires an iterative procedure involving
binomial distributions, and thus it's rarely used in practice. $(4)$ or even
$(3)$ provide good approximations.


## Unequal sample sizes
## Continous responses
## Types of hypothesis tests
## Simulation
## Streaming algorithm and segment analysis
