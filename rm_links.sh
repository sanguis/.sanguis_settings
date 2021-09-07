#!/usr/bin/env bash

P=$HOME/.sanguis_settings
source $P/links.sh
for k in ${!links[@]}; do
  if [ -f ${links[${k}]} ]; then
    rm -rf ${links[${k}]}
  fi
    ls ${links[${k}]}
done
