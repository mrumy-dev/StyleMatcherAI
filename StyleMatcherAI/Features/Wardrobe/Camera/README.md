# Camera Capture and Image Processing System

This directory contains a comprehensive camera capture and image processing system designed specifically for the StyleMatcherAI wardrobe feature. The system provides full-featured camera functionality, photo library access, image processing, cloud storage integration, and optimized thumbnail generation.

## Architecture Overview

### Core Components

1. **CameraViewModel.swift** - AVFoundation-based camera management
2. **CameraView.swift** - SwiftUI camera interface with preview
3. **PhotoLibraryPicker.swift** - Enhanced photo library selection
4. **ImageCaptureCoordinator.swift** - Unified image capture flow
5. **WardrobeThumbnailView.swift** - Grid view thumbnails with caching

### Supporting Systems

1. **ImageProcessor.swift** - Image compression and processing utilities
2. **ImageUploadService.swift** - Supabase Storage integration
3. **ThumbnailCacheManager** - Efficient thumbnail caching

## Features

### Camera Functionality
- Real-time camera preview with AVFoundation
- Front/back camera switching
- Flash toggle with visual feedback
- Tap-to-focus and exposure control
- Photo capture with processing indicators
- Automatic image orientation correction
- Permission handling with user-friendly prompts

### Photo Library Integration
- Single and multiple photo selection
- Grid-based photo browser with thumbnails
- Permission management
- High-resolution image loading
- Selection indicators and progress tracking

### Image Processing
- Automatic image compression for upload optimization
- Multiple thumbnail size generation (150x150, 300x300, 600x600)
- Smart resizing maintaining aspect ratios
- Background removal placeholder (extensible)
- Metadata extraction (dimensions, file size, etc.)

### Cloud Storage
- Supabase Storage integration for wardrobe images
- Organized bucket structure (wardrobe-images, outfit-images, profile-images)
- Automatic thumbnail generation and upload
- Progress tracking for uploads
- Retry logic for failed uploads
- Storage usage monitoring and cleanup

### Thumbnail System
- Multiple size variants (small, medium, large)
- Efficient caching with NSCache
- Skeleton loading states
- Context menu actions
- Visual indicators (favorites, wear count, attention needed)
- Optimized grid layouts

## Usage Examples

### Basic Camera Capture
```swift
CameraView { image in
    // Handle captured image
    processWardrobeImage(image)
}
```

### Photo Library Selection
```swift
PhotoLibraryPicker(maxSelectionCount: 5) { images in
    // Handle selected images
    uploadWardrobeImages(images)
}
```

### Unified Image Capture
```swift
ImageCaptureCoordinator(
    maxSelectionCount: 3,
    allowsCamera: true,
    allowsPhotoLibrary: true
) { images in
    // Handle images from camera or library
    processImages(images)
}
```

### Wardrobe Grid Display
```swift
WardrobeGridView(
    items: wardrobeItems,
    columns: 2,
    thumbnailSize: .medium
) { item in
    // Handle item selection
    showItemDetails(item)
}
```

### Image Upload to Storage
```swift
let result = try await ImageUploadService.shared.uploadWardrobeImage(
    image,
    userId: currentUserId,
    itemId: wardrobeItemId
) { progress in
    updateProgressUI(progress)
}
```

## Component Details

### CameraViewModel
- **Permissions**: Automatic camera and photo library permission handling
- **Session Management**: AVCaptureSession configuration and lifecycle
- **Device Control**: Camera switching, flash, focus/exposure controls
- **Photo Capture**: High-quality image capture with processing
- **Error Handling**: Comprehensive error states and user feedback

### CameraView
- **UI Components**: Modern SwiftUI interface with controls
- **Preview Layer**: Real-time camera preview with touch controls
- **Visual Feedback**: Flash animation, processing indicators
- **Navigation**: Full-screen presentation with proper dismissal
- **Accessibility**: Proper labels and touch targets

### PhotoLibraryPicker
- **Grid Interface**: Responsive photo grid with thumbnails
- **Selection Logic**: Multi-selection with count limits
- **Performance**: Optimized image loading and memory management
- **User Experience**: Selection indicators, progress feedback

### ImageProcessor
- **Compression**: Smart compression maintaining quality
- **Resizing**: Aspect-ratio aware resizing
- **Thumbnails**: Multiple size generation for different use cases
- **Optimization**: Memory-efficient processing for large images
- **Metadata**: Comprehensive image information extraction

### ImageUploadService
- **Storage Integration**: Direct Supabase Storage uploads
- **Organization**: Structured file paths by user and type
- **Progress Tracking**: Real-time upload progress
- **Error Handling**: Retry logic and comprehensive error types
- **Batch Operations**: Multiple image uploads with coordination

### WardrobeThumbnailView
- **Display Options**: Multiple size variants and layouts
- **Caching**: Efficient image caching with Kingfisher
- **Interactions**: Context menus and tap handling
- **Visual States**: Loading, error, and placeholder states
- **Indicators**: Status badges for favorites, wear count, etc.

## Performance Optimizations

1. **Image Compression**: Automatic compression to target file sizes
2. **Thumbnail Caching**: Multi-level caching strategy
3. **Lazy Loading**: On-demand image loading in grids
4. **Memory Management**: Proper cleanup and cache limits
5. **Background Processing**: Non-blocking image operations
6. **Progress Feedback**: Real-time progress for long operations

## Error Handling

The system includes comprehensive error handling for:
- Camera unavailability or permission denial
- Photo library access restrictions
- Network failures during upload
- Image processing errors
- Storage quota exceeded
- Corrupted or invalid image data

## Accessibility Features

- VoiceOver support for all interactive elements
- Proper semantic labels and hints
- Minimum touch target sizes (44x44 points)
- High contrast support
- Dynamic Type support for text scaling

## Testing Considerations

- Mock camera functionality for simulator testing
- Sample image data for UI testing
- Error state simulation
- Permission flow testing
- Performance testing with large image sets

## Integration Requirements

### Permissions (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>StyleMatcher needs camera access to photograph your wardrobe items</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>StyleMatcher needs photo library access to select wardrobe images</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>StyleMatcher needs permission to save photos to your library</string>
```

### Dependencies
- AVFoundation (camera functionality)
- Photos/PhotosUI (photo library access)
- Kingfisher (image caching and loading)
- Supabase Storage (cloud storage)

This camera system provides a complete, production-ready solution for wardrobe image capture and management, designed specifically for the StyleMatcherAI use case with performance and user experience as top priorities.