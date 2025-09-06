import SwiftUI
import CoreLocation

struct ForecastOutfitPlannerView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var plannerViewModel = ForecastOutfitPlannerViewModel()
    @StateObject private var locationService = LocationService()
    @State private var showLocationPermission = false
    @State private var selectedDay: DailyForecast?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if weatherViewModel.isLoadingWeather {
                        loadingView
                    } else if let forecast = weatherViewModel.forecast {
                        forecastPlannerContent(forecast)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("5-Day Outfit Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Use Location") {
                            if locationService.canRequestLocation {
                                showLocationPermission = true
                            }
                        }
                        
                        Button("Refresh Weather") {
                            Task {
                                await weatherViewModel.refreshWeather()
                                if let forecast = weatherViewModel.forecast {
                                    await plannerViewModel.generateForecastPlans(forecast: forecast)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showLocationPermission) {
                LocationPermissionView(
                    onPermissionGranted: { location in
                        Task {
                            await weatherViewModel.updateWeatherForLocation(location)
                            if let forecast = weatherViewModel.forecast {
                                await plannerViewModel.generateForecastPlans(forecast: forecast)
                            }
                        }
                        showLocationPermission = false
                    },
                    onDismiss: {
                        showLocationPermission = false
                    }
                )
            }
            .sheet(item: $selectedDay) { day in
                DailyOutfitPlanView(
                    dailyForecast: day,
                    outfitSuggestions: plannerViewModel.getOutfitSuggestions(for: day.date)
                )
            }
            .task {
                if locationService.isLocationAuthorized && !weatherViewModel.hasWeatherData {
                    do {
                        let location = try await locationService.getCurrentLocation()
                        await weatherViewModel.updateWeatherForLocation(location)
                        if let forecast = weatherViewModel.forecast {
                            await plannerViewModel.generateForecastPlans(forecast: forecast)
                        }
                    } catch {
                        // Handle location error silently
                    }
                }
            }
            .alert("Weather Error", isPresented: $weatherViewModel.showWeatherError) {
                Button("OK") {
                    weatherViewModel.clearWeatherError()
                }
            } message: {
                Text(weatherViewModel.weatherError ?? "Unknown weather error")
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading weather forecast...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Weather Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enable location services to get a 5-day weather forecast and outfit suggestions for each day.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Get Location") {
                showLocationPermission = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    @ViewBuilder
    private func forecastPlannerContent(_ forecast: WeatherForecast) -> some View {
        VStack(spacing: 16) {
            headerSection(forecast)
            
            ForEach(forecast.next5Days) { dailyForecast in
                DailyForecastCard(
                    dailyForecast: dailyForecast,
                    outfitSuggestions: plannerViewModel.getOutfitSuggestions(for: dailyForecast.date),
                    isLoading: plannerViewModel.isGeneratingPlans
                ) {
                    selectedDay = dailyForecast
                }
            }
        }
    }
    
    @ViewBuilder
    private func headerSection(_ forecast: WeatherForecast) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Weather Forecast")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(forecast.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if plannerViewModel.isGeneratingPlans {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Planning outfits...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Tap any day to see detailed outfit suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct DailyForecastCard: View {
    let dailyForecast: DailyForecast
    let outfitSuggestions: [OutfitWithScore]
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Weather Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dailyForecast.dayOfWeek)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(dailyForecast.shortDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: dailyForecast.condition.icon)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(dailyForecast.maxTemperature.rounded()))°")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("\(Int(dailyForecast.minTemperature.rounded()))°")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Weather Details
                HStack {
                    weatherDetail(
                        icon: "humidity",
                        value: "\(dailyForecast.humidity)%"
                    )
                    
                    Spacer()
                    
                    weatherDetail(
                        icon: "wind",
                        value: "\(Int(dailyForecast.windSpeed.rounded())) km/h"
                    )
                    
                    Spacer()
                    
                    if dailyForecast.precipitationChance > 0 {
                        weatherDetail(
                            icon: "cloud.rain",
                            value: "\(Int(dailyForecast.precipitationChance))%"
                        )
                    } else {
                        weatherDetail(
                            icon: "sun.max",
                            value: "Clear"
                        )
                    }
                }
                
                Divider()
                
                // Outfit Suggestions Preview
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating outfit suggestions...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if outfitSuggestions.isEmpty {
                    Text("Tap to generate outfit suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Outfit Suggestions")
                                .font(.caption)
                                .fontWeight(.medium)
                                .textCase(.uppercase)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(outfitSuggestions.count) options")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(outfitSuggestions.prefix(3), id: \.outfit.id) { suggestion in
                                    OutfitPreviewCard(outfitWithScore: suggestion)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func weatherDetail(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct OutfitPreviewCard: View {
    let outfitWithScore: OutfitWithScore
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(outfitWithScore.outfit.items.prefix(3), id: \.id) { item in
                    AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay {
                                Image(systemName: getCategoryIcon(item.category))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                    }
                    .frame(width: 16, height: 16)
                    .cornerRadius(2)
                }
            }
            
            Text("\(Int(outfitWithScore.score.total))")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(getScoreColor(outfitWithScore.score.total))
        }
        .padding(6)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(6)
    }
    
    private func getCategoryIcon(_ category: ClothingCategory) -> String {
        switch category {
        case .tops: return "tshirt"
        case .bottoms: return "pants"
        case .dresses: return "dress"
        case .shoes: return "shoe"
        case .outerwear: return "jacket"
        case .accessories: return "bag"
        default: return "tshirt"
        }
    }
    
    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct DailyOutfitPlanView: View {
    let dailyForecast: DailyForecast
    let outfitSuggestions: [OutfitWithScore]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    weatherSummary
                    
                    if outfitSuggestions.isEmpty {
                        emptyOutfitSuggestions
                    } else {
                        outfitSuggestionsSection
                    }
                }
                .padding()
            }
            .navigationTitle(dailyForecast.dayOfWeek)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var weatherSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weather")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(dailyForecast.shortDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: dailyForecast.condition.icon)
                        .font(.title)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading) {
                        Text("\(Int(dailyForecast.maxTemperature.rounded()))°C")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(dailyForecast.description.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Low: \(Int(dailyForecast.minTemperature.rounded()))°C")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Humidity: \(dailyForecast.humidity)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if dailyForecast.precipitationChance > 0 {
                        Text("Rain: \(Int(dailyForecast.precipitationChance))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var emptyOutfitSuggestions: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Outfit Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Add more items to your wardrobe to get outfit suggestions for this weather.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var outfitSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Outfit Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(outfitSuggestions.count) options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(outfitSuggestions, id: \.outfit.id) { suggestion in
                    CompactOutfitCard(outfitWithScore: suggestion)
                }
            }
        }
    }
}

struct CompactOutfitCard: View {
    let outfitWithScore: OutfitWithScore
    
    var body: some View {
        HStack(spacing: 12) {
            // Outfit Items Preview
            LazyHStack(spacing: -8) {
                ForEach(outfitWithScore.outfit.items.prefix(4), id: \.id) { item in
                    AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .overlay {
                                Image(systemName: getCategoryIcon(item.category))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                    }
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    }
                }
            }
            
            // Outfit Details
            VStack(alignment: .leading, spacing: 4) {
                Text(outfitWithScore.outfit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(outfitWithScore.outfit.formality.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text("\(outfitWithScore.outfit.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score
            VStack {
                Text(outfitWithScore.score.grade)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(getScoreColor(outfitWithScore.score.total))
                
                Text("\(Int(outfitWithScore.score.total))/100")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(getScoreColor(outfitWithScore.score.total).opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getCategoryIcon(_ category: ClothingCategory) -> String {
        switch category {
        case .tops: return "tshirt"
        case .bottoms: return "pants"
        case .dresses: return "dress"
        case .shoes: return "shoe"
        case .outerwear: return "jacket"
        case .accessories: return "bag"
        default: return "tshirt"
        }
    }
    
    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

#Preview {
    ForecastOutfitPlannerView()
}