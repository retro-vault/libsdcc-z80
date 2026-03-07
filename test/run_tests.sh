#!/bin/sh
#
# run_tests.sh
#
# Run CP/M .COM test binaries under RunCPM and capture results.
# Each test result is written to bin/<name>.txt.
#
# Usage: run_tests.sh <name> [name ...]
#   name  - test binary name without extension (e.g. ftest)
#           must match a file in /src/bin/<name>.com
#

BINDIR=/src/bin
RESDIR=/src/bin

mkdir -p "$RESDIR"

for TEST in "$@"; do
    COM=$(echo "$TEST" | tr '[:lower:]' '[:upper:]')
    COMFILE="${BINDIR}/${TEST}.com"
    OUTFILE="${RESDIR}/${TEST}.txt"

    if [ ! -f "$COMFILE" ]; then
        printf "SKIP %s: %s not found\n" "$TEST" "$COMFILE"
        printf "SKIP %s: binary not found\n" "$TEST" > "$OUTFILE"
        continue
    fi

    # Set up RunCPM workspace: directory A/0 simulates CP/M drive A: user 0.
    WORK=$(mktemp -d)
    mkdir -p "${WORK}/A/0"
    cp "$COMFILE" "${WORK}/A/0/${COM}.COM"

    printf "Running %s ...\n" "$TEST"

    # Pipe the command into RunCPM stdin; timeout kills hung tests after 30s.
    # Strip the RunCPM banner, CP/M prompts, and blank lines from output.
    {
        cd "$WORK"
        printf '%s\r\n' "$COM" | timeout 30 RunCPM 2>/dev/null
    } | tr -d '\r' \
      | awk '
            /^[A-Z][0-9]*>/          { next }
            /CP.M Emulator/          { next }
            /RunCPM Version/         { next }
            /^  CP.M Emulator/       { next }
            /Built [A-Z]/            { next }
            /^CPU is /               { next }
            /T-states|MHz/           { next }
            /BIOS at|BDOS at/        { next }
            /BIOS.BDOS/              { next }
            /^CCP |^FILEBASE/        { next }
            /^-+$/                   { next }
            /^[[:space:]]*$/         { next }
            { print }
        ' \
      > "$OUTFILE" 2>/dev/null || true

    rm -rf "$WORK"

    printf "=== %s ===\n" "$TEST"
    cat "$OUTFILE"
    printf "\n"
done
