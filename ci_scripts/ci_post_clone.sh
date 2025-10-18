#!/bin/bash
set -euo pipefail
set -x

npm ci
npx cap sync ios

cd ios/App
pod install

