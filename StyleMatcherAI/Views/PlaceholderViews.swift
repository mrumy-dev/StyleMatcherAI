import SwiftUI

// MARK: - Placeholder Views for Navigation

struct AnalyticsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Coming Soon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Track your style preferences, most-worn items, and wardrobe insights")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
}

struct RecommendationsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("AI Recommendations")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Coming Soon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Get personalized style suggestions based on your wardrobe and preferences")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Recommendations")
        }
    }
}

struct OutfitDetailView: View {
    let outfit: Outfit
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text(outfit.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Outfit Details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Coming Soon")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Outfit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CreateOutfitView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Create Outfit")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Mix and match items from your wardrobe to create stylish outfits")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

struct EditOutfitView: View {
    let outfit: Outfit
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit \(outfit.name)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Outfit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("Theme")
                        Spacer()
                        Text("System")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    HStack {
                        Image(systemName: "ruler")
                        Text("Size System")
                        Spacer()
                        Text("US")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "dollarsign.circle")
                        Text("Currency")
                        Spacer()
                        Text("USD")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Privacy") {
                    HStack {
                        Image(systemName: "hand.raised")
                        Text("Data Privacy")
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PreferencesView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Style Preferences") {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("Preferred Style")
                        Spacer()
                        Text("Casual")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "person.badge.key")
                        Text("Formality Level")
                        Spacer()
                        Text("Smart Casual")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Sizing") {
                    HStack {
                        Image(systemName: "ruler")
                        Text("Size System")
                        Spacer()
                        Text("US")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SubscriptionView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Premium Features")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "camera.fill", text: "Unlimited item scanning")
                        FeatureRow(icon: "wand.and.stars", text: "AI outfit recommendations")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced analytics")
                        FeatureRow(icon: "cloud.fill", text: "Cloud backup")
                    }
                    
                    Button("Upgrade to Premium") {
                        // Handle subscription
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("StyleMatcher AI")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your AI-powered personal stylist")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HelpView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Getting Started") {
                    NavigationLink("Adding Items") {
                        HelpDetailView(title: "Adding Items", content: "Learn how to add clothing items to your wardrobe...")
                    }
                    
                    NavigationLink("Creating Outfits") {
                        HelpDetailView(title: "Creating Outfits", content: "Discover how to create and manage outfits...")
                    }
                }
                
                Section("Features") {
                    NavigationLink("AI Analysis") {
                        HelpDetailView(title: "AI Analysis", content: "Learn about our AI-powered clothing analysis...")
                    }
                    
                    NavigationLink("Style Recommendations") {
                        HelpDetailView(title: "Style Recommendations", content: "Get the most out of our recommendation engine...")
                    }
                }
                
                Section("Support") {
                    Button("Contact Support") {
                        // Handle contact
                    }
                    
                    Button("Report Bug") {
                        // Handle bug report
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HelpDetailView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Photo Library Picker Placeholder

struct PhotoLibraryPicker: View {
    let onImagesSelected: ([UIImage]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Photo Library")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Photo Library")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}