// capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.tapedecktimemachine.app',
  appName: 'TapeDeck Time Machine',
  webDir: 'docs',
  bundledWebRuntime: false,

  server: {
    // Force the app to load your site over HTTPS (not the bundled files)
    url: 'https://tapedecktimemachine.com',
    cleartext: false,

    // Keep these for Android parity / future
    hostname: 'tapedecktimemachine.com',
    iosScheme: 'https',
    androidScheme: 'https',
    allowNavigation: [
      'timedeck-api.onrender.com',
      'apple.com','*.apple.com','idmsa.apple.com','authorize.music.apple.com','*.music.apple.com',
      '*.youtube.com','*.youtube-nocookie.com','*.googlevideo.com','*.google.com','*.gstatic.com','*.ytimg.com','*.doubleclick.net'
    ],
  },

  ios: { contentInset: 'always' },
  plugins: { SplashScreen: { launchShowDuration: 0 } },
};

export default config;
