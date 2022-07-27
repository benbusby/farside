#!/bin/bash
# Remove cloudflare instances from services-full.json

rm -f out.json
file="services-full.json"

while read -r line; do
    if [[ "$line" == "\"https://"* ]]; then
        domain=$(echo "$line" | sed -e "s/^\"https:\/\///" -e "s/\",//" -e "s/\"//")
        ns=$(dig ns "$domain")
        if [[ "$ns" == *"cloudflare"* ]]; then
            echo "\"$domain\" using cloudflare, skipping..."
        else
            echo "$line" >> out.json
        fi
    else
        echo "$line" >> out.json
    fi
done <$file

# Remove any trailing commas from new instance lists
sed -i '' -e ':begin' -e '$!N' -e 's/,\n]/\n]/g' -e 'tbegin' -e 'P' -e 'D' out.json

cat out.json | jq --indent 2 . > services.json
rm out.json

