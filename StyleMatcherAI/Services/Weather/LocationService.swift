import Foundation
import CoreLocation
import SwiftUI

@MainActor
class LocationService: NSObject, ObservableObject {
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var isUpdatingLocation = false
    
    private let locationManager = CLLocationManager()
    private var locationUpdateCompletion: ((Result<CLLocation, LocationError>) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // Update location when user moves 100 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Guide user to settings
            errorMessage = "Location access is required for weather-based outfit suggestions. Please enable location access in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            getCurrentLocation()
        @unknown default:
            break
        }
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            getCurrentLocation { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func getCurrentLocation(completion: @escaping (Result<CLLocation, LocationError>) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationUpdateCompletion = completion
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            completion(.failure(.locationPermissionDenied))
            
        case .authorizedWhenInUse, .authorizedAlways:
            locationUpdateCompletion = completion
            isUpdatingLocation = true
            locationManager.startUpdatingLocation()
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.isUpdatingLocation == true {
                    self?.locationManager.stopUpdatingLocation()
                    self?.isUpdatingLocation = false
                    completion(.failure(.locationTimeout))
                }
            }
            
        @unknown default:
            completion(.failure(.unknownError))
        }
    }
    
    func openLocationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    var canRequestLocation: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return CLLocationManager.locationServicesEnabled()
        case .notDetermined:
            return CLLocationManager.locationServicesEnabled()
        default:
            return false
        }
    }
    
    var isLocationAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    var locationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission not requested"
        case .denied:
            return "Location permission denied"
        case .restricted:
            return "Location access restricted"
        case .authorizedWhenInUse:
            return "Location authorized when in use"
        case .authorizedAlways:
            return "Location always authorized"
        @unknown default:
            return "Unknown location status"
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                errorMessage = nil
                if let completion = locationUpdateCompletion {
                    getCurrentLocation(completion: completion)
                }
                
            case .denied, .restricted:
                errorMessage = "Location access denied. Enable location services to get weather-based outfit suggestions."
                locationUpdateCompletion?(.failure(.locationPermissionDenied))
                locationUpdateCompletion = nil
                
            case .notDetermined:
                break
                
            @unknown default:
                errorMessage = "Unknown location authorization status"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newLocation = locations.last else { return }
            
            location = newLocation
            isUpdatingLocation = false
            manager.stopUpdatingLocation()
            
            locationUpdateCompletion?(.success(newLocation))
            locationUpdateCompletion = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isUpdatingLocation = false
            manager.stopUpdatingLocation()
            
            let locationError: LocationError
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .locationPermissionDenied
                case .network:
                    locationError = .networkError
                case .locationUnknown:
                    locationError = .locationNotAvailable
                default:
                    locationError = .unknownError
                }
            } else {
                locationError = .unknownError
            }
            
            errorMessage = locationError.localizedDescription
            locationUpdateCompletion?(.failure(locationError))
            locationUpdateCompletion = nil
        }
    }
}

enum LocationError: LocalizedError {
    case locationServicesDisabled
    case locationPermissionDenied
    case locationNotAvailable
    case locationTimeout
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .locationPermissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .locationNotAvailable:
            return "Current location is not available. Please try again."
        case .locationTimeout:
            return "Location request timed out. Please try again."
        case .networkError:
            return "Network error while getting location. Please check your connection."
        case .unknownError:
            return "An unknown error occurred while getting location."
        }
    }
}

struct LocationPermissionView: View {
    @StateObject private var locationService = LocationService()
    let onPermissionGranted: (CLLocation) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Location Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We use your location to provide weather-based outfit suggestions that match your local conditions.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                if locationService.isUpdatingLocation {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Getting your location...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = locationService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: handleLocationRequest) {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Skip for now") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .onChange(of: locationService.location) { _, newLocation in
            if let location = newLocation {
                onPermissionGranted(location)
            }
        }
    }
    
    private var buttonTitle: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Allow Location Access"
        case .denied, .restricted:
            return "Open Settings"
        case .authorizedWhenInUse, .authorizedAlways:
            return locationService.isUpdatingLocation ? "Getting Location..." : "Get Current Location"
        @unknown default:
            return "Request Location"
        }
    }
    
    private func handleLocationRequest() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestLocationPermission()
        case .denied, .restricted:
            locationService.openLocationSettings()
        case .authorizedWhenInUse, .authorizedAlways:
            Task {
                do {
                    let location = try await locationService.getCurrentLocation()
                    onPermissionGranted(location)
                } catch {
                    // Error is handled by the location service
                }
            }
        @unknown default:
            locationService.requestLocationPermission()
        }
    }
}

#Preview {
    LocationPermissionView(
        onPermissionGranted: { _ in },
        onDismiss: { }
    )
}