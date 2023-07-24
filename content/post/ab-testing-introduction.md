---
author: "Michele Lacchia"
title: "A/B testing fundamentals - part I: introduction"
date: "2022-10-08"
tags: ["math", "statistics", "ab-tests"]
draft: false
summary: "Introduction to a new series on A/B testing fundamentls."
---

A/B testing, often referred to as "split testing", is a randomized
experimentation technique used by organizations to determine the most effective
version of a web page, a user interface, a marketing email, or any other
customer-facing element. By displaying two or more different versions to
different user groups concurrently, it's possible to measure which version has
the most successful outcome, typically measured in conversion rates or average
revenue per user (ARPU).

This series will provide an in-depth exploration of A/B testing, starting from
the fundamental statistical concepts underpinning the technique, to more
specific topics like the formulas and algorithms applied when dealing with
binary (e.g customer churn, click rates etc.) and continuous data types (e.g
session duration, revenue per user etc.). In later parts, we will delve into
more advanced topics like group sequential tests, which allow for stopping the
experiment early based on interim results.

We will also discuss practical aspects such as how to draw reliable and
generalizable conclusions from test results, especially when faced with
confounding variables or external factors. To help you conduct A/B tests more
efficiently and correctly, we'll introduce some A/B testing calculators and
demonstrate how to use them.

Towards the end of the series, we will introduce Bayesian testing and compare
it to its frequentist counterpart. The two are fundamentally different
philosophical approaches to performing A/B tests both with their own merits and
demerits.

This series does presume a foundational understanding of random variables, and
statistics as it delves into the statistical backbone of A/B testing. For those
who do not possess the requisite mathematical knowledge, parts II and VI might
prove to be more accessible and useful. Part II provides an introduction to
statistical inference and hypothesis testing, fundamental tools in A/B testing,
while Part VI covers A/B testing calculators, a more practical aspect of A/B
testing. The emphasis throughout is on building a robust statistical
understanding of A/B testing.

### A/B testing fundamentals series
* Part I: Introduction (this post)
* [Part II: Statistical inference and hypothsis testing](/post/ab-testing-inference/)
* [Part III: Formulas for binary and continous responses](/post/ab-testing-formulas/)
* [Part IV: Sequential tests](/post/ab-testing-sequential/)
* Part V: Test evaluation and generalizability of test results
* Part VI: A/B testing calculators
* Part VII: Bayesian vs frequentist testing
