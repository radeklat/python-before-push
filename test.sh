#!/bin/bash
# To install required tools, run 'pip3 install pylint coverage'

TESTS_FOLDER="tests"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "** Stopped by user CTRL-C"
    exit 1
}

failed=0
ROOT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"
cd "$ROOT_FOLDER"

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

##### MODIFY THESE IF NEEDED #####

# Exclude/include files from/for doctests and pylint
PYFILES=$(find . -iregex '.*\.py$') # | grep -Ev './<EXCLUDED_PATH>')

# PYTHONPATH for imports
export PYTHONPATH="$PYTHONPATH:$(pwd)"

# Minimum total coverage in percent (0-100). This number should gradually increase with more/better tests
MIN_COVERAGE=95

##### Run doctest #####

echo "============================== Running doctest ================================"

for fl in ${PYFILES}; do
    python -m doctest "$fl"
    if [[ $? -ne 0 ]]; then
        failed=1
    fi
done

IFS=${SAVEIFS}

##### Run PyLint #####

echo "============================== Running pylint ================================="

pylint --rcfile="$TESTS_FOLDER/pylint.ini" $PYFILES
if [[ $? -ne 0 ]]; then
    failed=1
fi

##### Run unittests and coverage #####

echo "====================== Running unittests and coverage ========================="

rm -f .coverage  # remove any previous results

for fl in $(find "$TESTS_FOLDER" -iregex '.*\.py$'); do
    echo "---------- $fl ----------"

    coverage3 run --rcfile="$TESTS_FOLDER/coverage3.ini" -a "$fl"

    if [[ $? -ne 0 ]]; then
      failed=1
    fi
done

coverage3 report --rcfile="$TESTS_FOLDER/coverage3.ini" --fail-under=${MIN_COVERAGE}
if [[ $? -ne 0 ]]; then
  failed=1
fi

coverage3 html --rcfile="$TESTS_FOLDER/coverage3.ini"

xdg-open "$ROOT_FOLDER/htmlcov/index.html"  # open in default browser

exit ${failed}