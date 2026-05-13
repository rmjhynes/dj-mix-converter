#!/usr/bin/env bash

set -o pipefail

# If figlet is available, print the name of the tool in funky text style
if command -v figlet &>/dev/null; then
  figlet -f graffiti DJ Mix Converter
  echo
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is not installed. Install it and try again." >&2
  exit 1
fi

# Location of .wav files saved from Rekordbox
TARGET_DIR="${HOME}/Music/rekordbox/Recording"
OUTPUT_DIR="${TARGET_DIR}/mp3"
mkdir -p "$OUTPUT_DIR"

# Create logs directory next to the script itself rather than dir where script
# is called
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p "$SCRIPT_DIR/logs"
LOG_FILE="$SCRIPT_DIR/logs/mix_conversion_${TIMESTAMP}.log"

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

if [ ${#WAV_FILES[@]} -eq 0 ]; then
  echo "No .wav files found in $TARGET_DIR" | tee -a "$LOG_FILE"
  exit 0
fi

# Iterate over list of files and convert to .mp3.
# Quoting "${WAV_FILES[@]}" expands each array element as a single argument,
# so paths with spaces stay intact.
for file in "${WAV_FILES[@]}"; do

  # Get file name from absolute path, stripping the .wav extension.
  # ${file%.wav} removes the trailing ".wav" via parameter expansion.
  name=$(basename "${file%.wav}")

  echo "Converting ${name}.wav to .mp3..."

  # Convert to mp3 with ffmpeg and tee output to log file
  ## -hide_banner: suppress build/library version block
  ## -loglevel warning: only print warnings and errors
  ## -stats: keep live progress line (size/time/bitrate)
  ## -n: skip creating output if it already exists
  ## -codec:a libmp3lame: audio codec - use LAME to encode MP3
  ## -b:a 320k: audio bitrate - set constant 320 kbps
  ffmpeg -hide_banner -loglevel warning -stats -n -i "$file" -codec:a libmp3lame -b:a 320k "${OUTPUT_DIR}/${name}.mp3" 2>&1 | tee -a "$LOG_FILE"

  {
    echo ""
    echo "=========================================="
    echo ""
  } >> "$LOG_FILE"
done

echo "File(s) converted and stored in $OUTPUT_DIR" | tee -a "$LOG_FILE"

# Give user option to delete original files
read -p "Would you like to delete the original (.wav and .cue) files? (y/n) " delete

if [[ "$delete" =~ ^[Yy]([Ee][Ss])?$ ]]; then

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
