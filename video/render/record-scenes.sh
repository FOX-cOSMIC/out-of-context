#!/bin/zsh
# Record the real app in the iOS Simulator, one clip per video scene, using the app's own demo
# launch arguments (ios/CareCompanion/DemoLaunch.swift, docs/demo-launch-args.md).
# Needs: Xcode, the app installed on a booted Simulator, and the helper server running (npm start).
# Then run: python3 video/render/build.py   -> uses these clips inside the phone frame.
#
# Usage: SIM=<udid or "booted"> zsh video/render/record-scenes.sh
set -e
SIM=${SIM:-booted}
APP=com.outofcontext.carecompanion
OUT="${0:A:h}/clips"; mkdir -p "$OUT"

rec() {   # rec <name> <seconds> <launch args...>
  local name=$1 secs=$2; shift 2
  echo "recording $name ($secs s)"
  xcrun simctl terminate $SIM $APP 2>/dev/null || true
  sleep 1
  xcrun simctl io $SIM recordVideo --codec h264 --force "$OUT/$name.mp4" & local pid=$!
  sleep 1
  xcrun simctl launch $SIM $APP "$@" >/dev/null
  sleep $secs
  kill -INT $pid; wait $pid 2>/dev/null || true
}

rec home    16 -demoReset
rec call    26 -demoReset -testCall -testCallAccept
rec scan    28 -demoReset -demoScan sample-amlodipine -demoTapYes
rec safety  22 -demoReset -demoAsk "Can I skip my Metformin today?"
rec memory  18 -demoReset -demoAsk "How did I do with my pills this week?"
rec family  20 -demoReset -testFamilyCall
xcrun simctl terminate $SIM $APP 2>/dev/null || true
echo "clips in $OUT"
