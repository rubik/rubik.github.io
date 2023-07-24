---
author: "Michele Lacchia"
title: "A/B testing fundamentals - part IV: sequential tests"
date: "2022-10-08"
tags: ["math", "statistics", "ab-tests"]
hasMath: true
draft: false
summary: "The peeking problem in A/B testing and the theory behind sequential
tests."
---

This series of posts explores the statistical framework (with a frequentist
approach) behind controlled trials with a focus on online A/B testing, and it
assumes some basic knowledge of calculus, random variables, and statistics.
In this post we'll describe the theory behind sequential testing approaches and
why they are needed in the first place.

### A/B testing fundamentals series
* [Part I: Introduction](/post/ab-testing-introduction/)
* [Part II: Statistical inference and hypothsis testing](/post/ab-testing-inference/)
* [Part III: Formulas for binary and continous responses](/post/ab-testing-formulas/)
* Part IV: Sequential tests (this post)
* Part V: Test evaluation and generalizability of test results
* Part VI: A/B testing calculators
* Part VII: Bayesian vs frequentist testing

## The peeking problem
In the previous posts we discussed Type I and Type II errors, and how they can
be controlled by the experiment designer by, respectively, calculating a
suitable test statistic threshold and a minimum number of users per experiment
arm. Crucially, the evaluation of the experiment is performed only at the end,
once the minimum sample size has been reached.

This is where the "peeking problem" comes in. It is essentially yielding to the
temptation of prematurely reacting to the results. Suppose you've launched your
new website's design A, design B, and you're eager to see which one performs
better. So, you start 'peeking' into the ongoing results. If you see design A
is outperforming, you may jump the gun and cut off the test early. The
fundamental problem is that early ‘winning’ results can often happen by mere
chance. You might inadvertently sabotage an accurate comparison by dropping one
of the versions too soon based on misleading early data.

To better understand the damage that early peeking can do, we'll run a
simulation of 10,000 A/A tests with a significance level of 95%. A/A tests are
trivial examples of A/B tests in which control and variant are exactly the same
and we shouldn't expect any difference in conversions. Since the significance
level is set at 95%, we should expect to conclude that there is a statistically
significant difference in 5% of the cases.
