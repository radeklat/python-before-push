# python-before-push
A single script to run before push/commit of Python project. It will use common testing tools to check for potential errors. It can be used as git hook as well.

## Motivation

When working on several projects, I found myself using the same tools over and over again:

* Unit tests
* Coverage tests
* Doctests
* PyLint

Some of them don't integrate with each other, so I had to run them manually. So I ended up putting them into one script. So why not to make it available for everone?

## What does it do

By default, the script will find all \*.py files in the project and run on them the tools listed above. It is possible to exclude files/folder if you don't want them to be checked.

# Usage guide

## Manual use

1. Add test.sh to your repository path
1. Modify test.sh to your specific needs. By default all checks are performed.
1. Run test.sh to check for errors

## As a Git hook

TODO

## TODOs
* Turn into Python script
* Make cross-platform
* Run in a separate virtualenv
* Install all requirements automatically
* Generate pylint config file
* Generate coverage config file
* Use nosetest instead of manual search for tests
* Use Mypy
