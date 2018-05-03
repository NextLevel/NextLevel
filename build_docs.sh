#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

jazzy \
    --clean \
    --author 'Patrick Piemonte' \
    --author_url 'http://nextlevel.engineering' \
    --github_url 'https://github.com/NextLevel/NextLevel' \
    --sdk iphonesimulator \
    --xcodebuild-arguments -scheme,NextLevel \
    --module 'NextLevel' \
    --framework-root . \
    --readme README.md \
    --output docs/
