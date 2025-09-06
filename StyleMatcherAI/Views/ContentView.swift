import SwiftUI

struct ContentView: View {
    @State private var showingOnboarding = false
    
    var body: some View {
        if showingOnboarding {
            OnboardingView {
                showingOnboarding = false
            }
        } else {
            SimpleTabView()
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

struct SimpleTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SimpleHomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            SimpleWardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt")
                }
                .tag(1)
            
            SimpleAddView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            SimpleOutfitsView()
                .tabItem {
                    Label("Outfits", systemImage: "person.2")
                }
                .tag(3)
            
            SimpleProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
        }
    }
}

struct SimpleHomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to StyleMatcher AI")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your home for style management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

struct SimpleWardrobeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("My Wardrobe")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your clothing collection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Wardrobe")
        }
    }
}

struct SimpleAddView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Add New Item")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Scan or add clothing items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Take Photo") {
                    // TODO: Camera functionality
                }
                .buttonStyle(.borderedProminent)
                
                Button("Choose from Library") {
                    // TODO: Photo library
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Item")
        }
    }
}

struct SimpleOutfitsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("My Outfits")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your style combinations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Outfits")
        }
    }
}

struct SimpleProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("My Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your style preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
}