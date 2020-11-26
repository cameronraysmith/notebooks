#!/usr/bin/env bash
set -euo pipefail

# list records associated with $CF_DOMAIN to retrieve $CF_RECORD_ID
# curl -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records?type=A&name=$CF_DOMAIN&page=1&per_page=20&order=type&direction=desc&match=all" \
#      -H "X-Auth-Email: $CF_EMAIL" \
#      -H "X-Auth-Key: $CF_API_KEY" \
#      -H "Content-Type: application/json"
#
# update IP
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records/$CF_RECORD_ID" \
     -H "X-Auth-Email: $CF_EMAIL" \
     -H "X-Auth-Key: $CF_API_KEY" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'$CF_DOMAIN'","content":"'$1'","ttl":0,"proxied":true}'
