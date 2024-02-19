#!/bin/sh
# This script tests the top 1000 fediverse servers (according to fediverse.observer) to determine which are blocked in China.

echo 'fetching all known fediverse sites from fediverse.observer... (thanks David Morley!)' 1>&2
if [ ! -e fediverse_servers.json ]; then
  curl 'https://api.fediverse.observer/' \
    -H 'authority: api.fediverse.observer' \
    -H 'accept: */*' \
    -H 'accept-language: en-US,en;q=0.7' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'origin: https://fediverse.observer' \
    -H 'pragma: no-cache' \
    -H 'referer: https://fediverse.observer/' \
    -H 'sec-ch-ua: "Not_A Brand";v="8", "Chromium";v="120", "Brave";v="120"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Linux"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-site' \
    -H 'sec-gpc: 1' \
    -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
    --data-raw '{"query":"{nodes(softwarename:\"\" status: \"UP\"){domain uptime_alltime signup total_users countryname greenhost detectedlanguage name softwarename shortversion comment_counts local_posts monthsmonitored}}"}' \
    --compressed > fediverse_servers.json
fi

_top_fediverse_sites() {
  cat fediverse_servers.json | jq -r '[ .data.nodes[] ] | sort_by(.total_users) | reverse | .[:1000] | .[] | .domain'
}

echo 'sorting fediverse sites...' 1>&2
_sites=($(_top_fediverse_sites))

for site in ${_sites[@]}; do
  _fw_test=$(curl "http://www.chinafirewalltest.com/?siteurl=${site}" \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8' \
    -H 'Accept-Language: en-US,en;q=0.8' \
    -H 'Cache-Control: no-cache' \
    -H 'Connection: keep-alive' \
    -H 'Pragma: no-cache' \
    -H 'Sec-GPC: 1' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
    --compressed \
    --silent \
    --insecure)
  _blocked_in_china="Unknown"
  if echo ${_fw_test} | grep -q 'resultstatus ok'; then
    _blocked_in_china='Not_Blocked'
  elif echo ${_fw_test} | grep -q 'resultstatus fail'; then
    _blocked_in_china='Blocked'
  fi

  # Print as CSV
  echo "${_blocked_in_china},${site}"
  sleep 1
done
