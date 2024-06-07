#!/bin/env bash

# wttr.in's location service is a bit shit
location=$1
if [[ -z "$1" ]]; then
    ifconfigco=`curl -sS ifconfig.co/json`
    city=`echo $ifconfigco | jq ".city"`
    country_code=`echo $ifconfigco | jq ".country_iso"`

    location=`echo $city,$country_code | sed --expression "s/\"//g"`
fi

# Set up caching to avoid tons of reqs to wttr
cachedir=~/.cache/rbn
cachefile=${0##*/}-$location

if [ ! -d $cachedir ]; then
    mkdir -p $cachedir
fi

if [ ! -f $cachedir/$cachefile ]; then
    touch $cachedir/$cachefile
fi

# Save current IFS
SAVEIFS=$IFS
# Change IFS to new line.
IFS=$'\n'

cacheage=$(($(date +%s) - $(stat -c '%Y' "$cachedir/$cachefile")))
if [ $cacheage -gt 1740 ] || [ ! -s $cachedir/$cachefile ]; then
    data=($(curl -s https://en.wttr.in/$location\?0qnT 2>&1))
    echo ${data[0]} | cut -f1 -d, > $cachedir/$cachefile
    echo ${data[1]} | sed -E 's/^.{15}//' >> $cachedir/$cachefile
    echo ${data[2]} | sed -E 's/^.{15}//' >> $cachedir/$cachefile
fi

weather=($(cat $cachedir/$cachefile))

# Restore IFSClear
IFS=$SAVEIFS

temperature=$(echo ${weather[2]} | sed -E 's/\(/\(\+/;s/\+-/-/;s/\(/°, feels like /;s/\) °C/°/')

# https://fontawesome.com/icons?s=solid&c=weather
# echo $(echo ${weather[1]##*,} | tr '[:upper:]' '[:lower:]')
case $(echo ${weather[1]##*,} | tr '[:upper:]' '[:lower:]') in
"clear" | "sunny")
    icon=""
    ;;
"partly cloudy" | "cloudy" | "overcast")
    icon=""
    ;;
"mist" | "fog" | "freezing fog")
    icon=""
    ;;
"patchy rain possible" | "patchy light drizzle" | "light drizzle" | "rain")
    icon=""
    ;;
"patchy light rain" | "light rain" | "light rain shower" )
    icon="🌦 "
    ;;
"moderate rain at times" | "moderate rain" | "heavy rain at times" | "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | "rain shower")
    icon=""
    ;;
"patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
    icon=""
    ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow" | "light snow showers")
    icon=""
    ;;
"blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
    icon=""
    ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
    icon=""
    ;;
*)
    icon=""
    ;;
esac

echo -e "{\"text\":\""\<span font=\'Font Awesome 5 Free 10\'\>$icon\<\/span\> "$temperature \", \"class\": \"weather\", \"tooltip\":\""${weather[0]}: ${weather[1]}, updated at: $(stat -c '%z' "$cachedir/$cachefile"| cut -d' ' -f2 | cut -d'.' -f1)"\"}"
