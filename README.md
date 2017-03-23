# python-before-push
A single script to run before push/commit of Python project. It will use common testing tools to check for potential errors. It can be used as git hook as well. The script is ready to use out of the box, allowing to quickly checks new project from the beginning. The script is indended to be self-contained and easy to distribute.

## Motivation

When working on several projects, I found myself using the same tools over and over again:

* Unit tests
* Coverage tests
* Doctests
* PyLint

Some of them don't integrate with each other, so I had to run them manually. The also have number of options that I just never remembered and config files were usually obsolete or I lost them completely. I ended up putting all of it into one script. So why not to make it available for everone?

## What does it do

On first run, the script creates a virtualenv, activates it, installs there all dependencies for the tests, as well as all project dependencies from the requirements.txt file in the project root. On subsequent runs it reuses that environment.

By default, the script will find all \*.py files in the project and all tests in the test folder. Then it runs:

* Nose test with coverage and rednose plugin
* Pylint checking for Fatals and Errors
* Mypy for type checks

# Usage guide

**Run as:** `test.sh [options]`

 Option             | Description
------------------- | ------------------------------------------------
`-h`, `--help`          | Displays this help.
`-p`, `--pylint`        | Run PyLint.
`-t`, `--types`         | Run Mypy for checking types usage.
`-n`, `--nose`          | Run unit and coverage tests with Nose.
`-o`, `--browser`       | Open coverage results in browser.
`-ni`, `--noinstall`    | Do not install requirements and dependencies.
`-nv`, `--novirtualenv` | Do not create/use virtualenv.
`-pe`, `--python`       | Specify python executable to use for virtualenv.

## Manual use

1. Add test.sh to your repository root.
1. Modify test.sh to your specific needs. By default all checks are performed.
1. Run test.sh to check for errors.

## As a Git hook

TODO

## TODOs
- [ ] Turn into Python script
- [ ] Make cross-platform
- [x] Run in a separate virtualenv
- [x] Install all requirements automatically
- [x] Generate pylint config file
- [x] Generate coverage config file
- [x] Use nosetest instead of manual search for tests
- [x] Use Mypy
