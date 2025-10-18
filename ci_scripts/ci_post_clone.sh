#!/bin/bash
set -euo pipefail
set -x

# 0) Node deps
npm ci

# 1) Ensure CapacitorCordova sources exist in node_modules (some npm tarballs omit them)
if [ ! -d "node_modules/@capacitor/ios/CapacitorCordova" ]; then
  git clone --depth 1 --branch 7.4.3 https://github.com/ionic-team/capacitor tmp_cap_ios
  rsync -a tmp_cap_ios/ios/CapacitorCordova node_modules/@capacitor/ios/
  rm -rf tmp_cap_ios
fi

# 2) Sync native projects
npx cap sync ios

# 3) Install Pods (creates the .xcworkspace)
cd ios/App
pod install
