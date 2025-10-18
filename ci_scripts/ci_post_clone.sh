
set -euo pipefail

npm ci

npx cap sync ios

cd ios/App

pod install

