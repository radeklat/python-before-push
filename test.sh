#!/bin/bash

ROOT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"
cd "${ROOT_FOLDER}"

export PYTHONPATH="${PYTHONPATH}:$(pwd)"  # PYTHONPATH for imports

failed=0
pylintrc='.pylintrc'
pythons=("python3" "python")
venv_activate=".venv/bin/activate"
current_os="$(uname -s)"

if [[ "${current_os}" == "CYGWIN_NT-6.1" ]]; then
    pythons=("python3.exe" "python.exe")
    venv_activate=".venv/Scripts/activate"
    export PATH="/usr/local/bin:/usr/bin:$PATH"
fi

for py in ${pythons[*]}; do
    eval "${py} --version >/dev/null 2>&1"
    if [[ $? -eq 0 ]]; then
        python_exe="${py}"
        break
    fi
done

if [[ -z ${python_exe+x} ]]; then
    echo "No python executable found."
    exit 253
fi

while [[ "$#" > 0 ]]; do
    case $1 in
        -o|--browser) open_in_browser=1;;
        -p|--pylint) use_pylint=1;;
        -t|--types) use_typecheck=1;;
        -n|--nose) use_nosetest=1;;
        -h|--help) show_help=1;;
        -ni|--noinstall) no_install_requirements=1;;
        -nv|--novirtualenv) no_virtualenv=1;;
        -pe|--python) python_exe="$2"; shift;;
        *) break;;
    esac
    shift
done

if [[ -n ${show_help+x} ]]; then
    echo -e "Sanity testing script. If no tool is selected, all will run by default.\n"
    echo -e "Run as:\n  $0 [options]\n\nPossible options are:"
    echo -e "  -h, --help: Displays this help.\n"
    echo -e "  -p, --pylint: Run PyLint."
    echo -e "  -t, --types: Run Mypy for checking types usage."
    echo -e "  -n, --nose: Run unit and coverage tests with Nose.\n"
    echo -e "  -o, --browser: Open coverage results in browser."
    echo -e "  -ni, --noinstall: Do not install requirements and dependencies.\n"
    echo -e "  -nv, --novirtualenv: Do not create/use virtualenv."
    echo -e "  -pe, --python: Specify python executable to use for virtualenv."
    exit 255
fi

if [[ -z ${use_pylint+x} && -z ${use_typecheck+x} && -z ${use_nosetest+x} ]]; then
    use_all=1
fi

if [[ -z ${no_virtualenv+x} ]]; then
    if [[ ! -d .venv ]]; then
        pip install --upgrade virtualenv
        failed=$(expr ${failed} + $?)

        echo -e "\n============================= Creating vitualenv ==============================\n"

        eval "${python_exe} --version" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo "Python executable '${python_exe}' does not exist. Cannot create virtualenv."
            exit 1
        fi

        virtualenv -p "${python_exe}" ".venv"
    fi

    source "${venv_activate}"
fi

if [[ -z ${no_install_requirements+x} ]]; then
    echo -e "\n========================== Refreshing dependencies ============================\n"
    pip install --upgrade mypy nose rednose coverage pylint
    failed=$(expr ${failed} + $?)

    if [[ "${current_os}" == "CYGWIN_NT-6.1" ]]; then
        pip install --upgrade pypiwin32
        failed=$(expr ${failed} + $?)
    fi

    if [[ -f "requirements.txt" ]]; then
        pip install --upgrade -r "requirements.txt"
        failed=$(expr ${failed} + $?)
    fi

    echo -e "\nUse '-ni' command line argument to prevent installing requirements."
fi

if [[ -n ${use_all+x} || -n ${use_nosetest+x} ]]; then
    echo -e "\n============================= Running nose test ===============================\n"

    nosetests \
        --with-coverage \
        --cover-branches \
        --cover-html \
        --cover-erase \
        --cover-inclusive \
        --cover-package=src \
        --hide-skips \
        --rednose \
        $(find tests -name "*.py" ! -name "__init__*")

    failed=$(expr ${failed} + $?)

    # open in default browser
    [[ "${current_os}" == "CYGWIN_NT-6.1" ]] && cover_path="$(cygpath.exe -w "$(pwd)")" || cover_path="$(pwd)"
    eval "${python_exe} -m webbrowser -t '${cover_path}/cover/index.html'"

    rm .coverage
fi

if [[ -n ${use_all+x} || -n ${use_typecheck+x} ]]; then
    echo -e "\n============================ Running type check ===============================\n"

    mypy_exe="mypy"
    if [[ "${current_os}" == "CYGWIN_NT-6.1" ]]; then
        mypy_exe="${python_exe} .venv/Lib/site-packages/mypy/"
    fi

    # --disallow-untyped-calls \
    eval ${mypy_exe} \
        --ignore-missing-imports \
        $(find . -name "*.py" ! -regex "\.\/\.venv/.*")

    failed=$(expr ${failed} + $?)
fi

if [[ -n ${use_all+x} || -n ${use_pylint+x} ]]; then
    echo -e "\n============================== Running pylint =================================\n"

    if [[ ! -f "${pylintrc}" ]]; then
        # create default file to prevent automatic picking up an unexpected one
        pylint --generate-rcfile >"${pylintrc}"
    fi

    # F,E,W,R,C

    pylint \
        --rcfile="${pylintrc}" \
        --disable="all,RP0001,RP0002,RP0003,RP0101,RP0401,RP0701,RP0801" \
        --enable="F,E" \
        --output-format="colorized" \
        --evaluation="10.0 - ((float(20 * fatal + 10 * error + 5 * warning + 2 * refactor + convention) / statement) * 10)" \
        --max-line-length=92 \
        --msg-template='{C}:{line:3d},{column:2d}: {msg} ({symbol}, {msg_id})' \
        $(find . -name "*.py" ! -regex "\.\/\.venv/.*")

    failed=$(expr ${failed} + $?)
fi

if [[ -z ${no_virtualenv+x} ]]; then
    deactivate
fi

exit ${failed}