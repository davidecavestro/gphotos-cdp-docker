#!/bin/env bash

FILE=$1
PARENT_DIR=$(dirname $FILE)

pwd

ls -lha $FILE

DEST_DIR='' : "${DEST_DIR:?DEST_DIR is not set}"
[ -d "$DEST_DIR" ] || { echo "DEST_DIR does not exist: $DEST_DIR"; exit 2; }

echo "PARENT_DIR: $PARENT_DIR"
# set file time
exiftool "-DateTimeOriginal>FileModifyDate" $FILE

# move file to proper subdir
exiftool  -d "${PARENT_DIR}/%Y/%Y-%m" '-directory<${CreateDate}' '-filename<${filename}' $FILE

# move to destination folder
cd $PARENT_DIR
rsync \
  -av \
  --remove-source-files \
  --include='20[0-9][0-9]/' --include='20[0-9][0-9]/20[0-9][0-9]-[0-1][0-9]/' \
  . $DEST_DIR

rm -rf $PARENT_DIR