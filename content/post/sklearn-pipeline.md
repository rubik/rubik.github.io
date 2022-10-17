+++
author = "Michele Lacchia"
title = "Why you should use scikit-learn's Pipeline object"
tags = ["python", "sklearn", "machine-learning"]
date = "2016-11-01"
hasCode = true
hasDisqus = true
summary = "Making the case for sklearn's Pipeline object"
+++

<figure>
    <img itemprop="image" title="A pipeline" src="/static/images/pipes.jpg" />
    <div class="copyright">
        Copyright:&nbsp;<a href="https://www.istockphoto.com/portfolio/visualgo">visualgo</a>.
    </div>
</figure>

Machine learning models learn from data. It is crucial, however, that the data
you feed them is specifically preprocessed and refined for the problem you want
to solve. This includes data cleaning, preprocessing, feature engineering, and
so on.

Very often, when presented with a dataset, I would fire up a Jupyter notebook
and start exploring it interactively. The notebook is great for that task, but
after a while I ended up with code that is a total mess in the global
namespace.

Then I read about scikit-learn's [`Pipeline`][pipeline-doc] object, a utility
that provides a way to automate a machine learning workflow.  It works by
allowing several transformers to be chained together. One can also add an
estimator at the end of the pipeline. Data flows from the start of the pipeline
to its end, and each time it is transformed and fed to the next component. A
`Pipeline` object has two main methods:

- `fit_transform`: this same method is called for each transformer and each time
  the result is fed into the next transformer;
- `fit_predict`: if your pipeline ends with an estimator, then as before the
  data is transformed until it arrives at the last step, where it is fed into
  the estimator and `fit_predict` is called on the estimator.

Sometimes data flow is not linear, and that's where [`FeatureUnion`][fu-doc]
comes in. A `FeatureUnion` is itself a transformer, which combines multiple
transformers. During fitting, they are fitted independently, while for the
transformation, each component of the union is applied in parallel. Where all
the results have been collected, they are concatenated into a single vector.

### Example
The excellent scikit-learn documentation has loads of examples. Let's take a
look at the [Anova SVM pipeline][anova-svm]. The relevant part is the
following:

```python
# ANOVA SVM-C
# 1) anova filter, take 3 best ranked features
anova_filter = SelectKBest(f_regression, k=3)
# 2) svm
clf = svm.SVC(kernel='linear')

anova_svm = make_pipeline(anova_filter, clf)
anova_svm.fit(X, y)
anova_svm.predict(X)
```

The function
[`make_pipeline`](https://scikit-learn.org/stable/modules/generated/sklearn.pipeline.make_pipeline.html)
is just a wrapper around the class, and it allows to compose transformers and
estimators without specifying a name for each one. The above code is equivalent
to the following:

```python
# ANOVA SVM-C
# 1) anova filter, take 3 best ranked features
anova_filter = SelectKBest(f_regression, k=3)
# 2) svm
clf = svm.SVC(kernel='linear')

anova_filter.fit(X, y)
X_ = anova_filter.transform(X)
clf.fit(X_, y)
clf.predict(X_)
```

In this little example, we only have one transformer and one estimator, but the
difference in readability and clarity is significantly in favour of the first
version. In what follows, I'll explain how I got scikit-learn and pandas
working together in a pipeline with many more transformers.

### Pipelines and Pandas dataframes
Unfortunately, scikit-learn's API expects Numpy arrays. If you feed a dataframe
into a pipeline, you will get a Numpy array out of it. Other times, as it is
the case with `FeatureUnion`, it will not work as expected. It would be much
better if one could get a dataframe out of the pipeline. Right now various
efforts are in place to allow a better sklearn/pandas integration, namely:

- the PR [`scikit-learn/3886`](https://github.com/scikit-learn/scikit-learn/pull/3886),
    which at the time of writing is still a work in progress;
- the package [`sklearn-pandas`](https://github.com/paulgb/sklearn-pandas).

I tried `sklearn-pandas` but it doesn't quite do what I wanted: it provides a
way to map `DataFrame` columns to transformations. Most of the time, however, I
construct a pipeline of transformers and I want to receive a `DataFrame` as
input or output. For this reason I wrote a custom transformer that does
precisely this:

```python
from sklearn.base import TransformerMixin

class NoFitMixin:
    def fit(self, X, y=None):
        return self

class DFTransform(TransformerMixin, NoFitMixin):
    def __init__(self, func, copy=False):
        self.func = func
        self.copy = copy

    def transform(self, X):
        X_ = X if not self.copy else X.copy()
        return self.func(X_)
```

It accepts a function as argument and the transformed data is simply its return
value. The `copy` keyword argument is there to prevent a double copying: if the
function itself returns a new `DataFrame`, then there's no need to copy it.

The only problem arises when using `FeatureUnion`: it does not concatenate the
results into a `DataFrame`. I wrote a custom class for this case as well:

```python
from sklearn.pipeline import Pipeline, FeatureUnion, _transform_one
from sklearn.externals.joblib import Parallel, delayed

class DFFeatureUnion(FeatureUnion):
    def fit_transform(self, X, y=None, **fit_params):
        # non-optimized default implementation; override when a better
        # method is possible
        if y is None:
            # fit method of arity 1 (unsupervised transformation)
            return self.fit(X, **fit_params).transform(X)
        else:
            # fit method of arity 2 (supervised transformation)
            return self.fit(X, y, **fit_params).transform(X)

    def transform(self, X):
        Xs = Parallel(n_jobs=self.n_jobs)(
            delayed(_transform_one)(trans, X, None, weight)
            for _, trans, weight in self._iter())
        return pd.concat(Xs, axis=1, join='inner')
```

This is an example showing how they can be used:

```python
pipeline = Pipeline([
    ('ordinal_to_nums', DFTransform(_ordinal_to_nums, copy=True)),
    ('union', DFFeatureUnion([
        ('categorical', Pipeline([
            ('select', DFTransform(lambda X: X.select_dtypes(include=['object']))),
            ('fill_na', DFTransform(lambda X: X.fillna('NA'))),
            ('one_hot', DFTransform(_one_hot_encode)),
        ])),
        ('numerical', Pipeline([
            ('select', DFTransform(lambda X: X.select_dtypes(exclude=['object']))),
            ('fill_median', DFTransform(lambda X: X.fillna(X.median()))),
            ('add_features', DFTransform(_add_features, copy=True)),
            ('remove_skew', DFTransform(_remove_skew, copy=True)),
            ('find_outliers', DFTransform(_find_outliers, copy=True)),
            ('normalize', DFTransform(lambda X: X.div(X.max())))
        ])),
    ])),
])
```

The above pipeline splits the `DataFrame` into categorical and numerical
columns, applying different transformation to each. The columns are
concatenated into a `DataFrame` at then end of the `DFFeatureUnion`.

The resulting code is well organized and very easy to understand. It's also
extremely easy to add or remove steps to/from the pipeline.

**UPDATE (Oct 28, 2017)**: As of scikit-learn v0.19.0, the function signature
of the undocumented function `_transform_one` changed, and the code of
`DFFeatureUnion` was updated accordingly (thanks to Paulo Cheadi Haddad Filho
for pointing it out).

**UPDATE (Dec 02, 2019)**: As of scikit-learn v0.21.0, the function signature
of the function `_transform_one` changed once again, and the code of
`DFFeatureUnion` was updated accordingly (thanks to Григорий Гусаров for
pointing it out).

[pipeline-doc]: https://scikit-learn.org/stable/modules/pipeline.html#pipeline
[fu-doc]: https://scikit-learn.org/stable/modules/compose.html#featureunion-composite-feature-spaces
[anova-svm]: https://scikit-learn.org/stable/auto_examples/feature_selection/plot_feature_selection_pipeline.html#sphx-glr-auto-examples-feature-selection-plot-feature-selection-pipeline-py
