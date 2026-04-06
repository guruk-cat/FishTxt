import Foundation

struct Blob: Codable, Identifiable, Equatable {
    let id: UUID
    var folderID: UUID?
    var sortOrder: Int
    var isHidden: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        folderID: UUID? = nil,
        sortOrder: Int = 0,
        isHidden: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.folderID = folderID
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
