#!/bin/bash
# Xcode Cloud post-clone setup for Capacitor iOS
set -euxo pipefail

# Always operate from repo root (so package.json is found)
ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(git rev-parse --show-toplevel)}"
cd "$ROOT"

echo ">>> POST-CLONE on commit $(git rev-parse --short HEAD)"
echo "PWD: $PWD"

# ---- Ensure Node & npm are available via NVM ----
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
node -v
npm -v

# ---- Install JS deps ----
npm ci

# ---- Capacitor source headers safety net ----
# Some npm tarballs omit ios sources; fetch from upstream if missing.
if [ ! -d "node_modules/@capacitor/ios/Capacitor" ] || [ ! -d "node_modules/@capacitor/ios/CapacitorCordova" ]; then
  echo "Capacitor iOS sources missing; fetching from upstream…"
  git clone --depth 1 --branch 7.4.3 https://github.com/ionic-team/capacitor tmp_cap_ios
  rsync -a tmp_cap_ios/ios/Capacitor        node_modules/@capacitor/ios/ || true
  rsync -a tmp_cap_ios/ios/CapacitorCordova node_modules/@capacitor/ios/ || true
  rm -rf tmp_cap_ios
fi

# ---- Sync native & install Pods ----
npx cap sync ios
( cd ios/App && pod install )

echo ">>> POST-CLONE completed."
