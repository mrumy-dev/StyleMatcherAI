import Foundation

struct APIKeys {
    
    struct Supabase {
        static let url = "YOUR_SUPABASE_URL_HERE"
        static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
        static let serviceRoleKey = "YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE"
    }
    
    struct RevenueCat {
        static let publicKey = "YOUR_REVENUECAT_PUBLIC_KEY_HERE"
    }
    
    struct OpenAI {
        static let apiKey = "YOUR_OPENAI_API_KEY_HERE"
    }
    
    struct GoogleVision {
        static let apiKey = "YOUR_GOOGLE_VISION_API_KEY_HERE"
    }
    
    struct Analytics {
        static let mixpanelToken = "YOUR_MIXPANEL_TOKEN_HERE"
        static let amplitudeKey = "YOUR_AMPLITUDE_KEY_HERE"
    }
    
    struct Social {
        static let facebookAppId = "YOUR_FACEBOOK_APP_ID_HERE"
        static let googleClientId = "YOUR_GOOGLE_CLIENT_ID_HERE"
    }
    
    struct Weather {
        static let openWeatherMapApiKey = "YOUR_OPENWEATHERMAP_API_KEY_HERE"
    }
}

// MARK: - Instructions
/*
 To use this template:
 
 1. Copy this file to APIKeys.swift
 2. Replace all "YOUR_*_HERE" placeholders with actual API keys
 3. Never commit APIKeys.swift to version control
 4. Add APIKeys.swift to .gitignore (already done)
 
 Example usage in your app:
 
 let supabaseClient = SupabaseClient(
     supabaseURL: URL(string: APIKeys.Supabase.url)!,
     supabaseKey: APIKeys.Supabase.anonKey
 )
 
 Note: Keep your API keys secure and never expose them in client-side code
 when possible. Use environment-specific keys for different deployment stages.
*/