#!/usr/bin/env bash
# -*- mode: sh; coding: utf-8; tab-width: 4; indent-tabs-mode: nil -*-
set -euo pipefail
IFS=$'\n\t'

PATH="/usr/local/bin:$PATH"
export PATH

IP_ADDRS="10.0.1.222, 10.0.2.91, 10.0.3.37"

for IP_ADDR in ${IP_ADDRS//, /$IFS}
do
    STARTERKIT_INSTANCE_IP_ADDR="$IP_ADDR" make deploy
done
