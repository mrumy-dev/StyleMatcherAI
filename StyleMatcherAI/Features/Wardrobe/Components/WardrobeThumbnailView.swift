import SwiftUI
import Kingfisher

struct WardrobeThumbnailView: View {
    let item: WardrobeItem
    let size: ThumbnailSize
    let onTap: () -> Void
    
    @State private var isLoading = true
    @State private var loadError = false
    
    init(
        item: WardrobeItem,
        size: ThumbnailSize = .medium,
        onTap: @escaping () -> Void = {}
    ) {
        self.item = item
        self.size = size
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                thumbnailContent
                overlayContent
                
                if item.isFavorite {
                    favoriteIndicator
                }
                
                if item.needsAttention {
                    attentionIndicator
                }
            }
        }
        .buttonStyle(ThumbnailButtonStyle())
        .contextMenu {
            contextMenuContent
        }
    }
    
    private var thumbnailContent: some View {
        Group {
            if let thumbnailURL = item.thumbnailURL, !thumbnailURL.isEmpty {
                KFImage(URL(string: thumbnailURL))
                    .onSuccess { _ in
                        isLoading = false
                        loadError = false
                    }
                    .onFailure { _ in
                        isLoading = false
                        loadError = true
                    }
                    .placeholder {
                        placeholderView
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.dimension, height: size.dimension)
                    .clipped()
            } else if let firstImageURL = item.imageURLs.first {
                KFImage(URL(string: firstImageURL))
                    .onSuccess { _ in
                        isLoading = false
                        loadError = false
                    }
                    .onFailure { _ in
                        isLoading = false
                        loadError = true
                    }
                    .placeholder {
                        placeholderView
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.dimension, height: size.dimension)
                    .clipped()
            } else {
                placeholderView
            }
        }
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
    
    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: size.dimension, height: size.dimension)
            
            if loadError {
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: size.iconSize))
                        .foregroundColor(.gray)
                    
                    if size != .small {
                        Text("Failed to load")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            } else if isLoading {
                ProgressView()
                    .scaleEffect(size == .small ? 0.5 : 0.8)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: size.iconSize))
                        .foregroundColor(.gray)
                    
                    if size != .small {
                        Text(item.category.displayName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
    
    private var overlayContent: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if size != .small {
                        Text(item.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let brand = item.brand {
                            Text(brand)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                if size == .large && item.timesWorn > 0 {
                    wearCountBadge
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
    
    private var favoriteIndicator: some View {
        VStack {
            HStack {
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.system(size: size == .small ? 10 : 12))
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: size == .small ? 16 : 20, height: size == .small ? 16 : 20)
                    )
            }
            
            Spacer()
        }
        .padding(4)
    }
    
    private var attentionIndicator: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: size == .small ? 10 : 12))
                    .foregroundColor(.orange)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: size == .small ? 16 : 20, height: size == .small ? 16 : 20)
                    )
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(4)
    }
    
    private var wearCountBadge: some View {
        Text("\(item.timesWorn)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.blue)
            )
    }
    
    private var contextMenuContent: some View {
        Group {
            Button(action: { /* Edit item */ }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: { /* Mark as favorite */ }) {
                Label(
                    item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: item.isFavorite ? "heart.slash" : "heart"
                )
            }
            
            Button(action: { /* Mark as worn */ }) {
                Label("Mark as Worn", systemImage: "checkmark.circle")
            }
            
            Divider()
            
            Button(action: { /* Archive item */ }) {
                Label("Archive", systemImage: "archivebox")
            }
            
            Button(role: .destructive, action: { /* Delete item */ }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var categoryIcon: String {
        switch item.category {
        case .tops:
            return "tshirt"
        case .bottoms:
            return "pants"
        case .dresses:
            return "dress"
        case .outerwear:
            return "coat"
        case .shoes:
            return "shoe.2"
        case .accessories:
            return "bag"
        case .underwear:
            return "underwear"
        case .activewear:
            return "sportscourt"
        case .sleepwear:
            return "bed.double"
        case .swimwear:
            return "drop.triangle"
        }
    }
}

enum ThumbnailSize {
    case small
    case medium
    case large
    
    var dimension: CGFloat {
        switch self {
        case .small:
            return 80
        case .medium:
            return 120
        case .large:
            return 160
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 8
        case .medium:
            return 12
        case .large:
            return 16
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small:
            return 20
        case .medium:
            return 28
        case .large:
            return 36
        }
    }
}

struct ThumbnailButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Wardrobe Grid View

struct WardrobeGridView: View {
    let items: [WardrobeItem]
    let columns: Int
    let thumbnailSize: ThumbnailSize
    let onItemTap: (WardrobeItem) -> Void
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    init(
        items: [WardrobeItem],
        columns: Int = 2,
        thumbnailSize: ThumbnailSize = .medium,
        onItemTap: @escaping (WardrobeItem) -> Void
    ) {
        self.items = items
        self.columns = columns
        self.thumbnailSize = thumbnailSize
        self.onItemTap = onItemTap
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(items) { item in
                WardrobeThumbnailView(
                    item: item,
                    size: thumbnailSize
                ) {
                    onItemTap(item)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Loading States

struct WardrobeThumbnailSkeleton: View {
    let size: ThumbnailSize
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(Color(UIColor.systemGray5))
            .frame(width: size.dimension, height: size.dimension)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? size.dimension : -size.dimension)
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .clipped()
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct WardrobeGridSkeleton: View {
    let columns: Int
    let rows: Int
    let thumbnailSize: ThumbnailSize
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                WardrobeThumbnailSkeleton(size: thumbnailSize)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Thumbnail Cache Manager

final class ThumbnailCacheManager {
    static let shared = ThumbnailCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let imageProcessor = ImageProcessor.shared
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func thumbnail(for url: String, size: ThumbnailSize) -> UIImage? {
        let cacheKey = "\(url)_\(size.dimension)" as NSString
        return cache.object(forKey: cacheKey)
    }
    
    func setThumbnail(_ image: UIImage, for url: String, size: ThumbnailSize) {
        let cacheKey = "\(url)_\(size.dimension)" as NSString
        let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
        cache.setObject(image, forKey: cacheKey, cost: cost)
    }
    
    func generateAndCacheThumbnail(
        from imageURL: String,
        size: ThumbnailSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        let cacheKey = "\(imageURL)_\(size.dimension)" as NSString
        
        if let cachedThumbnail = cache.object(forKey: cacheKey) {
            completion(cachedThumbnail)
            return
        }
        
        guard let url = URL(string: imageURL) else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let thumbnailSize = CGSize(width: size.dimension, height: size.dimension)
            guard let thumbnail = self?.imageProcessor.generateThumbnail(
                from: image,
                size: thumbnailSize,
                contentMode: .aspectFill
            ) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self?.setThumbnail(thumbnail, for: imageURL, size: size)
            
            DispatchQueue.main.async {
                completion(thumbnail)
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func clearExpiredThumbnails() {
        // In a real implementation, you might track creation dates
        // and remove thumbnails older than a certain threshold
    }
}

#Preview {
    let sampleItem = WardrobeItem(
        userId: UUID(),
        name: "Blue Jeans",
        category: .bottoms,
        brand: "Levi's",
        colors: [ClothingColor(name: "Blue", hexCode: "#0000FF", isPrimary: true)],
        isFavorite: true,
        timesWorn: 5
    )
    
    return VStack {
        HStack {
            WardrobeThumbnailView(item: sampleItem, size: .small) { }
            WardrobeThumbnailView(item: sampleItem, size: .medium) { }
            WardrobeThumbnailView(item: sampleItem, size: .large) { }
        }
        
        WardrobeGridSkeleton(columns: 3, rows: 2, thumbnailSize: .medium)
    }
    .padding()
}