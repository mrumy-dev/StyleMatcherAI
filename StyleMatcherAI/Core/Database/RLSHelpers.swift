import Foundation
import Supabase

struct RLSHelpers {
    static let shared = RLSHelpers()
    private let supabase = SupabaseClient.shared
    
    private init() {}
    
    func getCurrentUserId() -> UUID? {
        return supabase.currentUser?.id
    }
    
    func ensureUserOwnership<T: Identifiable>(
        _ items: [T],
        userIdKeyPath: KeyPath<T, UUID>
    ) throws -> [T] {
        guard let currentUserId = getCurrentUserId() else {
            throw RLSError.notAuthenticated
        }
        
        let filteredItems = items.filter { item in
            return item[keyPath: userIdKeyPath] == currentUserId
        }
        
        return filteredItems
    }
    
    func validateUserOwnership(userId: UUID) throws {
        guard let currentUserId = getCurrentUserId() else {
            throw RLSError.notAuthenticated
        }
        
        guard currentUserId == userId else {
            throw RLSError.unauthorized
        }
    }
    
    func getUserClause() throws -> (String, UUID) {
        guard let currentUserId = getCurrentUserId() else {
            throw RLSError.notAuthenticated
        }
        return ("user_id", currentUserId)
    }
    
    func createUserScopedQuery<T>(
        table: String,
        operation: QueryOperation = .select
    ) throws -> PostgrestQueryBuilder {
        let (userColumn, userId) = try getUserClause()
        
        let query = supabase.database.from(table)
        
        switch operation {
        case .select:
            return query.select().eq(userColumn, value: userId)
        case .insert:
            return query
        case .update:
            return query.eq(userColumn, value: userId)
        case .delete:
            return query.eq(userColumn, value: userId)
        }
    }
}

enum QueryOperation {
    case select
    case insert
    case update
    case delete
}

enum RLSError: LocalizedError {
    case notAuthenticated
    case unauthorized
    case invalidUserId
    case policyViolation(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .unauthorized:
            return "User not authorized to perform this action"
        case .invalidUserId:
            return "Invalid user ID provided"
        case .policyViolation(let message):
            return "Row Level Security policy violation: \(message)"
        }
    }
}

protocol UserOwnedResource {
    var userId: UUID { get }
    
    func validateOwnership() throws
}

extension UserOwnedResource {
    func validateOwnership() throws {
        try RLSHelpers.shared.validateUserOwnership(userId: self.userId)
    }
}

extension AppUser: UserOwnedResource {
    func validateOwnership() throws {
        try RLSHelpers.shared.validateUserOwnership(userId: self.id)
    }
}

extension WardrobeItem: UserOwnedResource {
    func validateOwnership() throws {
        try RLSHelpers.shared.validateUserOwnership(userId: self.userId)
    }
}

extension Outfit: UserOwnedResource {
    func validateOwnership() throws {
        try RLSHelpers.shared.validateUserOwnership(userId: self.userId)
    }
}

extension OutfitHistory: UserOwnedResource {
    func validateOwnership() throws {
        try RLSHelpers.shared.validateUserOwnership(userId: self.userId)
    }
}

struct RLSPolicyBuilder {
    private let tableName: String
    private let policyName: String
    private var policyType: PolicyType
    private var operation: PolicyOperation
    private var condition: String?
    private var checkExpression: String?
    
    init(tableName: String, policyName: String) {
        self.tableName = tableName
        self.policyName = policyName
        self.policyType = .permissive
        self.operation = .all
    }
    
    func restrictive() -> RLSPolicyBuilder {
        var builder = self
        builder.policyType = .restrictive
        return builder
    }
    
    func permissive() -> RLSPolicyBuilder {
        var builder = self
        builder.policyType = .permissive
        return builder
    }
    
    func forOperation(_ operation: PolicyOperation) -> RLSPolicyBuilder {
        var builder = self
        builder.operation = operation
        return builder
    }
    
    func withCondition(_ condition: String) -> RLSPolicyBuilder {
        var builder = self
        builder.condition = condition
        return builder
    }
    
    func withCheck(_ check: String) -> RLSPolicyBuilder {
        var builder = self
        builder.checkExpression = check
        return builder
    }
    
    func buildSQL() -> String {
        var sql = "CREATE POLICY \(policyName) ON \(tableName)"
        
        sql += " AS \(policyType.rawValue.uppercased())"
        sql += " FOR \(operation.rawValue.uppercased())"
        
        if let condition = condition {
            sql += " USING (\(condition))"
        }
        
        if let check = checkExpression {
            sql += " WITH CHECK (\(check))"
        }
        
        return sql + ";"
    }
    
    static func userOwnershipPolicy(
        tableName: String,
        policyName: String,
        operation: PolicyOperation = .all
    ) -> RLSPolicyBuilder {
        return RLSPolicyBuilder(tableName: tableName, policyName: policyName)
            .forOperation(operation)
            .withCondition("auth.uid() = user_id")
            .withCheck("auth.uid() = user_id")
    }
    
    static func publicReadPolicy(
        tableName: String,
        policyName: String,
        publicColumn: String = "is_public"
    ) -> RLSPolicyBuilder {
        return RLSPolicyBuilder(tableName: tableName, policyName: policyName)
            .forOperation(.select)
            .withCondition("\(publicColumn) = true")
    }
}

enum PolicyType: String {
    case permissive
    case restrictive
}

enum PolicyOperation: String {
    case all
    case select
    case insert
    case update
    case delete
}

extension RLSHelpers {
    static func generateCommonPolicies() -> [String] {
        var policies: [String] = []
        
        policies.append(
            RLSPolicyBuilder.userOwnershipPolicy(
                tableName: "users",
                policyName: "users_own_policy"
            ).buildSQL()
        )
        
        policies.append(
            RLSPolicyBuilder.userOwnershipPolicy(
                tableName: "wardrobe_items",
                policyName: "wardrobe_items_own_policy"
            ).buildSQL()
        )
        
        policies.append(
            RLSPolicyBuilder.userOwnershipPolicy(
                tableName: "outfits",
                policyName: "outfits_own_policy"
            ).buildSQL()
        )
        
        policies.append(
            RLSPolicyBuilder.publicReadPolicy(
                tableName: "outfits",
                policyName: "outfits_public_read_policy"
            ).buildSQL()
        )
        
        policies.append(
            RLSPolicyBuilder.userOwnershipPolicy(
                tableName: "outfit_history",
                policyName: "outfit_history_own_policy"
            ).buildSQL()
        )
        
        return policies
    }
    
    static func generateEnableRLSStatements() -> [String] {
        let tables = ["users", "wardrobe_items", "outfits", "outfit_history"]
        return tables.map { "ALTER TABLE \($0) ENABLE ROW LEVEL SECURITY;" }
    }
    
    func executeRLSSetup() async throws {
        let enableStatements = RLSHelpers.generateEnableRLSStatements()
        let policies = RLSHelpers.generateCommonPolicies()
        
        let allStatements = enableStatements + policies
        
        for statement in allStatements {
            do {
                try await supabase.database.rpc("execute_sql", parameters: ["sql": statement]).execute()
            } catch {
                print("Failed to execute RLS statement: \(statement)")
                print("Error: \(error)")
                throw RLSError.policyViolation("Failed to setup RLS: \(error.localizedDescription)")
            }
        }
    }
}

struct RLSQueryWrapper {
    private let helpers = RLSHelpers.shared
    
    func safeQuery<T: UserOwnedResource & Codable>(
        table: String,
        returning type: T.Type
    ) async throws -> [T] {
        let query = try helpers.createUserScopedQuery(table: table, operation: .select)
        let response = try await query.execute()
        let items: [T] = try response.value
        
        return try helpers.ensureUserOwnership(items, userIdKeyPath: \.userId)
    }
    
    func safeInsert<T: UserOwnedResource & Codable>(
        _ item: T,
        into table: String
    ) async throws -> T {
        try item.validateOwnership()
        
        let query = helpers.supabase.database.from(table)
        let response = try await query.insert(item).select().single().execute()
        
        let insertedItem: T = try response.value
        try insertedItem.validateOwnership()
        
        return insertedItem
    }
    
    func safeUpdate<T: UserOwnedResource & Codable & Identifiable>(
        _ item: T,
        in table: String,
        idColumn: String = "id"
    ) async throws -> T {
        try item.validateOwnership()
        
        let query = try helpers.createUserScopedQuery(table: table, operation: .update)
        let response = try await query
            .update(item)
            .eq(idColumn, value: item.id)
            .select()
            .single()
            .execute()
        
        let updatedItem: T = try response.value
        try updatedItem.validateOwnership()
        
        return updatedItem
    }
    
    func safeDelete<T: Identifiable>(
        itemId: T.ID,
        from table: String,
        idColumn: String = "id"
    ) async throws {
        let query = try helpers.createUserScopedQuery(table: table, operation: .delete)
        try await query
            .delete()
            .eq(idColumn, value: itemId)
            .execute()
    }
}

extension RLSHelpers {
    func withUserContext<T>(_ operation: () async throws -> T) async throws -> T {
        guard getCurrentUserId() != nil else {
            throw RLSError.notAuthenticated
        }
        
        return try await operation()
    }
    
    func validateResourceAccess<T: UserOwnedResource>(
        _ resource: T,
        allowOwnerOnly: Bool = true
    ) throws {
        if allowOwnerOnly {
            try resource.validateOwnership()
        }
    }
    
    func filterUserResources<T: UserOwnedResource>(
        _ resources: [T],
        currentUserId: UUID
    ) -> [T] {
        return resources.filter { $0.userId == currentUserId }
    }
}

protocol RLSCompliantRepository {
    func validateUserAccess() throws
    func getCurrentUserId() -> UUID?
}

extension RLSCompliantRepository {
    func validateUserAccess() throws {
        guard getCurrentUserId() != nil else {
            throw RLSError.notAuthenticated
        }
    }
    
    func getCurrentUserId() -> UUID? {
        return RLSHelpers.shared.getCurrentUserId()
    }
}