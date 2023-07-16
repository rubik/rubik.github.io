---
author: "Michele Lacchia"
title: "A/B testing fundamentals - part III: binary and continous responses"
date: "2022-10-08"
tags: ["math", "statistics", "ab-tests"]
hasMath: true
draft: false
summary: "Statistical framework underlying online A/B testing: formulas for binary and continous responses."
---

This post continues the A/B testing series and it shows how to derive key
formulas for some common cases encountered in online A/B tests. We'll show how
to derive the formulas for the test statistic and sample size calculation.
We'll also provide some online algorithms that allow post-test analysis and
p-value calculations without having to store all the observations.

This post assumes some basic knowledge about calculus, random variables, and
statistics. For an overview of the basic concepts and the underlying
statistical framework, I recommend reading part I of the series linked below.

### A/B testing fundamentals series
* [Part I: Introduction](/post/ab-testing-introduction/)
* [Part II: Statistical inference and hypothsis testing](/post/ab-testing-inference/)
* Part III: Formulas for binary and continous responses (this post)
* Part IV: Group sequential tests
* Part V: Multivariate tests
* Part VI: Bayesian testing
* Part VII: Bayesian vs frequentist testing
* Part VIII: Test evaluation and generalizability of test results


## Sample size for binary responses
We'll first describe one of the most common cases encountered in online A/B
tests: a binary response variable, such as whether a conversion happened or not
for a particular user. Let $X_i, Y_i, i = 1, \ldots, n$ be the conversion data
for the $i$-th user in variants A and B respectively. We'll model a conversion
with a [Bernoulli random
variable](https://en.wikipedia.org/wiki/Bernoulli_distribution) with parameter
$p$, which takes the value $1$ with probability $p$ and value $0$ with
probability $1 - p$:

$$
\begin{aligned}
X_i &\sim \operatorname{Bernoulli}(p_1),\qquad i = 1, \ldots, n\\\\
Y_j &\sim \operatorname{Bernoulli}(p_2),\qquad j = 1, \ldots, m
\end{aligned}
$$

with $m = rn$ for some $r > 0$.

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

where the null hypothesis $H_0$ is that the population proportion of $X_i$ is
equal or greater than the population proportion of $Y_j$. In other words, that
the conversion rate $p_1$ in variant A is equal or greater than the conversion
rate $p_2$ in variant B. We seek to reject the null hypothesis with Type I
error $\alpha \in (0, 1)$. We'll furthermore require power $1 - \beta \in (0,
1)$ at $\theta = \delta > 0$.

We chose a one-tailed test as opposed to the more common two-tailed tests
because one-tailed tests make much more sense in the context of online A/B
testing, where we are interested in determining whether the new variant is
sufficiently better than control. This was also discussed in [part
I](/post/ab-testing-inference/#types-of-hypotheses).

Let's define the sample mean to be

$$
\bar X_n = \frac 1n \sum_{i = 1}^n X_i,\quad
\bar Y_m = \frac 1m \sum_{j = 1}^m Y_j
$$

It can be observed that in this case it corresponds to the _sample conversion
rate_ of each variant.

Since the conversion variables are independent and have finite mean and
variance, we can apply the [Central Limit
Theorem](https://en.wikipedia.org/wiki/Central_limit_theorem#Classical_CLT)
which states that, as $n$ approaches infinity, the distribution of $\sqrt n
(\bar X_n - p_1)$ approaches that of a normal variable with mean $0$ and
standard deviation $\operatorname{Var}(X_i) = p_1(1 - p_1)$. The same holds for
$\bar Y_m$ and $\sqrt m (\bar Y_m - p_2)$. Hence in practice, for sufficiently
large values of $n$ and $m$,

$$
\begin{aligned}
\begin{split}
\bar X_n &\sim \mathcal N(p_1, p_1(1 - p_1) / n)\\\\
\bar Y_m &\sim \mathcal N(p_2, p_2(1 - p_2) / m)
\end{split}
\end{aligned}
$$

We are interested in the difference of sample means,
$\Delta_{n, m} = \bar Y_m - \bar X_n$, because it's an unbiased estimator of
$\theta$. As $\Delta_{n, m}$ is a linear combination of normal variables, it's
also normally distributed:

<p class="non-mobile">
$$
\Delta_{n, m} \sim \mathcal N(\theta, \sigma_{\Delta n, m}^2),
\qquad \sigma_{\Delta n, m}^2 = p_1(1 - p_1) / n + p_2(1 - p_2) / m
$$
</p>

<p class="mobile">
$$
\Delta_{n, m} \sim \mathcal N(\theta, \sigma_{\Delta n, m}^2),\ \text{with}
$$
$$
\sigma_{\Delta n, m}^2 = p_1(1 - p_1) / n + p_2(1 - p_2) / m
$$
</p>

We can then define our test statistic:

$$
Z_{n, m} = \frac{\Delta_{n, m}}{\sigma_{\Delta n, m}}
$$

and it's easy to verify that $Z_{n, m} \sim \mathcal N(\theta \sigma_{\Delta n,
m}^{-1}, 1)$, a standard normal distribution at $\theta = 0$. Since the
standard deviation $\sigma_{\Delta n, m}$ depends on $p_1$ and $p_2$, which are
unknown, we'll need to replace it with a suitable estimator. Thus we define

$$
\begin{aligned}
\hat \sigma_{\Delta n, m}^2 = \bar W_{n, m}(1 - \bar W_{n, m})(n^{-1} + m^{-1})
\end{aligned}
$$

where we used the pooled variance estimator $\bar W_{n, m} = (\bar X_n + r \bar
Y_m) / (1 + r)$.

Our revised test statistic is now

$$
\begin{aligned}
Z_{n, m}^\prime = \frac{\Delta_{n, m}}{\hat \sigma_{\Delta n, m}}
\end{aligned}
$$

This statistic is still approximately normal for large $n$ values. In online
controlled experiments we usually deal with much larger samples, and thus we
can safely use the normal approximation and assume $Z_{n, m}^\prime \sim
\mathcal N(\theta \hat \sigma_{\Delta n, m}^{-1}, 1)$.

<blockquote>
<strong>Note</strong>: the test statistic defined above is the so-called
"pooled" statistic for this test. The "unpooled" version $Z_{n, m,\
\text{unpooled}}^\prime$ is defined just like $Z_{n, m}^\prime$, except for the
variance estimate:

<p class="non-mobile">
$$
Z_{n, m,\ \text{unpooled}}^\prime = \frac{\Delta_{n, m}}{\hat \sigma_{\Delta n, m,\ \text{unpooled}}},\quad\quad\hat \sigma_{\Delta n, m,\ \text{unpooled}}^2 = \bar X_n(1 - \bar X_n) / n + \bar Y_m(1 - \bar Y_m) / m
$$
</p>

<p class="mobile">
$$
Z_{n, m,\ \text{unpooled}}^\prime = \frac{\Delta_{n, m}}{\hat \sigma_{\Delta n, m,\ \text{unpooled}}},\ \text{with}
$$
$$
\hat \sigma_{\Delta n, m,\ \text{unpooled}}^2 = \bar X_n(1 - \bar X_n) / n + \bar Y_m(1 - \bar Y_m) / m
$$
</p>

The unpooled statistic is also normally distributed for large values of $n$.
The unpooled version has worse small-sample properties than the pooled version,
but they are asymptotically equivalent as $n$ goes to infinity. The large
sample sizes normally encountered in online A/B testing render them essentially
equal in practice. More details and simulation results can be found
[here](https://stats.stackexchange.com/a/573144).
</blockquote>

We now define a "rejection rule" based on the statistic $Z_{n, m}^\prime$ to achieve
the desired Type I error rate; we'll reject the null hypothesis $H_0$ when the
test statistic is too large (in absolute value, if this were a two-sided test),
i.e. when $Z_{n, m}^\prime > c$ for some value $c \in \mathbb R$. The
probability of making a Type I error, i.e. of rejecting $H_0$ when it's in fact
true, is

$$
\begin{aligned}
\alpha &= \operatorname{Pr}(\text{Reject } H_0 \mid H_0 \text{ is true}) =\\\\
&= \operatorname{Pr}(Z_{n, m}^\prime > c \mid \theta = 0) =\\\\
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

<blockquote>
<strong>Note:</strong> in the calculation of the Type I error above, we set
$\theta = 0$ when $H_0$ is assumed true. That's because any other $\theta < 0$
would yield a higher critical value $c$. We want to be conservative and select
$\theta = 0$ which is the closest to the alternative hypothesis boundary and
thus the worst case in terms of Type I errors.
</blockquote>

We now derive the conditions to control the Type II error $\beta$, and we'll
find that we can do so by running the experiment with a big enough sample size.
Controlling the Type II error is equivalent to requiring a specific test power,
since the latter is defined as $1 - \beta$.

We are going to calculate the power at $\theta = \delta > 0$, our minimum
effect of interest. The power of the test will be higher for higher values of
$\theta$, and lower for lower values.

$$
\begin{aligned}
1 - \beta &= 1 - \operatorname{Pr}(\text{Accept } H_0 \mid H_0 \text{ is false}) =\\\\
&= 1 - \operatorname{Pr}(Z_{n, m}^\prime \leq c \mid \theta = \delta) =\\\\
&= \operatorname{Pr}(Z_{n, m}^\prime > c \mid \theta = \delta) =\\\\
&= \operatorname{Pr}(Z_{n, m}^\prime - \delta\hat \sigma_{\Delta n, m}^{-1} > c - \delta\hat \sigma_{\Delta n, m}^{-1}) =\\\\
&= 1 - \Phi(c - \delta\hat \sigma_{\Delta n, m}^{-1})
\end{aligned}
$$

As our goal is to obtain an expression for the sample size $n$, we need to
solve the equation for $\hat \sigma_{\Delta n, m}^{-1}$ first, and then with
respect to $n$. We have:

$$
\begin{aligned}
\Phi^{-1}(1 - \beta) &= \Phi^{-1}(1 - \Phi(c - \delta\hat \sigma_{\Delta n, m}^{-1})) =\\\\
&= \Phi^{-1}(\Phi(-c + \delta\hat \sigma_{\Delta n, m}^{-1})) =\\\\
&= -c + \delta\hat \sigma_{\Delta n, m}^{-1}\\\\
\end{aligned}
$$

Recall from $(1)$ that we found that in order to limit the Type I error at
the desired significance level $\alpha$, the critical value $c$ must be equal
to $\Phi^{-1}(1 - \alpha)$. Therefore,

$$
\delta\hat \sigma_{\Delta n, m}^{-1} = \Phi^{-1}(1 - \alpha) + \Phi^{-1}(1 - \beta)
$$

Before presenting the final expression for $n$, note that $\hat \sigma_{\Delta
n, m}$ depends on $\bar X_n$ and $\bar Y_n$, which are observable only after
the experiment is completed. Thus we can define

$$
s^2 = \pi (1 - \pi)(n^{-1} + m^{-1}),\qquad \pi = (\pi_1 + r \pi_2) / (1 + r)
$$

as an estimate of $\hat \sigma_{\Delta n, m}^2$, where $\pi_1$ and $\pi_2$ are
hypothesized by the designer of the experiment and are such that $\pi_2 - \pi_1
= \delta$. In practice, $\pi_1$ is derived from existing available data (such
as conversion data from Google Analytics or a similar tracking tool), and
$\pi_2$ is calculated after defining the minimum effect of interest $\delta$.
Ideally, historical data should be:

* recent enough to be representative for the A/B test;
* without outliers (like holidays for an e-commerce site); and
* from a time period that is a multiple of the business cycle, which is
  frequently at least a week (to avoid seasonality effects).

Finally, after substituting $m = rn$, we can solve for $n$ and obtain

$$
\begin{align}
n = \frac{1 + r}{r}\frac{{\pi (1 - \pi) \left[\Phi^{-1}(1 - \alpha) + \Phi^{-1}(1 - \beta)\right]}^2}{\delta^2}
\end{align}
$$

Observe that the sample size $n$ required to attain power $1 - \beta$ and
maintain significance $\alpha$:

1. is directly proportional to the variance estimate $\pi (1 - \pi)$
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
n^\star = \frac{n}{4}{\left(1 + \sqrt{1 + \frac{2(1 + r)}{n r \delta}}\right)}^2
\end{align}
$$

which provides values very close to the exact sample size. The exact
calculation of the sample size requires an iterative procedure involving
binomial distributions, and thus it's rarely used in practice. $(3)$ or even
$(2)$ provide good approximations.

## Sample size for continuous responses
In online A/B testing there are several continuous variables of interest, like
the average order value (AOV) and average revenue per user (ARPU, defined as
the product between conversion rate and AOV).

These continous variables are not normally distributed, but if the observations
are independent, the sample means are normally distributed, thanks to the
Central Limit Theorem. To apply the theorem, we also require that these random
variables have finite mean and variance (as these are assumptions of the
Central Limit Theorem) $\mu_1, \mu_2$ and $\sigma_1^2, \sigma_2^2$. If they
represent order values, these assumptions are satisfied in most cases since
such distribution should have compact support (that is, the order values belong
to a bounded interval $[0, v]$ for some $v > 0$).

Therefore, if $X_i, i = 1, \ldots, n$ and $Y_j, j = 1, \ldots, m$ (with $m =
rn$ for some $r > 0$) are independent, continous random variables with finite
mean and variance, their sample means are normally distributed for sufficiently
large values of $n$ and $m$:

$$
\begin{aligned}
\bar X_n &= \frac 1n \sum_{i = 1}^n X_i \sim \mathcal N(\mu_1, \sigma_1^2 / n)\\\\
\bar Y_m &= \frac 1m \sum_{i = 1}^m Y_i \sim \mathcal N(\mu_2, \sigma_2^2 / m)
\end{aligned}
$$

We are interested in the one-tailed, non inferiority test

$$
\begin{aligned}
H_0&: \theta \leq 0\\\\
H_a&: \theta > 0
\end{aligned}\quad\quad\theta = \mu_2 - \mu_1
$$

with significance level $\alpha \in (0, 1)$, and power $1 - \beta \in (0, 1)$
at a minimum effect of interest $\theta = \delta > 0$.

As for the case of binary responses, we consider the difference $\Delta_{n, m}
= \bar Y_m - \bar X_n$ as an estimator for $\theta$ since $\Delta_{n, m} \sim
\mathcal N(\theta, \sigma_{\Delta n, m}^2)$ with $\sigma_{\Delta n, m}^2 =
\sigma_1^2/n + \sigma_2^2/m$.

The test statistic $T_{n, m} = \Delta_{n, m} / \sigma_{\Delta n, m}$ has unit
variance, but since $\sigma_1$ and $\sigma_2$ are unknown, we replace them with
the sample variances:

$$
\begin{aligned}
s_1^2 = \frac 1{n - 1} \sum_{i = 1}^n {(X_i - \bar X_n)}^2\\\\
s_2^2 = \frac 1{m - 1} \sum_{j = 1}^m {(Y_i - \bar Y_m)}^2
\end{aligned}
$$

Therefore, we consider the test statistic

$$
T^\prime_{n, m} = \frac{\Delta_{n, m}}{\hat \sigma_{\Delta n, m}},\qquad \hat
\sigma_{\Delta n, m}^2 = \frac{s_1^2}{n} + \frac{s_2^2}{m}
$$

This statistic is not normally distributed since the variance estimate in the
denominator does not depend exclusively on the sample means, but directly on
the observed data too. This is a source of additional variance in the test
statistic, which is distributed as a Student's t variable instead. In practice,
the difference is very small with sample sizes above $30$. Since in online A/B
testing we usually deal with much larger sample sizes, the normal approximation
is appropriate. Thus, in the following paragraphs we'll assume $T^\prime_{n, m}
\sim \mathcal N(\theta\hat \sigma_{\Delta n, m}^{-1}, 1)$.

The same reasoning as before shows that the critical value below which the null
hypothesis is rejected is $c = \Phi^{-1}(1 - \alpha)$. Analogous power
calculations lead to the same equation:

$$
\delta\hat \sigma_{\Delta n, m}^{-1} = \Phi^{-1}(1 - \alpha) + \Phi^{-1}(1 - \beta)
$$

Before we can derive the expression for the sample size, we have to find a
suitable replacement for $s_1^2$ and $s_2^2$, which are only known at the end
of the experiment as they depend on the observed data. The experiment designer
usually assumes that both variances are equal and estimates the value with
recent and representative historical data, if available. We shall denote this
estimate with the symbol $s_\star^2$.

After substituting $m = rn$, we can solve for $n$:

$$
\begin{align}
n = \frac{1 + r}{r}\frac{s_\star^2 {[\Phi^{-1}(1 - \beta) + \Phi^{-1}(1 - \alpha)]}^2}{\delta^2}
\end{align}
$$

## Single-pass algorithms
Once all observations have been collected, to calculate p-values (or confidence
intervals) and reach a conclusion, one must be able to calculate the sample
variance. A common method is to store all observations and carry out the
computation at the end, but sometimes that's not possible to due the size of
the datasets, performance considerations or other constraints. We'll now
present a few formulas to keep track of observed variance online, i.e. by
seeing the observed values only once. No storage is required in this case.

The case of binary responses is trivial, since the variance is a function of
the observed proportion. That is, just by keeping track of the number of
observations $n$ and number of conversions $k$, the sample proportion is $p = k
/ n$, and the sample variance is $p (1 - p)$.

The case of continous responses (such as AOV) is more delicate. [Welford
(1962)](https://doi.org/10.2307%2F1266577) discovered the following online
formulas that don't suffer from numerical instability as much as other naiver
approaches. The idea is to keep track of the sum of squares of differences from
the current mean, $M_{2, n} = \sum_{i = 1}^n {(x_i - \bar x_n)}^2$, and only
calculate the sample variance at the end, when needed:

$$
\begin{align}
\begin{aligned}
\bar x_{n + 1} &= \bar x_n + \frac{x_{n + 1} - \bar x_n}{n + 1}\\\\
M_{2, n + 1} &= M_{2, n} + (x_{n + 1} - \bar x_n)(x_{n + 1} - \bar x_{n + 1})\\\\
s_{n + 1}^2 &= \frac{M_{2, n + 1}}{n}
\end{aligned}
\end{align}
$$

The formulas above can be used to keep track of metrics like the AOV, but they
do not work with a metric like ARPU. The reason is that such formulas keep
track of the running average and update it whenever a new value is observed.
With ARPU, there are two updates:

1. when a new user is observed ($n \mapsto n + 1$ and $x_{n + 1} = 0$), and the
   formulas above are applied without change;
2. when a conversion from a user is observed.

The latter is equivalent to the following state change, where the state goes
from $n$ users with $k$ conversions (and thus $n - k$ non-conversions with
value $0$) to $n$ users and $k + 1$ conversions (and thus $n - k - 1$
non-conversions with value $0$):

$$
(x_1, \ldots, x_k, \underbrace{0, \ldots, 0}\_{n - k})
\mapsto (x_1, \ldots, x_{k + 1}, \underbrace{0, \ldots, 0}\_{n - k - 1})
$$

In this case, the updating formula for the sum of squared differences must be
slightly modified. I derived the following formula:

$$
\begin{align}
M_{2, n, k + 1} = M_{2, n, k} + \frac{n - 1}{n} x_{k + 1}^2 - 2x_{k + 1}\bar x_k
\end{align}
$$

When these single-pass algorithms are used to track the whole A/B test, it's no
longer possible to perform segment analysis after the experiment (i.e.
comparing subsets of each sample, like mobile users in A vs mobile users in B,
etc.).

However, if the segments of interest are defined before the experiment is
started, one can track each segment as if it were an individual test, and
combine the results at the end. That's accomplished with the following
group-combination formulas, due to [Chen et al.
(1979)](https://doi.org/10.1007/978-3-642-51461-6_3), which can be used to
combine the results from groups $A$ and $B$ and obtain the combined sample
mean and variance.

$$
\begin{align}
\begin{aligned}
n_{AB} &= n_A + n_B\\\\
\delta &= \bar x_B - \bar x_A\\\\
\bar x_{AB} &= \bar x_A + \delta \frac{n_B}{n_{AB}}\\\\
M_{AB} &= M_A + M_B + + \delta^2\frac{n_A n_B}{n_{AB}}
\end{aligned}
\end{align}
$$

Note that in these formulas $A$ and $B$ do not represent the experiment
variants, but rather two arbitrary subsets of the experiment samples.

The following sample Python code implements the formulas described above.

```python
import dataclasses

@dataclasses.dataclass
class VariantState:
    n: int = 0
    conversions: int = 0
    aov: float = .0
    ov_m2: float = .0
    arpu: float = .0
    rpu_m2: float = .0

    def track(self):
        '''Record the entrance of a new user in the A/B test.'''

        new_arpu = (self.n * self.arpu) / (self.n + 1)
        # mimic a SQL update, where all fields are updated at the same time
        # this makes it easy to translate this code to a SQL query
        self.n, self.arpu, self.rpu_m2 = (
            self.n + 1,
            new_arpu,
            self.rpu_m2 + self.arpu * new_arpu,
        )

    def conversion(self, amount):
        '''Record a conversion from a user that is part of the A/B test.'''

        new_aov = (self.conversions * self.aov + amount) / (self.conversions + 1)
        new_arpu = (self.n * self.arpu + amount) / self.n
        # mimic a SQL update, where all fields are updated at the same time
        # this makes it easy to translate this code to a SQL query
        (
            self.conversions,
            self.aov, self.ov_m2,
            self.arpu, self.rpu_m2
        ) = (
            self.conversions + 1,
            new_aov,
            self.ov_m2 + (amount - self.aov) * (amount - new_aov),
            new_arpu,
            (
                self.rpu_m2 + (self.n - 1) / self.n * amount**2 -
                2 * amount * self.arpu
            ),
        )

    @property
    def ov_var(self):
        '''Order value (OV) sample variance.'''

        if self.conversions < 2:
            return 0
        return self.ov_m2 / (self.conversions - 1)

    @property
    def rpu_var(self):
        '''Revenue per user (RPU) sample variance.'''

        if self.n < 2:
            return 0
        return self.rpu_m2 / (self.n - 1)

    def combine(self, other):
        '''Combine this state with another state.'''

        n_t = self.n + other.n
        c_t = self.conversions + other.conversions
        delta_ov = other.aov - self.aov
        delta_rpu = other.arpu - self.arpu
        ov_t = self.aov + delta_ov * other.conversions / c_t
        rpu_t = self.arpu + delta_rpu * other.n / n_t
        ov_m2 = self.ov_m2 + other.ov_m2 + delta_ov**2 * self.conversions * other.conversions / c_t
        rpu_m2 = self.rpu_m2 + other.rpu_m2 + delta_rpu**2 * self.n * other.n / n_t
        return VariantState(
            n=n_t,
            conversions=c_t,
            aov=ov_t,
            ov_m2=ov_m2,
            arpu=rpu_t,
            rpu_m2=rpu_m2,
        )
```

Example usage:

```python
mobile_a = VariantState()
mobile_b = VariantState()
desktop_a = VariantState()
desktop_b = VariantState()
mobile_a.track()
mobile_a.track()
mobile_b.track()
desktop_b.track()
desktop_b.track()
desktop_a.track()
mobile_a.conversion(53)
desktop_b.conversion(71)
mobile_b.track()
mobile_b.conversion(81)
desktop_a.conversion(29)
desktop_a.track()

mobile_a
# VariantState(n=2, conversions=1, aov=53.0, ov_m2=0.0, arpu=26.5, rpu_m2=1404.5)

desktop_a
# VariantState(n=2, conversions=1, aov=29.0, ov_m2=0.0, arpu=14.5, rpu_m2=420.5)

variant_a = mobile_a.combine(desktop_a)

mobile_b
# VariantState(n=2, conversions=1, aov=81.0, ov_m2=0.0, arpu=40.5, rpu_m2=3280.5)

desktop_b
# VariantState(n=2, conversions=1, aov=71.0, ov_m2=0.0, arpu=35.5, rpu_m2=2520.5)

variant_b = mobile_b.combine(desktop_b)

variant_a
# VariantState(n=4, conversions=2, aov=41.0, ov_m2=288.0, arpu=20.5, rpu_m2=1969.0)

variant_b
# VariantState(n=4, conversions=2, aov=76.0, ov_m2=50.0, arpu=38.0, rpu_m2=5826.0)

mobile_a.aov
# 53.0

mobile_a.ov_var
# 0

mobile_b.arpu
# 40.5

mobile_b.rpu_var
# 3280.5
```

## Summary
This post showed how to derive the sample size formulas for binary and
continous responses, and presented some useful formulas for online A/B test
tracking and variance computation.

Part IV will discuss the peeking problem in online A/B tests and a detailed
description of sequential tests as a possible solution.
