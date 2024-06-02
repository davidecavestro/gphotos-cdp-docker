#!/bin/env bash

#pwd

#ls -lha $FILE

DEST_DIR='' : "${DEST_DIR:?DEST_DIR is not set}"
[ -d "$DEST_DIR" ] || { echo "DEST_DIR does not exist: $DEST_DIR"; exit 2; }

#IGNORE_REGEX="${IGNORE_REGEX:-(^(Screenshot_|VID-).*)|(.*(MV-PANO|COLLAGE|-ANIMATION|-EFFECTS)\..*)}"
IGNORE_REGEX="${IGNORE_REGEX:-.*(MV-PANO|COLLAGE|-ANIMATION|-EFFECTS)\..*)}"

function do_image () {
  local FILE=$1
  local PARENT_DIR=$(dirname $FILE)

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
}

function do_video () {
  local FILE=$1
  local PARENT_DIR=$(dirname $FILE)

  echo "PARENT_DIR: $PARENT_DIR"

  #json=$(ffprobe -v quiet -print_format json -show_format $1)
  #creation_time=$(echo $json | jq -r .format.tags.creation_time)
  #location=$(echo $json | jq -r .format.tags.location)
  
  local creation_time=$(ffprobe -v quiet -print_format json -show_entries format_tags=creation_time "$FILE" | jq -r '.format.tags.creation_time')
  
  # If creation_time is not available, use file modification time
  if [[ "$creation_time" == "null" || -z "$creation_time" ]]; then
#    creation_time=$(stat -c %y "$file")
    echo "$FILE has no creation_time"
  else
    # Extract year and month from the creation time
    local year=$(date -d "$creation_time" +"%Y")
    local month=$(date -d "$creation_time" +"%Y-%m")
    
    # Create target directory if it doesn't exist
    local target_dir="${PARENT_DIR}/${year}/${year}-${month}"
    mkdir -p "${target_dir}"
    
    # Move the file to the target directory
    mv "$FILE" "${target_dir}/"
    
    echo "Moved $FILE to $target_dir/"

    # move to destination folder
    cd $PARENT_DIR
    rsync \
      -av \
      --remove-source-files \
      --include='20[0-9][0-9]/' --include='20[0-9][0-9]/20[0-9][0-9]-[0-1][0-9]/' \
      . $DEST_DIR

  fi
  
  rm -rf $PARENT_DIR
}

# Check if the file matches the regex in IGNORE_REGEX
base=$(basename $1)
if [[ ! $base =~ $IGNORE_REGEX ]]; then
  echo "Processing: $1"
  mimetype=$(mimetype -b "$1")

  case $mimetype in
    image/*)
      do_image "$1"
      ;;
    video/*)
      do_video "$1"
      ;;
    *)
      echo "$1 is neither an image nor a video"
      ;;
  esac
else
  echo "Ignoring $1"
fi
