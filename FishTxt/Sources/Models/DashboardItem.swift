import Foundation

enum DashboardItem: Identifiable, Equatable {
    case folder(BlobFolder)
    case blob(Blob)
    case ghost

    var id: UUID {
        switch self {
        case .folder(let folder):
            return folder.id
        case .blob(let blob):
            return blob.id
        case .ghost:
            return UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        }
    }

    var sortOrder: Int {
        switch self {
        case .folder(let folder):
            return folder.sortOrder
        case .blob(let blob):
            return blob.sortOrder
        case .ghost:
            return Int.max
        }
    }

    static func == (lhs: DashboardItem, rhs: DashboardItem) -> Bool {
        switch (lhs, rhs) {
        case (.folder(let a), .folder(let b)):
            return a == b
        case (.blob(let a), .blob(let b)):
            return a == b
        case (.ghost, .ghost):
            return true
        default:
            return false
        }
    }
}
