#!/bin/env bash
# Moves photo and video files to a per "year/year-month" folder structure
#
# For every file the creation date/time is extracted from metadata
# when not available, it is extracted as timestamp from the filename
#
# Supported env vars
# DEST_DIR: the destination folder path, eventually containing a folder per year (mandatory)
# IGNORE_REGEX: bash regex for files to ignore
#
# Supported arguments:
# 1. file to process

DEST_DIR='' : "${DEST_DIR:?DEST_DIR is not set}"
[ -d "$DEST_DIR" ] || { echo "DEST_DIR does not exist: $DEST_DIR"; exit 2; }

IGNORE_REGEX="${IGNORE_REGEX:-.*(MV-PANO|COLLAGE|-ANIMATION|-EFFECTS)\..*)}"

function do_image () {
  local FILE="$1"
  local PARENT_DIR=$(dirname "$FILE")

  echo "PARENT_DIR: $PARENT_DIR"

  local creation_time=$(exiftool -DateTimeOriginal -d "%Y-%m-%d %H:%M:%S" "$FILE" | awk -F ': ' '{print $2}')

  local filename=$(basename "$FILE")
  # If creation_time is not available, try getting it from filename
  if [[ -z "$creation_time" ]]; then
    # Use regex to match the encoded timestamp in the filename
    if [[ "$filename" =~ ^.*([0-9]{8})_([0-9]{6}).* ]]; then
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

  creation_time=$(exiftool -DateTimeOriginal -d "%Y-%m-%d %H:%M:%S" "$FILE" | awk -F ': ' '{print $2}')

  # If creation_time is not available, move it to root
  if [[ "$creation_time" == "null" || -z "$creation_time" ]]; then
    echo "$FILE has no creation_time"
    mv "$FILE" "${PARENT_DIR}/"
  else

    # check if downloaded file has GPS data
    local has_gps=$(exiftool "$FILE" | grep GPS)

    # set file time
    exiftool "-DateTimeOriginal>FileModifyDate" "$FILE"

    # move file to proper subdir
    exiftool -d "${PARENT_DIR}/%Y/%Y-%m" '-directory<${DateTimeOriginal}' '-filename<${filename}' "$FILE"

    # move to destination folder
    cd "$PARENT_DIR"

    local new_filepath=$(find -name "$filename")
    local local_path=${new_filepath#"./"}
    echo "Moved image to $local_path"

    local obsoleted_file=$(find "$DEST_DIR" -wholename "*/$local_path")
    local prevent_sync=""
    if [[ -z "$obsoleted_file" ]]; then
      echo "No overwrite dilemma for $local_path"
    elif [[ -z "$has_gps" ]]; then
      echo "Checking if the overwrite of $obsoleted_file would cause loss of GPS data"
      # check if existing file has GPS data
      local target_has_gps=$(exiftool "$new_filepath" | grep GPS)
      if [[ -z "$target_has_gps" ]]; then
        prevent_sync="target GPS data would be lost"
      fi
    else
      echo "Downloaded file has GPS data"
    fi

    if [[ -z "$prevent_sync" ]]; then
      rsync \
        -av \
        --remove-source-files \
        --include='20[0-9][0-9]/' --include='20[0-9][0-9]/20[0-9][0-9]-[0-1][0-9]/' \
        . "$DEST_DIR"
    else
      echo "No rsync as $prevent_sync"
    fi
  fi

  rm -rf "$PARENT_DIR"
}

function do_video () {
  local FILE="$1"
  local PARENT_DIR=$(dirname "$FILE")

  echo "PARENT_DIR: $PARENT_DIR"

  local creation_time=$(ffprobe -v quiet -print_format json -show_entries format_tags=creation_time "$FILE" | jq -r '.format.tags.creation_time')

  local filename=$(basename "$FILE")
  # If creation_time is not available, try getting it from filename
  if [[ "$creation_time" == "null" || -z "$creation_time" ]]; then
    # Use regex to match the encoded timestamp in the filename
    if [[ "$filename" =~ ^FILE([0-9]{6})-([0-9]{6}) ]]; then
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
      ffmpeg -i "${FILE}" -metadata creation_time="$creation_time" -codec copy "${FILE%.*}_new.${FILE##*.}"

      # Check if the command was successful
      if [[ $? -eq 0 ]]; then
        echo "creation_time has been set to $creation_time for $FILE"
        mv "${FILE%.*}_new.${FILE##*.}" "$FILE"
      else
        echo "Failed to set creation_time for $FILE"
      fi
    fi
  fi

  # If creation_time is not available, move it to root
  if [[ "$creation_time" == "null" || -z "$creation_time" ]]; then
    echo "$FILE has no creation_time"
    mv "$FILE" "${PARENT_DIR}/"
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
    cd "$PARENT_DIR"
    rsync \
      -av \
      --remove-source-files \
      --include='20[0-9][0-9]/' --include='20[0-9][0-9]/20[0-9][0-9]-[0-1][0-9]/' \
      . "$DEST_DIR"

  fi

  rm -rf "$PARENT_DIR"
}

# Check if the file matches the regex in IGNORE_REGEX
base=$(basename "$1")
if [[ ! "$base" =~ $IGNORE_REGEX ]]; then
  echo "Processing: $1"
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
      rm -rf $(dirname "$1")
      ;;
  esac
else
  echo "Discarding $1"
  rm -rf $(dirname "$1")
fi
