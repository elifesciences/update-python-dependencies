#!/bin/bash
# updates Pipfile.lock and regenerates the requirements.txt file.
# if a package and a version are passed in, then just that package (and it's dependencies) will be updated.

set -ex

# the envvar is necessary otherwise Pipenv will use it's own .venv directory.
export VIRTUAL_ENV="venv"

# optional
package="$1"
version="$2"
lock_constraint=${3:-semver} # either 'semver' (~=) or not-semver (==).

if [ ! -e Pipfile ]; then
    echo "a 'Pipfile' is missing"
    exit 1
fi

if [ ! -e requirements.txt ]; then
    echo "a 'requirements.txt' file is missing"
    exit 1
fi

if [[ "$lock_constraint" != semver && "$lock_constraint" != exact ]]; then
    echo "the lock constraint must be either 'semver' (default) or 'exact'."
    exit 1
fi

# create/update existing venv
rm -rf venv/

# whatever your preferred version of python is, eLife needs to support python3.6 (Ubuntu 18.04)
python3.6 -m venv venv

# prefer using wheels to compilation
source venv/bin/activate
pip install pip wheel --upgrade

if [ -n "$package" ]; then
    # updates a single package to a specific version.

    pip install -r requirements.txt

    # make Pipenv install exactly what we want (==).
    if [[ "$OSTYPE" == linux-gnu* ]]; then
        sed --in-place --regexp-extended "s/$package = \".+\"/$package = \"==$version\"/" Pipfile
    else
        sed -i '' -E "s/$package = \".+\"/$package = \"==$version\"/" Pipfile
    fi

    pipenv install --keep-outdated "$package==$version"

    # relax the constraint again (~=).
    if [[ "$lock_constraint" == semver ]]; then
        if [[ "$OSTYPE" == linux-gnu* ]]; then
            sed --in-place --regexp-extended "s/$package = \".+\"/$package = \"~=$version\"/" Pipfile
        else
            sed -i '' -E "s/$package = \".+\"/$package = \"~=$version\"/" Pipfile
        fi
    fi
else
    # updates the Pipfile.lock file and then installs the newly updated dependencies.
    # the envvar is necessary otherwise Pipenv will use it's own .venv directory.
    pipenv update --dev
fi

datestamp=$(date +"%Y-%m-%d") # long form to support linux + bsd
echo "# file generated $datestamp - see update-dependencies.sh" > requirements.txt
# lsh@2021-11-29: re 'pkg-resources': https://github.com/pypa/pip/issues/4022
pipenv run pip freeze | grep -v pkg_resources >> requirements.txt
