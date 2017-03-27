#!/bin/bash

ROOT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"
cd "${ROOT_FOLDER}"

export PYTHONPATH="$(pwd):${PYTHONPATH}"  # PYTHONPATH for imports

BRED='\033[1;31m'
BGREEN='\033[1;32m'
NC='\033[0m' # No Color

failed=0
pylintrc='.pylintrc'
current_os="$(uname -s)"
pips=("pip3" "pip")
venv=".venv_${current_os}"

if [[ "${current_os}" == "CYGWIN_NT-6.1" ]]; then
    pythons=("python3.exe" "python.exe")
    venv_activate="${venv}/Scripts/activate"
    cover_path="$(cygpath.exe -w "$(pwd)")"
    venv_sudo=""
    export PATH="/usr/local/bin:/usr/bin:$PATH"
else
    venv_sudo="echo 'Needs sudo to install virtualenv via pip.'; sudo -H "
    pythons=("python3" "python")
    venv_activate="${venv}/bin/activate"
    cover_path="$(pwd)"
fi

test_exit() {
    if [[ $1 -ne 0 ]]; then
        echo -e "$2"
        exit $1
    elif [[ -n ${3+x} ]]; then
        echo -e "$3"
    fi
}

for py in ${pythons[*]}; do
    eval "${py} --version >/dev/null 2>&1"
    if [[ $? -eq 0 ]]; then
        python_exe="${py}"
        break
    fi
done

if [[ -z ${python_exe+x} ]]; then
    test_exit 253 "No python executable found."
fi

# platform-specific command to open an HTML file in a default browser
[[ "${current_os}" == "Darwin" ]] && website_opener="open" || website_opener="${python_exe} -m webbrowser -t"

check_supported_python_version() {
    ver() {
        printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' ')
    }
    py_version="$(${python_exe} --version 2>&1 | cut -d ' ' -f 2)"
    [[ "${current_os}" == "CYGWIN_NT-6.1" ]] && py_version="$(echo ${py_version} | tr --delete '\r')"
    [[ $(ver "${py_version}") -ge $(ver "3.4") && $(ver "${py_version}") -lt $(ver "3.6") ]]
    test_exit $? "Python version ${py_version} is not supported. Supported versions range is <3.4, 3.5).\nUse '-pe' option to specify different python executable."
}

discover_pip() {
    for pie in ${pips[*]}; do
        eval "${pie} --version >/dev/null 2>&1"
        if [[ $? -eq 0 ]]; then
            echo "${pie}"
            return 0
        fi
    done

    return 1
}

pip_exe="$(discover_pip)"
test_exit $? "No pip executable found. Please install pip."

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
    if [[ ! -d "${venv}" ]]; then
        check_supported_python_version

        echo -e "\n============================= Creating vitualenv ==============================\n"

        eval "${venv_sudo}${pip_exe} install --upgrade virtualenv"
        test_exit $? "Could not install virtualenv via pip."

        eval "${python_exe} --version" >/dev/null 2>&1
        test_exit $? "Python executable '${python_exe}' does not exist. Cannot create virtualenv."

        virtualenv -p "${python_exe}" "${venv}"
    fi

    source "${venv_activate}"
    test_exit $? "Failed to activate virtualenv."

    pip_exe="$(discover_pip)"
else
    check_supported_python_version
fi

if [[ -z ${no_install_requirements+x} ]]; then
    echo -e "\n========================== Refreshing dependencies ============================\n"
    eval "${pip_exe} install --upgrade mypy nose rednose coverage pylint"
    test_exit $? "Failed to install required dependencies via pip."

    if [[ "${current_os}" == "CYGWIN_NT-6.1" ]]; then
        eval "${pip_exe} install --upgrade pypiwin32"
        test_exit $? "Failed to install pypiwin32 via pip."
    fi

    if [[ -f "requirements.txt" ]]; then
        eval "${pip_exe} install --upgrade -r 'requirements.txt'"
        test_exit $? "Failed to install requirements via pip."
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
    [[ -n ${open_in_browser+x} ]] && eval "${website_opener} '${cover_path}/cover/index.html'"

    rm -f .coverage
fi

if [[ -n ${use_all+x} || -n ${use_typecheck+x} ]]; then
    echo -e "\n============================ Running type check ===============================\n"

    mypy_exe="mypy"
    if [[ "${current_os}" == "CYGWIN_NT-6.1" ]]; then
        mypy_exe="${python_exe} ${venv}/Lib/site-packages/mypy/"
    fi

    # --disallow-untyped-calls \
    eval ${mypy_exe} \
        --ignore-missing-imports \
        $(find . -name "*.py" ! -regex "\.\/\.venv_.*")

    failed=$(expr ${failed} + $?)
fi

if [[ -n ${use_all+x} || -n ${use_pylint+x} ]]; then
    echo -e "\n============================== Running pylint =================================\n"

    if [[ ! -f "${pylintrc}" ]]; then
        # create default file to prevent automatic picking up an unexpected one
        pylint --generate-rcfile >"${pylintrc}"
    fi

    pylint \
        --rcfile="${pylintrc}" \
        --disable="all,RP0001,RP0002,RP0003,RP0101,RP0401,RP0701,RP0801" \
        --enable="F,E,W,R,C" \
        --output-format="colorized" \
        --evaluation="10.0 - ((float(20 * fatal + 10 * error + 5 * warning + 2 * refactor + convention) / statement) * 10)" \
        --max-line-length=92 \
        --msg-template='{C}:{line:3d},{column:2d}: {msg} ({symbol}, {msg_id})' \
        --dummy-variables-rgx="(_+[a-zA-Z0-9_]*?$)|args|kwargs" \
        --good-names="i,j,k,e,ex,fd,Run,_" \
        $(find . -name "*.py" ! -regex "\.\/\.venv_.*")

    failed=$(expr ${failed} + $?)
fi

if [[ -z ${no_virtualenv+x} ]]; then
    deactivate
fi

test_exit ${failed} "${BRED}Some tests failed.${NC}" "${BGREEN}All tests passed.${NC}"