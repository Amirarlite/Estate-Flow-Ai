const fs = require('fs');
const path = require('path');

try {
  const dotenv = require('dotenv');
  const rootDir = path.resolve(__dirname, '..');

  // Load environment variables with proper priority:
  // 1. Process environment (system variables already in process.env)
  // 2. .env.local (if it exists)
  // 3. .env (if it exists)
  // Since dotenv.config() does not overwrite existing variables, we load .env.local first
  // so that its variables take precedence over .env.
  const envFiles = [
    path.join(rootDir, '.env.local'),
    path.join(rootDir, '.env'),
  ];

  envFiles.forEach((file) => {
    if (fs.existsSync(file)) {
      dotenv.config({ path: file });
    }
  });
} catch (e) {
  console.warn("Warning: dotenv could not be loaded. Environment variables from .env files might not be populated.", e.message);
}
