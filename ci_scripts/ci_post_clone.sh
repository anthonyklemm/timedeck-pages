#!/bin/bash
set -euo pipefail
set -x

# install node deps
npm ci

# sync native
npx cap sync ios

# DEBUG: prove CapacitorCordova headers exist
ls -la node_modules/@capacitor/ios/CapacitorCordova/CapacitorCordova/Classes/Public || true
ls -la node_modules/@capacitor/ios/CapacitorCordova/CapacitorCordova || true

# install pods (creates .xcworkspace)
cd ios/App
pod install