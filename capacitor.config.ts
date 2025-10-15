import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.tapedecktimemachine.app',
  appName: 'TapeDeck Time Machine',
  // **FIXED**: Point to a dedicated 'docs' directory instead of the root.
  webDir: 'docs',
  // Setting bundledWebRuntime to false is standard for web-based apps.
  bundledWebRuntime: false
};

export default config;

