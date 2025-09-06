import SwiftUI

struct ContentView: View {
    @State private var showingOnboarding = false
    
    var body: some View {
        if showingOnboarding {
            OnboardingView {
                showingOnboarding = false
            }
        } else {
            MainTabView()
        }
    }
}

struct OnboardingView: View {
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                    
                    Text("StyleMatcher AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your AI-Powered Style Assistant")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    OnboardingFeature(
                        icon: "camera.fill",
                        title: "Smart Scanning",
                        description: "AI analyzes your clothes automatically"
                    )
                    
                    OnboardingFeature(
                        icon: "sparkles",
                        title: "Style Recommendations",
                        description: "Get personalized outfit suggestions"
                    )
                    
                    OnboardingFeature(
                        icon: "square.grid.2x2",
                        title: "Organize & Track",
                        description: "Keep your wardrobe organized effortlessly"
                    )
                }
                
                Spacer()
                
                Button(action: onComplete) {
                    HStack {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}