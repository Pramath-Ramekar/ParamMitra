#!/usr/bin/env bash

set -euo pipefail

# =========================
# Config
# =========================
INPUT_FILE="$1"
OUTPUT_DIR="output"
LOG_DIR="logs"
FINAL_OUTPUT="$OUTPUT_DIR/final_final_params.txt"

THREADS=10

# =========================
# Checks
# =========================
if [[ -z "$INPUT_FILE" || ! -f "$INPUT_FILE" ]]; then
  echo "[!] Usage: $0 live_subdomains.txt"
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

> "$FINAL_OUTPUT"

# =========================
# Dependency Check
# =========================
REQUIRED_TOOLS=(
  paramspider
  waybackurls
  arjun
  JSParser
  qsreplace
  parallel
)

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo "[!] Missing dependency: $tool"
    echo "[!] Please install it before running."
    exit 1
  fi
done

# =========================
# Helper
# =========================
dedupe() {
  sort -u | grep "?"
}

export -f dedupe

# =========================
# 1. ParamSpider
# =========================
echo "[+] Running ParamSpider"
cat "$INPUT_FILE" | parallel -j $THREADS '
  domain=$(echo {} | sed "s~https\?://~~")
  paramspider -d "$domain" --silent 2>>logs/paramspider.log
' | dedupe >> "$FINAL_OUTPUT"

# =========================
# 2. Waybackurls
# =========================
echo "[+] Running Waybackurls"
cat "$INPUT_FILE" | waybackurls 2>>logs/wayback.log \
| grep "=" \
| dedupe >> "$FINAL_OUTPUT"

# =========================
# 3. Arjun
# =========================
echo "[+] Running Arjun"
cat "$INPUT_FILE" | parallel -j $THREADS '
  arjun -u {} --silent 2>>logs/arjun.log
' | dedupe >> "$FINAL_OUTPUT"

# =========================
# 4. Extract JS URLs
# =========================
echo "[+] Extracting JS URLs"
cat "$INPUT_FILE" | waybackurls \
| grep "\.js$" \
| sort -u > "$OUTPUT_DIR/js_files.txt"

# =========================
# 5. JSParser
# =========================
echo "[+] Running JSParser"
cat "$OUTPUT_DIR/js_files.txt" | parallel -j $THREADS '
  JSParser {} 2>>logs/jsparser.log
' | dedupe >> "$FINAL_OUTPUT"

# =========================
# 6. Normalize with qsreplace
# =========================
echo "[+] Normalizing parameters"
cat "$FINAL_OUTPUT" \
| qsreplace FUZZ \
| dedupe > "$FINAL_OUTPUT.tmp"

mv "$FINAL_OUTPUT.tmp" "$FINAL_OUTPUT"

# =========================
# Final Cleanup
# =========================
sort -u "$FINAL_OUTPUT" -o "$FINAL_OUTPUT"

echo "[✓] Done!"
echo "[✓] Final output: $FINAL_OUTPUT"
echo "[✓] Logs stored in: $LOG_DIR"
