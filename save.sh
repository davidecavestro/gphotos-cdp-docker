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

  local creation_time=$(exiftool -DateTimeOriginal -d "%Y-%m-%d %H:%M:%S" "$FILE" | awk -F ': ' '{print $2}')

  local filename=$(basename $FILE)
  # If creation_time is not available, try getting it from filename
  if [[ -z "$creation_time" ]]; then
    # Use regex to match the encoded timestamp in the filename
    if [[ $filename =~ ^.*([0-9]{8})_([0-9]{6}).* ]]; then
      # Extract the encoded date and time
      encoded_date=${BASH_REMATCH[1]}
      encoded_time=${BASH_REMATCH[2]}
      
      # Extract year, month, day, hour, minute, second
      year="${encoded_date:0:4}"
      month=${encoded_date:4:2}
      day=${encoded_date:6:2}
      hour=${encoded_time:0:2}
      minute=${encoded_time:2:2}
      second=${encoded_time:4:2}
      
      # Create a formatted timestamp
      creation_time="$year-$month-$day $hour:$minute:$second"

      exiftool "-DateTimeOriginal=${creation_time}" -overwrite_original "$FILE"
      # Check if the command was successful
      if [[ $? -eq 0 ]]; then
        echo "DateTimeOriginal has been set to $creation_time for $FILE"
      else
        echo "Failed to set DateTimeOriginal for $FILE"
      fi
    fi
  fi

  # set file time
  exiftool "-DateTimeOriginal>FileModifyDate" $FILE

  # move file to proper subdir
  exiftool  -d "${PARENT_DIR}/%Y/%Y-%m" '-directory<${DateTimeOriginal}' '-filename<${filename}' $FILE

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

  local creation_time=$(ffprobe -v quiet -print_format json -show_entries format_tags=creation_time "$FILE" | jq -r '.format.tags.creation_time')

  local filename=$(basename $FILE)
  # If creation_time is not available, try getting it from filename
  if [[ "$creation_time" == "null" || -z "$creation_time" ]]; then
    # Use regex to match the encoded timestamp in the filename
    if [[ $filename =~ ^FILE([0-9]{6})-([0-9]{6}) ]]; then
      # Extract the encoded date and time
      encoded_date=${BASH_REMATCH[1]}
      encoded_time=${BASH_REMATCH[2]}
      
      # Extract year, month, day, hour, minute, second
      year="20${encoded_date:0:2}"
      month=${encoded_date:2:2}
      day=${encoded_date:4:2}
      hour=${encoded_time:0:2}
      minute=${encoded_time:2:2}
      second=${encoded_time:4:2}
      
      # Create a formatted timestamp
      creation_time="$year-$month-${day}T$hour:$minute:$second"

      # Set the creation_time attribute
      ffmpeg -i "v" -metadata creation_time="$creation_time" -codec copy "${$FILE%.*}_new.${$FILE##*.}"

      # Check if the command was successful
      if [[ $? -eq 0 ]]; then
        echo "creation_time has been set to $creation_time for $FILE"
        mv "${FILE%.*}_new.${FILE##*.}" "$file_path"
      else
        echo "Failed to set creation_time for $FILE"
      fi
    fi
  fi

  # If creation_time is not available, use file modification time
  if [[ "$creation_time" == "null" || -z "$creation_time" ]]; then
#    creation_time=$(stat -c %y "$file")
    echo "$FILE has no creation_time"
  else
    # Extract year and month from the creation time
    local year=$(date -d "$creation_time" +"%Y")
    local month=$(date -d "$creation_time" +"%m")
    
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
#  mimetype=$(mimetype -b "$1")
  mimetype=$(file --mime-type --no-pad $1| awk '{print  $2}')

  case $mimetype in
    image/*)
      do_image "$1"
      ;;
    video/*)
      do_video "$1"
      ;;
    *)
      echo "$1 is neither an image nor a video"
      rm -rf $(dirname $1)
      ;;
  esac
else
  echo "Discarding $1"
  rm -rf $(dirname $1)
fi
