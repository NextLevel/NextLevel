#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

jazzy \
	--clean \
	--author 'Patrick Piemonte' \
    --author_url 'https://patrickpiemonte.com' \
    --github_url 'https://github.com/NextLevel/NextLevel' \
    --sdk iphonesimulator \
    --xcodebuild-arguments -scheme,NextLevel \
    --module 'NextLevel' \
    --framework-root . \
    --readme README.md \
    --output Documentation/
