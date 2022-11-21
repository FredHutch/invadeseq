#!/bin/bash

set -euo pipefail

date
echo
echo "Running workflow from ${PWD}"
echo

# Run the workflow
echo Starting workflow
nextflow \
    run \
    "${TOOL_REPO}" \
    --output_dir "${PWD}" \
    -params-file ._wb/tool/params.json \
    -with-dag \
    -resume

echo
date
echo Done
