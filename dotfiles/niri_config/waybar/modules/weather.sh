#!/bin/env bash

# Set up caching to avoid tons of reqs to server
cachedir=$HOME/.cache/rbn
cachefile=${0##*/}-temp

[ "$1" == "reload" ] && find "$cachedir" -name "$cachefile" -delete

[ ! -d "$cachedir" ] && mkdir -p "$cachedir"
[ ! -f "$cachedir"/"$cachefile" ] && touch "$cachedir"/"$cachefile"

cacheage=$(($(date +%s) - $(stat -c '%Y' "$cachedir/$cachefile")))
if [ "$cacheage" -gt 1740 ] || [ ! -s "$cachedir"/"$cachefile" ]; then
    ifconfigco="$(curl -sS ifconfig.co/json)"
    city="$(echo "$ifconfigco" | jq --raw-output ".city")"
    code="$(echo "$ifconfigco" | jq --raw-output ".country_iso")"
     lat="$(echo "$ifconfigco" | jq ".latitude")"
     lon="$(echo "$ifconfigco" | jq ".longitude")"
    location=$city", "$code

    echo "$location" > "$cachedir"/"$cachefile"

    data=$(curl -s "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$lat&lon=$lon")
  { echo "$data" | jq ".properties.timeseries.[0].data.instant.details.air_temperature";
    echo "$data" | jq --raw-output ".properties.timeseries.[0].data.next_1_hours.summary.symbol_code" | cut -d"_" -f1;
    echo "$data" | jq ".properties.timeseries.[0].data.instant.details.relative_humidity";
    echo "$data" | jq ".properties.timeseries.[0].data.instant.details.wind_from_direction";
    echo "$data" | jq ".properties.timeseries.[0].data.instant.details.wind_speed"; } >> "$cachedir"/"$cachefile"
fi

mapfile -t weather < <(cat "$cachedir"/"$cachefile")

[ -z "${weather[2]}" ] && { echo -e "{\"text\":\"Error retreaving weather info\", \"class\": \"weather\", \"tooltip\": \"\"}" ; exit 1; }

case ${weather[2]} in
"fair" | "clearsky" | "clear" | "sunny")
    icon=" "
    ;;
"partlycloudy" | "partly cloudy" | "cloudy" | "overcast")
    icon="  "
    ;;
"mist" | "fog" | "freezing fog")
    icon=" "
    ;;
"lightrain" | "patchy rain possible" | "patchy light drizzle" | "light drizzle" | "rain")
    icon=" "
    ;;
"lightrainshowers" | "patchy light rain" | "light rain" )
    icon="🌦 "
    ;;
"heavyrain" | "rainshowers" | "heavyrainshowers" )
    icon=" "
    ;;
"snow" | "sleet" | "lightsnow" | "lightsleet" | "light snow" | "snow shower" | "patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
    icon=" "
    ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow showers")
    icon=" "
    ;;
"heavysnow" | "blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
    icon=" "
    ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
    icon="  "
    ;;
*)
    icon=" "
    ;;
esac

directions=(N ↘NNW ↘NW WNW W ↗WSW ↗SW SSW S ↖SSE ↖SE ESE E ↙ENE ↙NE NNE N)
sectors=(348.75 326.25 303.75 281.25 258.75 236.25 213.75 191.25 168.75 146.25 123.75 101.25 78.75 56.25 33.75 11.25 -11.25)

for index in ${!directions[*]}
do
    if [ "${weather[4]%.*}" -eq "${sectors[$index]%.*}" ] && [ "${weather[4]#*.}" \> "${sectors[$index]#*.}" ] || [ "${weather[4]%.*}" -gt "${sectors[$index]%.*}" ]; then
        wind_dir=${directions[$index]}
        break
    fi
done

beaufort_scale=(" Hurricane-force" " Violent storm" " Storm" " Strong gale" " Gale" "! High wind"  "! Strong breeze" "  Fresh breeze" "  Moderate breeze" "  Gentle breeze"  "  Light breeze" "  Light air" "  Calm")
sectors=(32.6 28.4 24.4 20.7 17.1 13.8 10.7 7.9 5.4 3.3 1.5 0.2 0)

for index in ${!beaufort_scale[*]}
do
    if [ "${weather[5]%.*}" -eq "${sectors[$index]%.*}" ] && [ "${weather[5]#*.}" \> "${sectors[$index]#*.}" ] || [ "${weather[5]%.*}" -gt "${sectors[$index]%.*}" ]; then
        wind_scale=${beaufort_scale[$index]}
        break
    fi
done

echo -e "{\"text\":\"<big>${wind_scale:0:1} ${wind_dir:0:1} $(printf '%.0f' "${weather[5]}")</big>m/s     <big>${icon}$(printf '%.0f' "${weather[1]}")°</big>\",\
 \"class\": \"weather\", \"tooltip\": \"${weather[0]}, $(stat -c '%z' "$cachedir/$cachefile" | cut -d' ' -f2 | cut -d'.' -f1)\\\n\
${wind_scale:2}, ${wind_dir} $(printf '%.0f' "${weather[5]}") m/s\\\n\
Relative humidity: $(printf '%.0f' "${weather[3]}")%\\\n\
${weather[2]}\"}"
