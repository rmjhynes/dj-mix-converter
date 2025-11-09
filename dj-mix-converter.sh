#!/usr/bin/env bash

# Location of .wav files saved from Rekordbox
TARGET_DIR="$HOME/Music/rekordbox/Recording"

# Find all .wav files in target directory
WAV_FILES=$(find $TARGET_DIR -type f -name '*.wav')

# Iterate over list of files and convert to .mp3
for file in $WAV_FILES; do
  # Get file name prefix (without .wav extension)
  name=$(basename "$file")

  # Convert to mp3 with ffmpeg
  ffmpeg -n -report -i "$file" -codec:a libmp3lame -b:a 320k "${name}.mp3"
done

echo "File conversion complete"
