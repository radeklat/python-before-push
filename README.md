# python-before-push
A single script to run before push/commit of Python project. It will use common testing tools to 
check for potential errors. It can be used as git hook as well. The script is ready to use out of 
the box, allowing to quickly checks new project from the beginning. The script is intended to be 
self-contained and easy to distribute.

## Motivation

When working on several projects, I found myself using the same tools over and over again:

* Unit tests using [Nose](http://nose.readthedocs.io/en/latest/)
* Coverage test using [Nose plugin](http://nose.readthedocs.io/en/latest/plugins/cover.html) 
  or [coverage](https://coverage.readthedocs.io/en/coverage-4.4.1/)
* Doctests using [Nose plugin](http://nose.readthedocs.io/en/latest/plugins/doctests.html) 
  or Python's [doctest module](https://docs.python.org/3/library/doctest.html)
* [PyLint](https://www.pylint.org/) to perform static analysis
* [MyPy](http://mypy.readthedocs.io/en/latest/) to check type hints
* [SonarQube](https://www.sonarqube.org/) when the project is large and multiple people are 
  working on it or when there is CI available

Some of them don't integrate with each other, so I had to run them manually. The also have 
number of options that I just never remembered and config files were usually obsolete or I 
lost them completely. I ended up putting all of it into one script. So why not to make it 
available for everyone?

## What does it do

On first run, the script creates a [virtualenv](https://pypi.python.org/pypi/virtualenv), 
activates it, installs there all dependencies for the tests, as well as all project 
dependencies from the [requirements.txt](https://pip.readthedocs.io/en/1.1/requirements.html) 
file in the project root. On subsequent runs it reuses that environment and only installs new 
versions of packages (if fixed version is not used).

By default, the script will find all `*.py` files in the sources folder (default is `src`, defined in `SOURCES_FOLDER`) and
all tests in the test folder (default is `test`, defined in `TESTS_FOLDER`). Then it runs:

* [Nose](http://nose.readthedocs.io/en/latest/) to run unit tests, coverage test, doctest and BDD tests.
* Timing information about unit tests (only when exceeding certain configurable threshold).
* PyLint performing static analysis of the code.
* [MyPy](http://mypy.readthedocs.io/en/latest/) for checking types.
* Optionally runs [SonarQube Scanner](https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner) 
  that posts results to [SonarQube](https://www.sonarqube.org/) and checks if 
  [Quality Gate](https://docs.sonarqube.org/display/SONAR/Quality+Gates) is passed.
* Optionally opens coverage test results in default web browser. There results are interactive
  (allow sorting and inspecting files individually).

# Usage guide

1. Add `test.sh` to your repository root.
1. Modify `test.sh` to your specific needs in section marked as *project related constants*. 
   By default all checks are performed, except for [SonarQube](https://www.sonarqube.org/).
1. Run `test.sh` to check for errors: \
   `./test.sh`
1. Use additional options to fine-tune what is being run. See help: \
   `./test.sh -h` or `./test.sh --help`

## Dependencies

Only SonarQube has some dependencies. If you don't intend to use it, you can use the script
as is. In order to be able to run SonarQube Scanner and get the Quality Gate result back,
you will need to install the following:

* curl
* unzip
* [Oracle Java SE Development Kit (JDK)](www.oracle.com/technetwork/java/javase/downloads/) (not just JRE!)

## Usage as a Git hook

TODO

## TODOs
- [ ] Write a guide how to use as a git hook run before push
- [x] Allow disabling certain functions completely (so they are not even present in help)
- [x] Add generated files to .gitignore if not there
- [x] <s>Turn into Python script</s>
- [x] Make cross-platform
   - [x] Linux
   - [x] MacOS
   - [x] Windows (Cygwin)
- [x] Run in a separate virtualenv
- [x] Install all requirements automatically
- [x] Generate pylint config file
- [x] Generate coverage config file
- [x] <s>Use nosetest instead of manual search for tests</s>
- [x] Use Mypy
