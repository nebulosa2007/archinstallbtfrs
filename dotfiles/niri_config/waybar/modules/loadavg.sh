#!/bin/env bash

IFS=" " read -r -a load < /proc/loadavg
ZPROCESSES=$(pgrep --runstates Z -a | sed -z 's/[<>]//g;s|\n|\\\\n|g')
ATT=$([ -n "$ZPROCESSES" ] && echo "! \\\n\\\n" || echo "")
echo -e "{\"text\": \"${ATT:0:2}${load[0]}\", \"tooltip\": \"${load[0]} ${load[1]} ${load[2]}\\\n$(uptime -p)${ATT:2}$ZPROCESSES\"}"
