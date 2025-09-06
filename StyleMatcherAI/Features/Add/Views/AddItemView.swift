import SwiftUI

struct AddItemView: View {
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingManualEntry = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                headerSection
                addOptionsSection
                quickTipsSection
                Spacer()
            }
            .padding()
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(viewModel: CameraViewModel())
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoLibraryPicker { images in
                // Handle selected images
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            AddWardrobeItemView { item in
                // Handle new item
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Add New Item")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Capture or select photos of your clothing items and let AI do the rest")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var addOptionsSection: some View {
        VStack(spacing: 16) {
            AddOptionCard(
                title: "Take Photo",
                subtitle: "Use camera with AI analysis",
                icon: "camera.fill",
                color: .blue
            ) {
                showingCamera = true
            }
            
            AddOptionCard(
                title: "Choose from Library",
                subtitle: "Select existing photos",
                icon: "photo.stack.fill",
                color: .green
            ) {
                showingPhotoPicker = true
            }
            
            AddOptionCard(
                title: "Manual Entry",
                subtitle: "Enter details manually",
                icon: "pencil.circle.fill",
                color: .orange
            ) {
                showingManualEntry = true
            }
        }
    }
    
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips for Better Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(
                    icon: "lightbulb.fill",
                    text: "Use good lighting for clearer photos"
                )
                
                TipRow(
                    icon: "viewfinder",
                    text: "Center the item in the frame"
                )
                
                TipRow(
                    icon: "square.dashed",
                    text: "Lay items flat on a solid background"
                )
                
                TipRow(
                    icon: "cpu",
                    text: "AI will automatically detect colors and patterns"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    AddItemView()
}