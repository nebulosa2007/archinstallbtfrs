#!/bin/bash

DAYSBETWEEN=$(( ($(date -d $(date +%Y-%m-%d) +%s) - $(date -d $(head -1 /var/log/pacman.log | cut -c 2-11) +%s)) / 86400 ))

YEARSCALC=$(( $DAYSBETWEEN / 365 ))
MONTHSCALC=$(( ($DAYSBETWEEN - ($YEARSCALC * 365)) / 30 ))
DAYSCALC=$(( $DAYSBETWEEN -($YEARSCALC * 365) - ($MONTHSCALC * 30) ))

[[ $YEARSCALC > 0  ]] && YEARS=$YEARSCALC"y "
[[ $MONTHSCALC > 0 ]] && MONTHS=$MONTHSCALC"m "
[[ $DAYSCALC > 0   ]] && DAYS=$DAYSCALC"d"

echo "System age: "$YEARS$MONTHS$DAYS" (since "$(head -1 /var/log/pacman.log | cut -c 2-11)")"