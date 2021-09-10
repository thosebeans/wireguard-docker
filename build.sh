#!/usr/bin/env sh

cd "$(dirname "$0")"

VERSION=''

if [ -e .git ]; then
    TAGS="$(git tag | while read i; do
        printf '%s %s\n' \
            "$i" \
            "$(git rev-parse "$i")"
    done)"
    HEAD="$(git rev-parse HEAD)"
    if echo "$TAGS" | grep -F "$HEAD" >/dev/null; then
        VERSION="$(echo "$TAGS" | 
                   grep -F "$HEAD" |
                   sed 's|\s[0-9a-f]\+$||g')"
    else 
        VERSION="$(git rev-parse --short HEAD)"
    fi
else
    VERSION="$(basename "$(pwd)" |
               grep 'v[0-9.-]\+$')"
fi

ALPINE_VERSION="$(cat Dockerfile |
                  grep '^FROM' |
                  sed 's|^FROM\s||g' |
                  sed 's|:|-|g')"

docker build --force-rm -t "thosebeans/wireguard:${VERSION}-${ALPINE_VERSION}" .
