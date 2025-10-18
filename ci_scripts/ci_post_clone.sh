#!/bin/bash
set -euo pipefail
set -x
echo ">>> CI POST-CLONE RAN (commit: $(git rev-parse --short HEAD))"

# 1) Install Node deps
npm ci

# 2) Ensure CapacitorCordova sources exist (some npm tarballs omit them)
if [ ! -d "node_modules/@capacitor/ios/CapacitorCordova" ]; then
  git clone --depth 1 --branch 7.4.3 https://github.com/ionic-team/capacitor tmp_cap_ios
  rsync -a tmp_cap_ios/ios/CapacitorCordova node_modules/@capacitor/ios/
  rm -rf tmp_cap_ios
fi

# 3) Sync native
npx cap sync ios

# 4) Install Pods (creates/updates App.xcworkspace)
cd ios/App
pod install
