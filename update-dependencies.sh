#!/bin/bash
# updates Pipfile.lock and regenerates the requirements.txt file.
# if a package and a version are passed in, then just that package (and it's dependencies) will be updated.

set -e

# optional
package="$1"
version="$2"
lock_constraint=${3:-semver} # either 'semver' (~=) or 'exact' (==).

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
#pip install pipenv==2022.1.8 # don't do this, it will add pipenv and it's dependencies to the requirements.txt file

# the envvar is necessary otherwise Pipenv will use it's own .venv directory.
export VIRTUAL_ENV="venv"

# suppress pipenv warnings about using our own virtualenv.
export PIPENV_VERBOSITY=-1

# pipenv supposedly doesn't use requirements.txt if a Pipfile is present, but it's presence 
# can lead to it hanging attempting to update the lock file.
pip install -r requirements.txt
#rm requirements.txt

if [ -n "$package" ]; then
    # updates a single package to a specific version.

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
    pipenv update --dev
fi

datestamp=$(date +"%Y-%m-%d") # long form to support linux + bsd
echo "# file generated $datestamp - see update-dependencies.sh" > requirements.txt
# lsh@2021-11-29: re 'pkg-resources': https://github.com/pypa/pip/issues/4022
pipenv run pip freeze | grep -v pkg_resources >> requirements.txt
