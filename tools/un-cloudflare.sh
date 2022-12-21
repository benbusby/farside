#!/bin/bash
# Remove cloudflare instances from services-full.json

rm -f out.json
file="services-full.json"

while read -r line; do
    if [[ "$line" == "\"https://"* ]]; then
        domain=$(echo "$line" | sed -e "s/^\"https:\/\///" -e "s/\",//" -e "s/\"//")
        ips=$(dig "$domain" +short || true)
        cf=0
        echo "$domain"

        for ip in $ips
        do
            echo "    - $ip"
            resp=$(curl --connect-timeout 5 --max-time 5 -s "$ip")

            # Cloudflare does not allow accessing sites using their IP,
            # and returns a 1003 error code when attempting to do so. This
            # allows us to check for sites using Cloudflare for proxying,
            # rather than just their nameservers.
            if [[ "$resp" == *"error code: 1003"* ]]; then
                cf=1
                echo "    ! Using cloudflare proxy, skipping..."
                break
            fi
        done

        if [ $cf -eq 0 ]; then
            echo "$line" >> out.json
        fi
    else
        echo "$line" >> out.json
    fi
done <$file

# Remove any trailing commas from new instance lists
sed -i -e ':begin' -e '$!N' -e 's/,\n]/\n]/g' -e 'tbegin' -e 'P' -e 'D' out.json

cat out.json | jq --indent 2 . > services.json
rm -f out.json
