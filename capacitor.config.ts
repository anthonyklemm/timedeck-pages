import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.tapedecktimemachine.app',
  appName: 'TapeDeck Time Machine',
  webDir: 'docs', // This should point to your web assets folder
  bundledWebRuntime: false,
  // **NEW**: This server configuration is crucial for handling authentication redirects.
  server: {
    // This makes the app's internal server respond to your domain name, which is required for secure callbacks.
    hostname: 'tapedecktimemachine.com',
    iosScheme: 'https',
    androidScheme: 'https',
    // This is a security feature that whitelists the external domains your app is allowed to navigate to.
    allowNavigation: [
      // Allow your API backend
      'timedeck-api.onrender.com',
      // Allow Apple for authentication
      'apple.com',
      '*.apple.com',
      // Allow YouTube for the embedded player
      '*.youtube.com',
      '*.googlevideo.com' // YouTube media content is often served from here
    ]
  }
};

export default config;