#!/bin/bash -e

dirs=(
    # Add new directories below:
    "bin"
    "lib/cr_comment/src"
    "lib/cr_comment/test"
    "lib/crs_cli/src"
    "lib/crs_cli/test"
    "lib/crs_parser/src"
    "lib/crs_parser/test"
)

for dir in "${dirs[@]}"; do
    echo "Apply headache to directory ${dir}"

    # Apply headache to .ml files
    headache -c .headache.config -h COPYING.HEADER ${dir}/*.ml

    # Check if .mli files exist in the directory, if so apply headache
    if ls ${dir}/*.mli 1> /dev/null 2>&1; then
        headache -c .headache.config -h COPYING.HEADER ${dir}/*.mli
    fi
done

dune fmt
