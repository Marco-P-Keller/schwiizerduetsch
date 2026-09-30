#!/bin/zsh
# Usage: scripts/run_sim.sh <out.png> [launch args...]
SIM=E631CD4F-3293-4D70-A81F-453107BF207E
OUT=$1; shift
cd "$(dirname "$0")/.."
xcodebuild -project Schwiizerduetsch.xcodeproj -scheme Schwiizerduetsch -destination "id=$SIM" -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD FAILED" 
APP=$(xcodebuild -project Schwiizerduetsch.xcodeproj -scheme Schwiizerduetsch -destination "id=$SIM" -configuration Debug -showBuildSettings CODE_SIGNING_ALLOWED=NO 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $2}')/Schwiizerduetsch.app
xcrun simctl terminate $SIM com.connexa.schweizerdeutsch 2>/dev/null
xcrun simctl install $SIM "$APP"
xcrun simctl status_bar $SIM override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 2>/dev/null
xcrun simctl launch $SIM com.connexa.schweizerdeutsch "$@" >/dev/null
sleep 6
xcrun simctl io $SIM screenshot "$OUT" 2>&1 | tail -1
