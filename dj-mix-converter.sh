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

# Find all .wav files in target directory and remove the file extension
WAV_FILES=$(find $TARGET_DIR -type f -name '*.wav' | cut -f 1 -d '.')

# Iterate over list of files and convert to .mp3
for file in $WAV_FILES; do

  # Get file name from absolute path
  name=$(basename "$file")

  # Convert to mp3 with ffmpeg and tee output to log file
  ffmpeg \
    -n \                            # skip creating output if it already exists
    -i "$file.wav" \
    -codec:a libmp3lame \           # audio codec - use LAME to encode MP3
    -b:a 320k \                     # audio bitrate - set constant 320 kbps
    "$OUTPUT_DIR/${name}.mp3" 2>&1 | tee -a "$LOG_FILE"

  {
    echo ""
    echo "=========================================="
    echo ""
  } >> "$LOG_FILE"
done

echo "File(s) converted and stored in $OUTPUT_DIR" | tee -a "$LOG_FILE"
