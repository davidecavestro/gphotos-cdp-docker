#!/bin/env bash

FILE=$1
PARENT_DIR=$(dirname $FILE)

# set file time
exiftool "-DateTimeOriginal>FileModifyDate" $FILE

# move file to proper dir
exiftool '-Directory<DateTimeOriginal' -d '%Y/%Y-%m' $FILE

rm -rf $PARENT_DIR