# python-before-push

A single script to run before push/commit of Python project. It will use common testing tools to 
check for potential errors. It can be used as git hook as well. The script is ready to use out of 
the box, allowing to run checks on a new project from the beginning. The script is intended to be self-contained and easy to distribute.

[![Build Status](https://travis-ci.org/radeklat/python-before-push.svg?branch=master)](https://travis-ci.org/radeklat/python-before-push)

## Motivation

When working on several projects, I found myself running the same tools over and over again:

* Unit tests using [pytest](https://docs.pytest.org/en/latest/)
* Coverage test using [coverage](https://coverage.readthedocs.io/en/coverage-4.4.1/) and [pytest-cov](https://github.com/pytest-dev/pytest-cov)
* [PyLint](https://www.pylint.org/) to perform static analysis
* [MyPy](http://mypy.readthedocs.io/en/latest/) to check type hints
* [Black](https://black.readthedocs.io/en/stable/) to format code before every commit and after every test.
* [Safety](https://github.com/pyupio/safety) to check dependencies in requirements.txt for security issues.

Some of them don't integrate with each other, so I had to run them manually. They also have 
number of options that I just never remembered and config files were usually obsolete or I 
lost them completely. I ended up putting all of it into one script. So why not to make it 
available for everyone?

## What does it do

On first run, the script creates a [virtualenv](https://pypi.python.org/pypi/virtualenv), activates it, installs there all dependencies for the tests, as well as all project dependencies from the [requirements.txt](https://pip.readthedocs.io/en/1.1/requirements.html) file in the project root. On subsequent runs it reuses that environment and only installs new versions of packages (if fixed version is not used).

The script can fetch configuration files (with coding style rules for example) from a different Github repository (private ones are supported as well). It also updates itself with newer versions. So you can keep the same coding standard up-to-date in multiple repositories.

By default, the script will find all `*.py` files in the sources folder (default is `src`, defined in `SOURCES_FOLDER`) and all tests in the test folder (default is `test`, defined in `TESTS_FOLDER`). Then it runs the following checks:

* All unit tests
* Static code analysis (code formatting and complexity, code smells)
* Type checks
* TODO checks and count
* Black to format the code
* Safety to check requirements for possible security vulnerabilities
* Optionally opens coverage test results in default web browser. There results are interactive
  (allow sorting and inspecting files individually).

# Usage guide

1. Add `test.sh` to your repository root.

1. Define what you want to check. Generate an RC file with `./test.sh --generate-rc-file` and change values in the resulting `.testrc` file. By default all checks are performed.

1. Run `test.sh` to check for errors: \
   `./test.sh`

1. Use additional options to fine-tune what is being run. See help: \
   `./test.sh -h` or `./test.sh --help`

## Dependencies

Only the underlying tools. The script will check if they are installed and prompt you to add them if they are missing.
