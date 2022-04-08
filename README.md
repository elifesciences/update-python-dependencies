# update-dependencies

A bash script for Python projects using Pipenv that will update *all* dependencies or a single dependency.

## requisites

* Python project
* `Pipenv` file
* `requirements.txt` file

## usage

update all dependencies:

    ./update-dependencies.sh
    
update single dependency

    ./update-dependencies.sh <name> <version> [lock-constraint]

For example, to update [elife-tools](https://github.com/elifesciences/elife-tools) to version `0.15.0` you would do:

    ./update-dependencies.sh elifetools 0.15.0

The `lock-constraint` is either "semver" (default) or "exact".

Using the default `lock-constraint` and the above example, the updated `Pipfile` will look like `elifetools = "~=0.15.0"`.

If `lock-constraint` is "exact", then the updated `Pipfile` will look like `elifetools = "==0.15.0"`.
