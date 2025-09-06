# Supabase Integration

This directory contains the complete Supabase integration for StyleMatcherAI, including database models, repositories, authentication, and Row Level Security helpers.

## Architecture Overview

### Core Components

1. **SupabaseClient.swift** - Singleton client for Supabase operations
2. **AuthService.swift** - Authentication service with SwiftUI integration
3. **Models** - Database models with comprehensive properties
4. **Repositories** - CRUD operations with business logic
5. **RLSHelpers.swift** - Row Level Security utilities

## Database Models

### User Model (`User.swift`)
- Complete user profile with subscription management
- User preferences and settings
- Onboarding state tracking
- Subscription tiers (Free, Premium, Pro)

### WardrobeItem Model (`WardrobeItem.swift`)
- Comprehensive clothing item properties
- Colors, patterns, materials, formality levels
- Care instructions and purchase information
- Usage tracking (times worn, last worn)

### Outfit Model (`Outfit.swift`)
- Outfit composition with item positions
- Weather conditions and seasonal appropriateness
- AI-generated scores and style tips
- Public/private visibility settings

### OutfitHistory Model (`OutfitHistory.swift`)
- Detailed wear tracking
- Mood, confidence, and feedback recording
- Photo storage and activity logging
- Analytics and pattern recognition

## Repositories

### UserRepository
- User CRUD operations
- Subscription management
- Preference updates
- User statistics and analytics

### WardrobeRepository
- Item management with advanced filtering
- Category, color, and pattern searches
- Usage tracking and statistics
- Archive/unarchive functionality

### OutfitRepository
- Outfit creation and management
- Weather-based recommendations
- Public outfit sharing
- AI score management

### OutfitHistoryRepository
- Comprehensive wear tracking
- Analytics and pattern analysis
- Photo and feedback management
- Historical data queries

## Authentication Service

The `AuthService` provides:
- Email/password authentication
- Social login (Apple, Google)
- Password reset functionality
- Profile management
- Session handling with SwiftUI integration

## Row Level Security

The `RLSHelpers` module provides:
- User ownership validation
- Security policy generation
- Safe query wrappers
- Access control utilities

## Configuration

The integration uses environment-based configuration:
- Development, staging, and production environments
- Secure credential management
- Feature flag integration

## Usage Examples

### Authentication
```swift
// Sign in
try await AuthService.shared.signInWithEmail("user@example.com", password: "password")

// Sign up
try await AuthService.shared.signUpWithEmail("user@example.com", password: "password")
```

### Repository Operations
```swift
// Create wardrobe item
let repository = WardrobeRepository()
let item = WardrobeItem(userId: userId, name: "Blue Jeans", category: .bottoms)
let createdItem = try await repository.createItem(item)

// Get user's items
let items = try await repository.getItems(for: userId)
```

### Security
```swift
// Validate ownership before operations
try item.validateOwnership()

// Create user-scoped query
let query = try RLSHelpers.shared.createUserScopedQuery(table: "wardrobe_items")
```

## Database Schema Requirements

The integration expects the following database tables with Row Level Security enabled:

1. `users` - User profiles and subscription data
2. `wardrobe_items` - Clothing items with detailed metadata
3. `outfits` - Outfit compositions and configurations
4. `outfit_history` - Wear tracking and analytics data

Each table should have proper RLS policies ensuring users can only access their own data, with exceptions for public outfit sharing.

## Best Practices

1. Always validate user ownership for data operations
2. Use the provided repository patterns for database access
3. Implement proper error handling for network operations
4. Follow the established authentication flow
5. Utilize the analytics and tracking features for insights

## Environment Setup

1. Configure your Supabase project URLs and keys in `Environment.swift`
2. Set up the database schema with appropriate RLS policies
3. Enable authentication providers as needed
4. Configure storage buckets for image uploads

This integration provides a robust foundation for the StyleMatcherAI app's data management and user authentication needs.