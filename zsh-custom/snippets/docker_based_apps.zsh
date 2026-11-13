#!/bin/zsh
# @brief Functions that ca;ll remote docker functions


function terraform-compliance {
  docker run --rm -v $(pwd):/target -i -t eerkunt/terraform-compliance "$@";
}

shdoc() {
  docker run --rm -v $(pwd):$(pwd) -w $(pwd) -it sanguis/shdoc "$@";
}

terraspace() {
  docker run --rm -v $(pwd):$(pwd) -w $(pwd) -it ghcr.io/boltops-tools/terraspace:alpine "$@";
}
