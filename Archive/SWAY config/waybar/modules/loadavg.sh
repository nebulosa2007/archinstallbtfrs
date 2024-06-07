#!/bin/env bash

load=$(cut -d" " -f1 </proc/loadavg)
loadavg=$(cut -d" " -f1-3 </proc/loadavg)

echo "{\"text\":\"$load\",\"tooltip\":\"$loadavg\"}"
