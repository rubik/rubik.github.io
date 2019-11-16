+++
author = "Michele Lacchia"
title = "A complete Kubernetes tutorial, part II: deploying an application"
tags = ["kubernetes", "containers"]
category = "posts"
date = "2019-11-13"
summary = "A complete Kubernetes tutorial series covering all the basics."
+++

## Preface
The goal of this tutorial series is to allow the reader to start deploying on
Kubernetes with a basic understanding of Kubernetes architectural principles.
If you don't know what Kubernetes is or how it works, I highly recommend
reading [part I](/post/kubernetes-tutorial/) of this series.

In this post, we dive into a practical example. We'll see many of the concepts
explained in the first part of the series. This is the structure of the series:

* Part I: [Kubernetes basic concepts](/post/kubernetes-tutorial/)
* Part II: A practical and realistic example (this post)
* Part III: Best practices (still WIP)

## Introduction
The application that we will deploy is a simple web application that, while
minimal, is supposed to mimic a real-world architecture.
