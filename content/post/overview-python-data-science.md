+++
author = "Michele Lacchia"
title = "An overview of great tools for data science"
tags = ["python", "javascript", "big-list"]
category = "posts"
date = "2016-11-06"
summary = "Overview of the most useful tools for data science: mainly Python and Javscript"
+++

<div class="img-with-copyright">
<img itemprop="image" title="A graph" src="/static/images/world-graph.jpg" />
<div class="copyright"><span>Travel vector designed by <a href="http://www.freepik.com/free-photos-vectors/travel">Freepik</a><span style="clear:both"></span></span></div>
</div>

This post presents an overview of the most useful tools for data
science-related tasks. It is not meant to be a complete list, but rather a
brief summary of the tools I've found repeatedly useful, with a couple new ones
that show great promise. The idea came from my last project ([Exploration of
Texas Death row data](/texas-death-row.html)), where I ended up using quite a
lot of Python packages, without having planned it from the start. This post is
meant to be a very syntetic reference, so that it can be useful to someone
comparing different solutions for a certain problem.

The overview will be comprised mainly of Python packages and some Javascript
tools in the visualization section, because that's what I am comfortable
working with. I also intend to start learning R in the near future, so maybe
there will be a follow-up with R libraries as well. Without further ado, let's
get started. This is what will be covered:

- [foundations (the SciPy stack)](#foundations)
- [scraping, data mining and NLP](#scr-nlp)
- [data visualization](#data-viz)
- [statistical modeling](#stat)
- [machine-learning](#ml)

---

<a name="foundations"></a>
## Foundations (the SciPy stack)

#### NumPy
Without doubt, [NumPy](http://www.numpy.org/) is the most foundamental package
for efficient scientific computing in Python. NumPy provides multi-dimensional
array objects and sophisticated broadcasting functions. Its core is written in
C, C++ and Fortran code for efficiency. Many packages in this list are built
upon NumPy, which is a must-know in the Python scientific computing landscape.

#### SciPy library
The [SciPy library](http://scipy.org/scipylib/index.html) is an extension to
NumPy that adds numerous algorithms for integration and optimization problems,
signal processing, statistics, linear algebra, as well as routines and objects
to work with sparse data. This library is huge, but it's well documented, with
explanations and examples.

#### Matplotlib
[Matplotlib](http://matplotlib.org/) is the standard Python plotting library
that produces publication-quality plots out of the box. It focuses on 2D
graphs, but it can produce 3D visualizations as well. It's pretty low-level,
meaning that plotting is not really straightforward. However, the library is
completely flexible, and you can customize it to make any kind of plot you
want.

#### Pandas
[Pandas](http://pandas.pydata.org/) is a library for operating with table-like
structures. Its powerful `DataFrame` object makes it easy to reshape, merge,
slice and perform computations on datasets. It can also read and write data to
a wealth of formats, including JSON, CSV and Excel.

#### Jupyter
[Project Jupyter](http://jupyter.org/) was born out of the IPython Project in
2014 as it evolved to support interactive data science and scientific computing
across all programming languages. Its notebook is a web application that allows
to create documents containing live code, equations, interactive visualizations
and text. It's most commonly used with the IPython kernel, but it's not
restricted to the Python language.

I've found the notebook to be extremely useful to explore datasets and perform
data cleaning and visualization. In fact, when presented with a new dataset, I
always fire up a notebook and delve into it.

<a name="scr-nlp"></a>
## Scraping, data mining and natural language processing (NLP)
#### Scrapy
[Scrapy](https://scrapy.org/) is a Python library to extract data from
websites. It builds on [Twisted](https://twistedmatrix.com/trac/) to schedule
asynchronous requests, resulting in extremely fast crawlers. It's also very
easy to extend. Scrapy requires a whole project to run, but it provides command
to build them from base templates (`scrapy startproject`, `scrapy genspider`),
so it's both easy and quick to get up and running.

Scrapy is my tool of choice when I have to scrape data and I have yet to
encounter something that it cannot do. For example, you can plug
[Splash](http://splash.readthedocs.io/en/stable/) to render Javascript, or
[Crawlera](https://crawlera.com/) (paid service) to route requests through a
pool of proxies, which are managed automatically.

#### Stocktalk
[Stocktalk](https://github.com/anfederico/Stocktalk) is a data collection
toolkit to scrape stock data from social media and explore it. The library can
also perform sentiment analysis over the collected data.

#### NLTK
[NLTK](http://www.nltk.org/), or Natural Language Toolkit, is a set of
libraries to work with human language data: it supports tokenization, stemming,
tagging, parsing and classification. It also includes over 50 corpora and
lexical resources. I found its documentation to be lacking in certain areas,
but there is also a [book](http://www.nltk.org/book/), written by the creators
of NLTK, which provides an introduction to NLP with Python.

#### Textblob
[Textblob](https://textblob.readthedocs.io/en/dev/) simple and modern API for
many NLP tasks such as tagging, sentiment analysis, classification and
translation, among others.

I have used it mainly for sentiment analysis, and it provides two analyzers,
which are useful in different contexts. The first one is TextBlob's own
analyzer, which works by querying a sentiment lexicon. Each word in the lexicon
has polarity and subjectivity scores, along with the intensity of each word.
The score of a sentence is the aggregate of the single word scores. The
analyzer is capable of factoring in negations and intensity modifiers. The
other one is based on NLTK's `NaiveBayesClassifier`, which is a model trained
on a corpus of movie reviews. In my own projects, I've found that the second
one gives better results when the text is composed of actual reviews or when
there is similar lexicon involved. On the other hand, TextBlob's own analyzer
fares better in more general contexts.

#### Gensim
[Gensim](https://radimrehurek.com/gensim/) is a Python library that focuses on
semantic analysis, and mainly for topic modeling. It's quite comprehensive:
including several model (LDA, LSI, TF-IDF, LogEntropy, HDP, etc.) and also
functions for summarization and similarity queries. Gensim was built with large
corpora in mind, and it's therefore very efficient, featuring ad-hoc routines
for distributed computing as well.

#### spaCy.io
[spaCy.io](https://spacy.io) is a new library for "industrial-strength NLP"
that claims to be the fastest in the world. It's a very comprehensive library,
and it allows seamless interoperability with the other Python libraries in the
NLP space. I have yet to try it, but it looks really promising.

<a name="data-viz"></a>
## Data visualization
#### seaborn
[Seaborn](http://seaborn.pydata.org/index.html) is based on Matplotlib's core
and adds several features (heat maps, violin plots, scatter plots with
marginals, etc.). Seaborn focuses on statistical visualization. Its default
styles are also much more sophisticated than Matplotlib's default ones, and
they are better looking too.

#### Altair
[Altair](https://altair-viz.github.io/) is a declarative visualization library
for Python, based on Vega-Lite (see below). Its API is elegant and concise, and
that's what I like about Altair: it lets you generate complex charts with very
few lines of code. Actually, all Altair does is generate JSON that is then fed
to the Javascript library Vega-Lite. It's very easy to display Altair plots in
Jupyter notebooks.

#### Bokeh
[Bokeh](http://bokeh.pydata.org/en/latest/) is a Python visualization library
that targets the browser and focuses on interactivity. Its goal is to provide
elegant and concise construction of graphics in the style of D3.js (see below).
It's very easy to embed Bokeh graphics in Jupyter notebooks.

#### Folium
[Folium](https://folium.readthedocs.io/en/latest/) is a library that brings the
mapping strengths of the Leaflet library to Python. It is capable of
producing interactive maps of different kinds, with different tiles. It's very
easy to embed Folium maps in Jupyter notebooks.

Leaflet is a Javascript library for the creation of mobile-friendly interactive
maps. It is designed with simplicity and performance in mind, and its code is
exceptionally small, but extensible.

#### gmaps
[gmaps](http://jupyter-gmaps.readthedocs.io/en/latest/) is a Jupyter extension
for embedding interactive Google Maps in Jupyter notebooks. It supports various
layer types: markers and symbols, heatmaps and weighted heatmaps. It's very
easy to use, but it requires an API key from Google.

#### D3.js (Vega, Vega-lite)
[D3.js](https://d3js.org/) is a giant in Javascript's visualization space. It
is a library that binds data to the document model (DOM), and then applies
data-driven transformations. It's very fast and emphasizes web standards.

[Vega](https://vega.github.io/vega/) is a visualization grammar that leverages
D3.js in its implementation and generates graphics from JSON.
[Vega-lite](https://vega.github.io/vega-lite/) is a high-level visualization
grammar that can be compiled to Vega. Vega-lite specifications are usually
succient and expressive, with supports for data transformations and visual
transformations.

<a name="stat"></a>
## Statistical modeling
#### statsmodels
[Statsmodels](http://statsmodels.sourceforge.net/) is the standard library for
estimating statistical models and performing statistical tests in Python. It is
fully-featured and among other things, it includes: linear regression models,
generalized linear models, discrete choice models and models for time series
analysis. The library also exposes plotting functions that work on top of
Matplotlib. The development appears to have been slowed down, but it's still
ongoing.

#### tsfresh
[tsfresh](http://tsfresh.readthedocs.io/en/latest/) is a new Python library
that allows automatic extraction of hundreds of features from time series. At
the time of writing, tsfresh is very young, being only 12 days old.  However,
it's extremely useful and quickly gained a lot of traction.

<a name="ml"></a>
## Machine learning
#### scikit-learn
[scikit-learn](http://scikit-learn.org/stable/) is the most popular machine
learning library for Python. It is built on NumPy and SciPy, and it's
fully-featured, including a broad range of models for classification,
regression, clustering, dimensionality reduction, and lots of utility classes
for preprocessing.

As a library, scikit-learn really stands out. It's actively developed and has
an outstanding documentation, which couples an API reference with a user guide.
Among scikit-learn's contributors there are many machine learning experts.

#### Tensorflow
[Tensorflow](https://www.tensorflow.org/) is a machine learning toolkit
developed by Google, with a C++ core and a Python frontend. It features
automatic differentiation and it's particularly ported: it can be used on
mobile devices or large distributed systems with little modification to the
code. With Tensorflow, one defines the neural network in a symbolic way, or how
the data flows.

#### Theano
[Theano](http://www.deeplearning.net/software/theano/) uses NumPy-like syntax
to optimize and evaluate mathematical expressions. It also supports automatic
differentiation. What sets Theano apart is that it takes advantage of the
computer's GPU. Theano's speed makes it especially valuable for deep learning
and other computationally complex tasks.

#### Lasagne
[Lasagne](http://lasagne.readthedocs.io/en/latest/) is a lightweight library
for building and training neural networks in Python. Lasagne uses Theano for
its computation and therefore can make use of the GPU.

#### scikit-neuralnetwork
[sknn](http://scikit-neuralnetwork.readthedocs.io/en/latest/index.html) is a
Python library that implements multi-layer perceptrons and is compatible with
scikit-learn's API. The library supports both regressors and classifiers and
uses Lasagne and Theano behind the scenes.
