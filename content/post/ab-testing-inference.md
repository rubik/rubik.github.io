---
author: "Michele Lacchia"
title: "A/B testing - part I: statistical inference and hypothesis testing"
date: "2022-10-08"
tags: ["math", "statistics", "ab-tests"]
hasmath: true
summary: "Statistical framework underlying online A/B testing using a frequentist approach to hypothesis testing."
---

A/B testing, also referred to as "split testing", is a randomized
experimentation process in which two or more versions of a variable (web page,
page element, etc.) are shown to different segments of website visitors at the
same time to determine which version leaves the maximum impact and drives
business metrics, most commonly conversion rate and average revenue per user
(ARPU).

This series of posts explores the statistical framework behind controlled
trials with a focus on online A/B testing, and it assumes some basic knowledge
about calculus, random variables, and statistics. In this first post we'll
describe the foundation to A/B testing: statistical inference through
hypothesis testing.

#### A/B testing series
* Part I: Statistical inference and hypothsis testing (this post)
* [Part II: Formulas for binary and continous responses](/post/ab-testing-formulas/)
* Part III: Streaming algorithms and segment analysis
* Part IV: Group sequential tests
* Part V: Multivariate tests

## Hypothesis testing
Statistical inference is the application of statistical methods to learn the
characteristics of a population (a complete collection of objects of interest),
from a limited sample (a series of observations).

Hypothesis testing is a form of statistical inference that uses representative
samples to evaluate two mutually exclusive hypotheses. First, a tentative
assumption is made about the parameter or distribution of interest. This
assumption is called the "null hypothesis" and is denoted by $H_0$. By defining
the null hypothesis, the alternative hypothesis, denoted $H_a$, is
automatically defined: it is the opposite of what is stated in the null
hypothesis. The hypothesis-testing procedure works as follows:

1. from the sample data we calculate a **test statistic**, a numerical quantity
   that summarizes the properties of the sample. The test statistic assesses
   how consistent the sample is with the null hypothesis;
2. the test statistic is converted into a **p-value**, which is the probability
   of obtaining test results as the ones observed in the sample, or more
   extreme, assuming the null hypothesis is true. In a sense, a p-value
   represents how _surprising_ the test results are under the null hypothesis.
   Lower p-values represent stronger evidence against the null hypothesis.
3. If the p-value is lower than a pre-determined threshold $\alpha$, $H_0$ is
   rejected.
4. If $H_0$ is rejected, we accept the alternative hypothesis $H_a$, otherwise
   we accept $H_0$.

A result is said to be _statistically significant_ if the calculated p-value is
lower than the threshold $\alpha$.

### Types of hypotheses
A null hypothesis can either be a _point_ hypothesis or a _composite_
hypothesis. The former is a hypothesis that cover only a single value out of
all the possible parameter values. A common example for a certain parameter
$\theta$ is:

$$
\begin{cases}
H_0:& \theta = 0\\\\
H_a:& \theta \neq 0
\end{cases}
$$

where the null hypothesis is that parameter $\theta$ is equal to zero, and the
alternative hypothesis covers the complementary set of possible parameter
values.

A composite null hypothesis covers multiple values from the parameter space,
e.g.:

$$
\begin{cases}
H_0:& \theta \leq 0\\\\
H_a:& \theta > 0
\end{cases}
$$

where $\theta$ for example could be a difference in coversion rates, between
variant B and the control in an A/B test.

Testing a composite null hypothesis is what usually makes the most sense in an
online A/B test, as we are interested in detecting and estimating effects in
only one direction: e.g. an increase in conversion rate or average revenue per
user. In fact, using a point null hypothesis would require a larger sample size
for the same significance level, and running a test so long as to detect a
statistically significant negative effect can be harmful overall for the
business.

## Errors
Since hypothesis tests derive their conclusions from a sample, and therefore
from limited information, the possibility of errors must be considered. There
are two kinds of errors one must guard against in designing a hypothesis test.

The first, called the **Type I error**, consists in rejecting the null
hypothesis $H_0$ when it's in fact true. For example, when comparing two
conversion rates for equality, it'd be equivalent to declaring that the
difference between them is real when in fact there's no difference. This kind
of error has been given the greater amount of attention in practice. It is
typically guarded against by designing a test in such a way that Type I errors
have a low probability of occurring. This probability is called
**significance** and usually denoted by the symbol $\alpha$. It's often set to
low values such as $0.01$ or $0.05$. The probability $1 - \alpha$ is called
**confidence**.

This kind of control is not totally adequate, because a literal Type I error
probably never occurs in practice. The reason is that the two populations
giving rise to the observed samples will inevitably differ to some extent,
albeit possibly by a trivially small amount. No matter how small the difference
is between the two underlying populations, provided it is nonzero, samples of
sufficiently large size can guarantee statistical significance. Assuming that
an experiment designer desires to declare significant only differences that are
of practical importance, and not merely differences of any magnitude, they
should impose the additional constraint of not employing sample sizes that are
larger than they need to guard against the second kind of error.

The second kind of error, called the **Type II error**, consists in accepting
the null hypothesis when the alternative hypothesis is in fact true. For
example, when comparing conversion rates, it would consist in failing to
declare the two conversion rates significantly different when they are actually
different. As just pointed out, such an error is not serious when the
conversion rates are only trivially different. It becomes serious only when
they differ to an important extent. The practical control over the Type
II error must therefore begin with the experiment designer specifying just what
difference is of sufficient importance to be detected, and must continue with
the designer specifying the desired probability of actually detecting it. We'll
denote the minimum effect of interest (MEI) with the symbol $\delta$; the
probability of detecting it, $1 - \beta$, is called the **power** of the test.
The quantity $\beta$ is the probability of failing to find the specified
difference to be statistically significant.

<figure>
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
    <figcaption>
        <strong>Fig. 1</strong>&emsp;A table from <a
        href="https://en.wikipedia.org/wiki/Type_I_and_type_II_errors"
        rel="noopener noreferrer" target="_blank">Wikipedia</a> that nicely
        summarizes the types of errors that can be made when performing a
        hypothesis test.
    </figcaption>
</figure>

## Operating procedure
With the basic definitions in place, we can now define the full operating
procedure for a statistically sound test:

1. we formulate a hypothesis to be tested, and we select the appropriate
   statistical test;
2. we choose a target significance level $\alpha \in (0, 1)$ to control Type I
   errors;
3. we choose a target power $1 - \beta \in (0, 1)$ to control Type II errors,
   along with a minimum effect of interest (MEI) $\delta$;
4. we calculate the sample size per variant required to achieve the target
   power;
5. we collect data until the target sample size is met;
6. we calculate a p-value for each variant;
7. we conclude the test by accepting or rejecting the null hypothesis.

## Types of tests
TODO

## p-values and uncertainty
As mentioned above, the p-value of a test is the probability of obtaining test
results as the ones observed in the sample, or more extreme, assuming the null
hypothesis is true.

An important observation about the definition of the p-value is that it
mentions the null hypothesis as an assumption only. The p-value is a
caracteristic of the testing procedure and is calculated from the sample data.
It does not, directly or indirectly, define the probability of a hypothesis
being true or false. Given the frequent misuse of this concent, it's important
to stress that a p-value **is not**:

* the probability of the outcome being "due to chance" (whatever that means);
* the probability of the null hypothesis being true;
* the probability of the alternative hypothesis being true; or
* the probability of making a wrong decision.

There are three possible scenarios in which a very low p-value below the
significance threshold (e.g. $0.0001$) can be observed, all logically valid:

1. the null hypothesis is not true;
2. the null hypothesis is true, but a very rare outcome is observed;
3. the statistical model is inadequate, and the calculated p-value is not an
   actual p-value.

Most of the time we'll interpret a low p-value as evidence that the null
hypothesis is not true. However, the other two possibilities can never be ruled
out entirely. Granted, provided the experiment was designed properly, scenario
\#3 is very unlikely, and by setting a significance level we accept that we'll
make the wrong decision a certain fraction of times over the long run. It's
therefore logical to interpret low p-values according to scenario \#1 above in
practice, although the other two possibilities should not be forgotten.

Understanding statistical uncertainty is key for implementing a data-driven
approach. Even when statistical methods are employed properly, it doesn't mean
that a conclusion reached through the experimental procedure is irrefutable,
certain, or unquestionable. Statistics is the science of estimating
uncertainty. It cannot lead to certain conclusions, it can only suggest how
close we are to having irrefutable evidence. Statistical methods provide means
to estimate risk and control it as we deem appropriate.

## Summary
TODO

The [next post](/post/ab-testing-formulas/) describes in detail how the
formulas for the target sample size is derived in some common scenarios.
