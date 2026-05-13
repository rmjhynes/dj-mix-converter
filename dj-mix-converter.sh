#!/usr/bin/env bash

# Location of .wav files saved from Rekordbox
TARGET_DIR="${HOME}/Music/rekordbox/Recording"
OUTPUT_DIR="${TARGET_DIR}/mp3"
mkdir -p "$OUTPUT_DIR"

# Create logs and output directories
TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")
mkdir -p logs
LOG_FILE="logs/mix_conversion_${TIMESTAMP}.log"

# Create log file header
{
  echo "DJ Mix Conversion Log - $(date)"
  echo "=========================================="
  echo ""
} > "$LOG_FILE"

# Find all .wav files in target directory and read them into an array.
# Using `find -print0` with a null-delimited `read` loop preserves filenames
# that contain spaces (a plain `for file in $(find ...)` would word-split them).
WAV_FILES=()
while IFS= read -r -d '' file; do
  WAV_FILES+=("$file")
done < <(find "$TARGET_DIR" -type f -name '*.wav' -print0)

# Iterate over list of files and convert to .mp3.
# Quoting "${WAV_FILES[@]}" expands each array element as a single argument,
# so paths with spaces stay intact.
for file in "${WAV_FILES[@]}"; do

  # Get file name from absolute path, stripping the .wav extension.
  # ${file%.wav} removes the trailing ".wav" via parameter expansion.
  name=$(basename "${file%.wav}")

  # Convert to mp3 with ffmpeg and tee output to log file
  ## -n: skip creating output if it already exists
  ## -codec:a libmp3lame: audio codec - use LAME to encode MP3
  ## -b:a 320k: audio bitrate - set constant 320 kbps
  ffmpeg -n -i "$file" -codec:a libmp3lame -b:a 320k "${OUTPUT_DIR}/${name}.mp3" 2>&1 | tee -a "$LOG_FILE"

  {
    echo ""
    echo "=========================================="
    echo ""
  } >> "$LOG_FILE"
done

echo "File(s) converted and stored in $OUTPUT_DIR" | tee -a "$LOG_FILE"

# Give user option to delete original files
read -p "Would you like to delete the original (.wav and .cue) files? (y/n) " delete

if [ $delete = 'y' ]; then

  echo "" >> "$LOG_FILE"

  # Iterate the same array we built above; quoting "${WAV_FILES[@]}"
  # keeps filenames with spaces intact.
  for file in "${WAV_FILES[@]}"; do
    # Strip the .wav extension so we can rebuild paths for both extensions.
    base="${file%.wav}"
    for ext in wav cue; do
      target="${base}.${ext}"
      if [ -f "$target" ]; then
        rm "$target"
        echo "Deleted: $target" >> "$LOG_FILE"
      else
        echo "Skipped (not found): $target" >> "$LOG_FILE"
      fi
    done
  done
  
  echo "" >> "$LOG_FILE"
  echo "Original (.wav and .cue) files deleted where found" | tee -a "$LOG_FILE"
fi
