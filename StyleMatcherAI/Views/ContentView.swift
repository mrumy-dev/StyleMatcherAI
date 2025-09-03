import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.primary)
                
                Text("StyleMatcherAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI-Powered Style Assistant")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    // TODO: Navigate to onboarding or main app
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

#Preview {
    ContentView()
}