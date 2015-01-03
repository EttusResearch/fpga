#!/bin/bash

if (git diff --quiet); then
#Clean
    short_hash="0$(git rev-parse --verify HEAD --short)"
else
#Dirty
    short_hash="F$(git rev-parse --verify HEAD --short)"
fi

echo $short_hash

