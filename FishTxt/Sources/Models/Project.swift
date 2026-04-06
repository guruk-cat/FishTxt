import Foundation

struct Project: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var folders: [BlobFolder]
    var hiddenFolders: [BlobFolder]
    var blobs: [Blob]
    var isArchived: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        folders: [BlobFolder] = [],
        hiddenFolders: [BlobFolder] = [],
        blobs: [Blob] = [],
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.folders = folders
        self.hiddenFolders = hiddenFolders
        self.blobs = blobs
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
