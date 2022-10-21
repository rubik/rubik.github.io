---
author: "Michele Lacchia"
title: "A/B testing fundamentals - part II: binary and continous responses"
date: "2022-10-08"
tags: ["math", "statistics", "ab-tests"]
hasMath: true
draft: false
summary: "Statistical framework underlying online A/B testing: formulas for binary and continous responses."
---

This post continues the A/B testing series and it shows how to derive key
formulas for some common cases encountered in online A/B tests. This post
assumes some basic knowledge about calculus, random variables, and statistics.
For an overview of the basic concepts and the underlying statistical framework,
I recommend reading part I of the series linked below.

### A/B testing fundamentals series
* [Part I: Statistical inference and hypothsis testing](/post/ab-testing-inference)
* Part II: Formulas for binary and continous responses (this post)
* Part III: Group sequential tests
* Part IV: Multivariate tests


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
\begin{aligned}
X_i &\sim \operatorname{Bernoulli}(p_1)\\\\
Y_i &\sim \operatorname{Bernoulli}(p_2)
\end{aligned}
$$

We'll further assume that different observations in the same test arm are
_independent_, and that observation from a test arm are independent from all
observations in the other arm. This assumption is key because otherwise we
wouldn't be able to apply the normal approximation discussed below.
Furthermore, if observations are paired, [McNemar's
test](https://en.wikipedia.org/wiki/McNemar%27s_test) might be more
appropriate.

The goal of our A/B experiment is to evaluate the one-tailed hypothesis test

$$
\begin{aligned}
H_0&: \theta \leq 0\\\\
H_a&: \theta > 0
\end{aligned}\quad\quad\theta = p_2 - p_1
$$

where the null hypothesis $H_0$ is that there's no difference in the
data-generation processes of $X_i$ and $Y_i$ ($p_1 = p_2$). We seek to reject
the null hypothesis with Type I error $\alpha \in (0, 1)$. We'll furthermore
require power $1 - \beta \in (0, 1)$ at $\theta = \delta > 0$.

We chose a one-tailed test as opposed to the more common two-tailed tests
because they make much more sense in the context of online A/B testing, where
we are interested in determining whether the new variant is sufficiently better
than control. This was also discussed in [part
I](/post/ab-testing-inference/#types-of-hypotheses).

Let's define the sample mean to be

$$
\bar X_n = \frac 1n \sum_{i = 1}^n X_i,\quad
\bar Y_n = \frac 1n \sum_{i = 1}^n Y_i
$$

It can be observed that in this case it corresponds to the _sample conversion
rate_ of each variant.

Since the conversion variables are independent and have finite mean and
variance, we can apply the [Central Limit
Theorem](https://en.wikipedia.org/wiki/Central_limit_theorem#Classical_CLT)
which states that, as $n$ approaches infinity, the distribution of $\sqrt n
(\bar X_n - p_1)$ approaches that of a normal variable with mean $0$ and
standard deviation $\operatorname{Var}(X_i) = p_1(1 - p_1)$. The same holds for $\bar
Y_n$ and $\sqrt n (\bar Y_n - p_2)$. Hence in practice, for a sufficiently
large $n$,

$$
\begin{aligned}
\begin{split}
\bar X_n &\sim \mathcal N(p_1, p_1(1 - p_1) / n)\\\\
\bar Y_n &\sim \mathcal N(p_2, p_2(1 - p_2) / n)
\end{split}
\end{aligned}
$$

We are interested in the difference of sample means, $\Delta_n = \bar Y_n -
\bar X_n$. As $\Delta_n$ is a linear combination of normal variables, it's also
normally distributed:

<p class="non-mobile">
$$
\Delta_n \sim \mathcal N(\theta, \sigma_{\Delta n}^2),
\quad\quad \sigma_{\Delta n}^2 = [p_1(1 - p_1) + p_2(1 - p_2)] / n
$$
</p>

<p class="mobile">
$$
\Delta_n \sim \mathcal N(\theta, \sigma_{\Delta n}^2),\ \text{with}
$$
$$
\quad\quad \sigma_{\Delta n}^2 = [p_1(1 - p_1) + p_2(1 - p_2)] / n
$$
</p>

We can then define our test statistic:

$$
Z_n = \frac{\Delta_n}{\sigma_{\Delta n}}
$$

and it's easy to verify that $Z_n \sim \mathcal N(\theta \sigma_{\Delta n}^{-1}, 1)$, a standard normal distribution under $H_0$. However, since the
standard deviation $\sigma_{\Delta n}$ depends on $p_1$ and $p_2$, which are
unknown, we'll need to replace it with a suitable estimator. Thus we define

$$
\begin{aligned}
\hat \sigma_{\Delta n}^2 = \frac{2\bar W_n(1 - \bar W_n)}{n}
\end{aligned}
$$

where we used the pooled variance estimator and $\bar W_n = (\bar X_n + \bar
Y_n) / 2$.

Our revised test statistic is now

$$
\begin{aligned}
Z_n^\prime = \frac{\Delta_n}{\hat \sigma_{\Delta n}}
\end{aligned}
$$

This statistic is still approximately normal for large $n$ values. In online
controlled experiments we usually deal with much larger samples, and thus we
can safely use the normal approximation and assume $Z_n^\prime \sim \mathcal
N(\theta \hat \sigma_{\Delta n}^{-1}, 1)$.

<blockquote>
<strong>Note</strong>: the test statistic defined above is the so-called
"pooled" statistic for this test. The "unpooled" version $Z_{n,\
\text{pooled}}^\prime$ is defined just like $Z_n^\prime$, except for the
variance estimate:

<p class="non-mobile">
$$
Z_{n,\ \text{unpooled}}^\prime = \frac{\Delta_n}{\hat \sigma_{\Delta n,\ \text{unpooled}}},\quad\quad\hat \sigma_{\Delta n,\ \text{unpooled}}^2 = \bar X_n(1 - \bar X_n) + \bar Y_n(1 - \bar Y_n)
$$
</p>

<p class="mobile">
$$
Z_{n,\ \text{unpooled}}^\prime = \frac{\Delta_n}{\hat \sigma_{\Delta n,\ \text{unpooled}}},\ \text{pooled}}},\ \text{with}
$$
$$
\hat \sigma_{\Delta n,\ \text{unpooled}}^2 = \bar X_n(1 - \bar X_n) + \bar Y_n(1 - \bar Y_n)
$$
</p>

The unpooled statistic is also normally distributed for large values of $n$.
The unpooled version has worse small-sample properties than the pooled version,
but they are asymptotically equivalent as $n$ goes to infinity. The large
sample sizes normally encountered in online A/B testing render them essentially
equal in practice. More details and simulation results can be found
[here](https://stats.stackexchange.com/a/573144).
</blockquote>

We now define a "rejection rule" based on the statistic $Z_n^\prime$ to achieve
the desired Type I error rate; we'll reject the null hypothesis $H_0$ when the
test statistic is too large (in absolute value, for a two-sided test), i.e.
when $|Z_n^\prime| > c$ for some value $c \in \mathbb R$. The probability of
making a two-sided Type I error, i.e. of rejecting $H_0$ when it's in fact
true, is

$$
\begin{aligned}
\alpha &= \operatorname{Pr}(\text{Reject } H_0 \mid H_0 \text{ is true}) =\\\\
&= \operatorname{Pr}(Z_n^\prime > c \mid \theta = 0) =\\\\
&= 1 - \Phi(c)
\end{aligned}
$$

where $\Phi$ is the cumulative density function of the standard normal. Thus,
the critical value that we should use to decide whether to reject the null
hypothesis $H_0$ is

$$
\begin{align}
c = \Phi^{-1}(1 - \alpha),
\end{align}
$$

which is sometimes written as $z_{1 - \alpha}$. If this were a two-tailed test,
we would have found that $c = \Phi^{-1}(1 - \alpha / 2)$.

So far we ignored the sample size $n$: how many observations are enough? To
find a suitable sample size we turn to the Type II error $\beta$, and we seek
to determine the conditions under which it can be kept sufficiently low.

We are going to calculate the power at $\theta = \delta > 0$, our
minimum effect of interest. The power of the test will be higher for higher
values of $\theta$, and lower for lower values.

$$
\begin{aligned}
1 - \beta &= 1 - \operatorname{Pr}(\text{Accept } H_0 \mid H_0 \text{ is false}) =\\\\
&= 1 - \operatorname{Pr}(|Z_n^\prime| \leq c \mid \theta = \delta) =\\\\
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

Recall from $(1)$ that we found that in order to limit the Type I error at
the desired significance level $\alpha$, the critical value $c$ must be equal
to $\Phi^{-1}(1 - \alpha)$. Therefore,

$$
\begin{aligned}
\Phi^{-1}(1 - \beta) &= \Phi^{-1}(1 - \Phi(\Phi^{-1}(1 - \alpha) - \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n})) =\\\\
&= \Phi^{-1}(\Phi(-\Phi^{-1}(1 - \alpha) + \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n})) =\\\\
&= -\Phi^{-1}(1 - \alpha) + \delta\hat \sigma_{\Delta n}^{-1} \sqrt{n}\\\\
\end{aligned}
$$

Before presenting the final expression for $n$, note that $\hat \sigma_{\Delta
n}$ depends on $\bar X_n$ and $\bar Y_n$, which are observable only after the
experiment is completed. Thus we can define

$$
s_{\text{pooled}}^2 = 2 \pi (1 - \pi) n^{-1},\qquad\qquad \pi = (\pi_1 + \pi_2)
/ 2
$$

as an estimate of $\hat \sigma_{\Delta n}^2$, where $\pi_1$ and $\pi_2$ are
hypothesized by the designer of the experiment and are such that $\pi_2 - \pi_1
= \delta$. In practice, $\pi_1$ is derived from existing available data (such
as conversion data from Google Analytics or a similar tracking tool), and
$\pi_2$ is calculated after defining the minimum effect of interest $\delta$.
Ideally, historical data should be:

* recent enough to be representative for the A/B test;
* without outliers (like holidays for an e-commerce site); and
* from a time period that is a multiple of the business cycle (to avoid
  seasonality effects).

Finally we can solve for $n$ and obtain

$$
\begin{align}
n = \frac{{2 \pi (1 - \pi) \left[\Phi^{-1}(1 - \alpha) + \Phi^{-1}(1 - \beta)\right]}^2}{\delta^2}
\end{align}
$$

Observe that the sample size $n$ required to attain power $1 - \beta$ and
maintain significance $\alpha$:

1. is directly proportional to the variance $\pi (1 - \pi)$
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
the following adjustment (using the so-called "continuity correction"),

$$
\begin{align}
n^\star = \frac{n}{4}{\left(1 + \sqrt{1 + \frac{4}{n \delta}}\right)}^2
\end{align}
$$

which provides values very close to the exact sample size. The exact
calculation of the sample size requires an iterative procedure involving
binomial distributions, and thus it's rarely used in practice. $(3)$ or even
$(2)$ provide good approximations.


## Unequal sample sizes
The most efficient A/B tests are those with equal sample size allocations.
However, in some specific cases an experimenter may want to design a test with
unequal allocations for a variety of reasons. We can derive a similar formula
to $(2)$ and $(3)$ in this case as well. As before, we consider a one-tailed
non-inferiority test with null hypothesis $H_0: \theta \leq 0$, significance
$\alpha \in (0, 1)$, and power $1 - \beta \in (0, 1)$ at $\theta = \delta > 0$.
The calculations are largely the same, with a few minor differences. Therefore
we'll skip a few elementary steps.

Assume the sample size in variant A is $n$, and the sample size in variant B is
$m$, with $m = rn$ for some $r > 0$. As before, we model each observation as a
Bernoulli random variable:

$$
\begin{aligned}
X_i &\sim \operatorname{Bernoulli}(p_1)\qquad\qquad i = 1, \ldots, n\\\\
Y_j &\sim \operatorname{Bernoulli}(p_2)\qquad\qquad j = 1, \ldots, m
\end{aligned}
$$

The sample means then are:

$$
\bar X_n = \frac 1n \sum_{i = 1}^n X_i,\quad
\bar Y_m = \frac 1n \sum_{j = 1}^m Y_j
$$

For sufficiently large values of $n$ and $m$, it holds that

$$
\begin{aligned}
\begin{split}
\bar X_n &\sim \mathcal N(p_1, p_1(1 - p_1) / n)\\\\
\bar Y_m &\sim \mathcal N(p_2, p_2(1 - p_2) / m)
\end{split}
\end{aligned}
$$

We define the difference of sample means as $\Delta_{n, m} = \bar Y_m - \bar
X_n$. The pooled estimator for the variance of the difference is

$$
\hat \sigma_{\Delta n, m}^2 = \bar W_{n, m}(1 - \bar W_{n, m}) (n^{-1} +
m^{-1})
$$

where $\bar W_{n, m} = (\bar X_n + r \bar Y_m) / (1 + r)$. The test statistic
is then

$$
Z_{n, m}^\prime = \frac{\Delta_{n, m}}{\hat \sigma_{\Delta n, m}},
$$

with sampling distribution $\mathcal N(\theta\hat \sigma_{\Delta n, m}^{-1},
1)$.

Simple algebra shows that the critical value for this statistic is again $c =
\Phi^{-1}(1 - \alpha)$. At $\theta = \delta$, the power of the test is required
to be $1 - \beta$:

$$
\begin{aligned}
1 - \beta &= 1 - \operatorname{Pr}(\text{Accept } H_0 \mid H_0 \text{ is false}) =\\\\
&= 1 - \operatorname{Pr}(Z_n^\prime \leq c \mid \theta = \delta) =\\\\
&= 1 - \Phi(c - \delta\hat \sigma_{\Delta n, m}^{-1})
\end{aligned}
$$

By substituting $c = \Phi^{-1}(1 - \alpha)$, we obtain:

$$
\begin{aligned}
\Phi^{-1}(1 - \beta) &= \Phi^{-1}(1 - \Phi(\Phi^{-1}(1 - \alpha) - \delta\hat \sigma_{\Delta n, m}^{-1})) =\\\\
&= \Phi^{-1}(\Phi(-\Phi^{-1}(1 - \alpha) + \delta\hat \sigma_{\Delta n, m}^{-1} )) =\\\\
&= -\Phi^{-1}(1 - \alpha) + \delta\hat \sigma_{\Delta n, m}^{-1}\\\\
\end{aligned}
$$

Since $\hat \sigma_{\Delta n, m}$ depends on $\bar X_n$ and $\bar Y_m$, which
are observable only after the experiment is completed, we define

$$
s_{\text{pooled}}^2 = \pi (1 - \pi)(n^{-1} + m^{-1}),\qquad \pi = (\pi_1 + r \pi_2) / (1 + r)
$$

as an estimate of $\hat \sigma_{\Delta n, m}^2$, where $\pi_1$ and $\pi_2$ are
hypothesized by the designer of the experiment and are such that $\pi_2 - \pi_1 = \delta$.

Finally, we substitute $m = rn$ and we solve for $n$, obtaining:

$$
\begin{align}
n = \frac{1 + r}{r}\frac{\pi (1 - \pi) {\left[\Phi^{-1}(1 - \alpha) + \Phi^{-1}(1 - \beta)\right]}^2}{\delta^2}
\end{align}
$$

The continuity-corrected value $n^\star$ is

$$
\begin{align}
n^\star = \frac{n}{4}{\left(1 + \sqrt{1 + \frac{2(1 + r)}{n r \delta}}\right)}^2
\end{align}
$$

## Continuous responses
In online A/B testing there are several continuous variables of interest, the
most important of which usually are: average order value (AOV), and average
revenue per user (ARPU). ARPU is defined as the product between conversion rate
and AOV.

These continous variables are not normally distributed, but if the observations
are independent, the sample means will are normally distributed, thanks to the
Central Limit Theorem.

## One-pass algorithms
