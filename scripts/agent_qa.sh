#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${AGENT_QA_OUTPUT_DIR:-$ROOT/artifacts/agent-qa}"
TIMEOUT_SECONDS="${AGENT_QA_TIMEOUT_SECONDS:-900}"
GAME="${AGENT_QA_GAME:-$(basename "$ROOT")}"
SCENARIO="${AGENT_QA_SCENARIO:-}"
if [[ -z "$SCENARIO" ]]; then
  case "$GAME" in
    market|market-of-ash) SCENARIO="qa/scenarios/market_ordinary_trade_round_trip.json" ;;
    pack|pack-the-keep) SCENARIO="qa/scenarios/pack_greywatch_three_wave.json" ;;
    long|the-long-march) SCENARIO="qa/scenarios/long_march_complete_journey.json" ;;
  esac
fi
GODOT_BIN="${GODOT_BIN:-godot}"
if [[ "$GODOT_BIN" == */* ]]; then
  export PATH="$(dirname "$GODOT_BIN"):$PATH"
fi
mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$ROOT/scripts/verify.sh" ]]; then
  echo "AGENT_QA_CONFIG_ERROR: scripts/verify.sh is missing" >&2
  exit 2
fi

set +e
python3 "$ROOT/tools/agent_qa_runner.py" \
  --game "$GAME" \
  --output "$OUTPUT_DIR" \
  --timeout "$TIMEOUT_SECONDS" \
  ${SCENARIO:+--scenario "$SCENARIO"} \
  --verify bash scripts/verify.sh
STATUS=$?
set -e

if [[ "${AGENT_QA_CAPTURE:-1}" == "1" ]]; then
  CAPTURE_DIR="$OUTPUT_DIR/title-capture"
  mkdir -p "$CAPTURE_DIR"
  export GODOT_BIN
  if command -v xvfb-run >/dev/null 2>&1; then
    xvfb-run -a --server-args='-screen 0 1280x720x24' \
      "$GODOT_BIN" --path "$ROOT" --editor --quit-after 2 \
      --script res://tools/agent_qa_capture.gd \
      -- --output="$CAPTURE_DIR" --state=title --width=1280 --height=720 --frames=8 \
      > "$OUTPUT_DIR/capture.stdout.log" 2> "$OUTPUT_DIR/capture.stderr.log"
  else
    "$GODOT_BIN" --path "$ROOT" --editor --quit-after 2 \
      --script res://tools/agent_qa_capture.gd \
      -- --output="$CAPTURE_DIR" --state=title --width=1280 --height=720 --frames=8 \
      > "$OUTPUT_DIR/capture.stdout.log" 2> "$OUTPUT_DIR/capture.stderr.log"
  fi
  CAPTURE_STATUS=$?
  if [[ "$CAPTURE_STATUS" -ne 0 ]]; then
    echo "AGENT_QA_CAPTURE_FAILED: see $OUTPUT_DIR/capture.stderr.log" >&2
    STATUS=1
  fi
fi

exit "$STATUS"
