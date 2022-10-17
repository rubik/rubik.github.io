#!/bin/sh

set -xe

~/exp/bin/jupyter nbconvert --output-dir "." --to "markdown" \
    --template "$(dirname "${BASH_SOURCE[0]}")/custom-markdown.tpl" \
    "$1"
