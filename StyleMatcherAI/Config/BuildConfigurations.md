# Build Configurations Setup Guide

This guide will help you set up build configurations in Xcode for Debug, Staging, and Release environments.

## Step 1: Create Build Configurations

1. Open your project in Xcode
2. Select your project in the Navigator
3. Select your project target (not the app target)
4. Go to the "Info" tab
5. Under "Configurations", you should see Debug and Release
6. Click the "+" button and select "Duplicate 'Release' Configuration"
7. Name it "Staging"

## Step 2: Create Build Schemes

1. Go to Product → Scheme → Edit Scheme
2. Duplicate the existing scheme and rename it to "StyleMatcherAI Staging"
3. In the scheme settings:
   - Set Build Configuration to "Staging" for Run, Test, Profile, Analyze, and Archive
4. Create another scheme for "StyleMatcherAI Release" with Release configuration

## Step 3: Add Compiler Flags

1. Select your app target (StyleMatcherAI)
2. Go to "Build Settings"
3. Search for "Swift Compiler - Custom Flags"
4. Under "Other Swift Flags":
   - Debug: Add `-DDEBUG`
   - Staging: Add `-DSTAGING`
   - Release: Leave empty or add `-DPRODUCTION`

## Step 4: Configure App Icons and Bundle Identifiers (Optional)

You can set different bundle identifiers for each environment:

1. In Build Settings, search for "Product Bundle Identifier"
2. Set different identifiers:
   - Debug: `com.stylematcher.ai.dev`
   - Staging: `com.stylematcher.ai.staging`
   - Release: `com.stylematcher.ai`

## Step 5: Configure Info.plist per Environment

1. Create separate Info.plist files for each environment if needed
2. In Build Settings, search for "Info.plist File"
3. Set different paths for each configuration

## Step 6: Test Your Configuration

1. Switch between schemes using the scheme selector
2. Build and run to verify the correct environment is selected
3. Check that `Environment.current` returns the expected value
4. Verify API endpoints and feature flags work correctly

## Usage in Code

Your configuration system is now ready to use:

```swift
// Check current environment
print("Current environment: \(Environment.current.displayName)")

// Use environment-specific URLs
let apiURL = AppConfig.Network.baseURL

// Use feature flags
if AppConfig.FeatureFlags.isDebugMenuEnabled {
    // Show debug menu
}

// Environment-specific behavior
switch Environment.current {
case .development:
    // Development-specific code
case .staging:
    // Staging-specific code  
case .production:
    // Production-specific code
}
```

## Security Notes

- Never commit `APIKeys.swift` to version control
- Copy `APIKeys.template.swift` to `APIKeys.swift` and fill in real values
- Use different API keys for each environment when possible
- Consider using Xcode's User-Defined Build Settings for sensitive values

## Troubleshooting

- If schemes don't appear, restart Xcode
- Make sure Swift flags are set correctly for environment detection
- Verify bundle identifiers are unique for parallel installation
- Check that the correct scheme is selected when building