#!/bin/bash

if [[ $(command -v git) = "" ]]; then
    short_hash="FFFFFFFF"
else
    if (git diff --quiet); then
        #Clean
        short_hash="0$(git rev-parse --verify HEAD --short=7)"
    else
        #Dirty
        short_hash="F$(git rev-parse --verify HEAD --short=7)"
    fi
fi
echo ${short_hash^^}
