import SwiftUI

class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []

    private let fileManager = FileManager.default
    private let rootPath: String

    init() {
        self.rootPath = NSHomeDirectory() + "/Documents/FishTxt"
        ensureRootDirectory()
        loadProjects()
    }

    // MARK: - Initialization

    private func ensureRootDirectory() {
        if !fileManager.fileExists(atPath: rootPath) {
            try? fileManager.createDirectory(
                atPath: rootPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            copyWelcomeProject()
        }
    }

    private func copyWelcomeProject() {
        let welcomeProjectID = "620851BD-61D1-4502-A662-D054E85FCC33"
        let destination = URL(fileURLWithPath: rootPath + "/" + welcomeProjectID)

        guard !fileManager.fileExists(atPath: destination.path) else { return }

        guard let resourceURL = Bundle.main.resourceURL else { return }

        // Locate project.json for the welcome project directly in the bundle resources
        let projectFileURL = resourceURL.appendingPathComponent("project.json")
        guard fileManager.fileExists(atPath: projectFileURL.path) else {
            print("ProjectStore: welcome project.json not found in bundle")
            return
        }

        do {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

            // Copy every JSON file from Resources into the destination folder
            let resourceContents = try fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
            let excluded = Set(["colors.json"])
            for file in resourceContents where file.pathExtension == "json" && !excluded.contains(file.lastPathComponent) {
                let dest = destination.appendingPathComponent(file.lastPathComponent)
                try fileManager.copyItem(at: file, to: dest)
            }
        } catch {
            print("ProjectStore: failed to copy welcome project: \(error)")
        }
    }

    private func loadProjects() {
        guard fileManager.fileExists(atPath: rootPath) else { return }

        guard let contents = try? fileManager.contentsOfDirectory(atPath: rootPath) else { return }

        var loadedProjects: [Project] = []
        for item in contents {
            let itemPath = rootPath + "/" + item
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue else {
                continue
            }

            let projectFile = itemPath + "/project.json"
            guard fileManager.fileExists(atPath: projectFile) else { continue }

            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: projectFile))
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let project = try decoder.decode(Project.self, from: data)
                loadedProjects.append(project)
            } catch {
                print("Failed to load project at \(projectFile): \(error)")
            }
        }

        // Sort by createdAt
        loadedProjects.sort { $0.createdAt < $1.createdAt }
        DispatchQueue.main.async {
            self.projects = loadedProjects
        }
    }

    // MARK: - Project CRUD

    func createProject(name: String) -> Project {
        let project = Project(name: name)
        let projectPath = rootPath + "/" + project.id.uuidString
        do {
            try fileManager.createDirectory(
                atPath: projectPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Failed to create project directory: \(error)")
            return project
        }

        save(project)
        DispatchQueue.main.async {
            self.projects.append(project)
            self.projects.sort { $0.createdAt < $1.createdAt }
        }
        return project
    }

    func deleteProject(_ projectID: UUID) {
        let projectPath = rootPath + "/" + projectID.uuidString
        do {
            try fileManager.removeItem(atPath: projectPath)
        } catch {
            print("Failed to delete project directory: \(error)")
        }

        DispatchQueue.main.async {
            self.projects.removeAll { $0.id == projectID }
        }
    }

    func renameProject(_ projectID: UUID, to name: String) {
        mutateProject(projectID) { project in
            project.name = name
        }
    }

    func archiveProject(_ projectID: UUID) {
        mutateProject(projectID) { project in
            project.isArchived = true
        }
    }

    func restoreProject(_ projectID: UUID) {
        mutateProject(projectID) { project in
            project.isArchived = false
        }
    }

    // MARK: - Folder CRUD

    func createFolder(in projectID: UUID, name: String) -> BlobFolder {
        guard let projectIndex = projectIndex(projectID) else { return BlobFolder(name: name) }

        var project = projects[projectIndex]
        var folder = BlobFolder(name: name)
        folder.sortOrder = (project.folders.min { $0.sortOrder < $1.sortOrder }?.sortOrder ?? 0) - 1
        project.folders.append(folder)
        rebuildRootSortOrders(&project)

        updateProject(project)
        return folder
    }

    func deleteFolder(_ folderID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        // Remove folder from folders or hiddenFolders
        project.folders.removeAll { $0.id == folderID }
        project.hiddenFolders.removeAll { $0.id == folderID }

        // Remove all blobs in this folder
        project.blobs.removeAll { $0.folderID == folderID }

        updateProject(project)
    }

    func renameFolder(_ folderID: UUID, in projectID: UUID, to name: String) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.folders.firstIndex(where: { $0.id == folderID }) {
            project.folders[index].name = name
        } else if let index = project.hiddenFolders.firstIndex(where: { $0.id == folderID }) {
            project.hiddenFolders[index].name = name
        }

        updateProject(project)
    }

    func hideFolder(_ folderID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.folders.firstIndex(where: { $0.id == folderID }) {
            let folder = project.folders.remove(at: index)
            project.hiddenFolders.append(folder)
        }

        updateProject(project)
    }

    func unhideFolder(_ folderID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.hiddenFolders.firstIndex(where: { $0.id == folderID }) {
            var unHiddenFolder = project.hiddenFolders.remove(at: index)
            unHiddenFolder.sortOrder = (project.folders.max { $0.sortOrder < $1.sortOrder }?.sortOrder ?? -1) + 1
            project.folders.append(unHiddenFolder)
        }

        updateProject(project)
    }

    // MARK: - Blob CRUD

    func createBlob(in projectID: UUID, folderID: UUID? = nil) -> Blob {
        guard let projectIndex = projectIndex(projectID) else { return Blob() }

        var project = projects[projectIndex]
        let blob = Blob(folderID: folderID)

        if let folderID = folderID {
            // Insert before first existing blob in folder
            let firstFolderSortOrder = project.blobs
                .filter { $0.folderID == folderID && !$0.isHidden }
                .min { $0.sortOrder < $1.sortOrder }?
                .sortOrder ?? 0
            var newBlob = blob
            newBlob.sortOrder = firstFolderSortOrder - 1
            project.blobs.append(newBlob)
            rebuildFolderSortOrders(&project, folderID: folderID)
        } else {
            // Insert before first existing root blob
            let firstRootBlobSortOrder = project.blobs
                .filter { $0.folderID == nil && !$0.isHidden }
                .min { $0.sortOrder < $1.sortOrder }
                .map { $0.sortOrder }

            if let firstSortOrder = firstRootBlobSortOrder {
                var newBlob = blob
                newBlob.sortOrder = firstSortOrder - 1
                project.blobs.append(newBlob)
                rebuildRootSortOrders(&project)
            } else {
                let maxSortOrder = project.blobs
                    .filter { $0.folderID == nil }
                    .max { $0.sortOrder < $1.sortOrder }?
                    .sortOrder ?? -1
                var newBlob = blob
                newBlob.sortOrder = maxSortOrder + 1
                project.blobs.append(newBlob)
            }
        }

        updateProject(project)
        return blob
    }

    func deleteBlob(_ blobID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let blobIndex = project.blobs.firstIndex(where: { $0.id == blobID }) {
            let blob = project.blobs[blobIndex]
            let folderID = blob.folderID

            project.blobs.remove(at: blobIndex)

            // Delete blob file from disk
            let projectPath = rootPath + "/" + projectID.uuidString
            let blobFile = projectPath + "/" + blobID.uuidString + ".json"
            try? fileManager.removeItem(atPath: blobFile)

            // Rebuild sort orders for affected context
            if let folderID = folderID {
                rebuildFolderSortOrders(&project, folderID: folderID)
            } else {
                rebuildRootSortOrders(&project)
            }
        }

        updateProject(project)
    }

    func hideBlob(_ blobID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.blobs.firstIndex(where: { $0.id == blobID }) {
            project.blobs[index].isHidden = true
        }

        updateProject(project)
    }

    func unhideBlob(_ blobID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.blobs.firstIndex(where: { $0.id == blobID }) {
            project.blobs[index].isHidden = false
            let blob = project.blobs[index]

            // If blob is at root level, assign sortOrder before first existing root blob
            if blob.folderID == nil {
                let firstRootBlobSortOrder = project.blobs
                    .filter { $0.folderID == nil && !$0.isHidden && $0.id != blobID }
                    .min { $0.sortOrder < $1.sortOrder }
                    .map { $0.sortOrder }

                if let firstSortOrder = firstRootBlobSortOrder {
                    project.blobs[index].sortOrder = firstSortOrder - 1
                } else {
                    let maxSortOrder = project.blobs
                        .filter { $0.folderID == nil }
                        .max { $0.sortOrder < $1.sortOrder }?
                        .sortOrder ?? -1
                    project.blobs[index].sortOrder = maxSortOrder + 1
                }

                rebuildRootSortOrders(&project)
            }
        }

        updateProject(project)
    }

    func moveBlobToRoot(_ blobID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.blobs.firstIndex(where: { $0.id == blobID }) {
            let oldFolderID = project.blobs[index].folderID
            project.blobs[index].folderID = nil

            // Assign sortOrder before first existing root blob
            let firstRootBlobSortOrder = project.blobs
                .filter { $0.folderID == nil && !$0.isHidden && $0.id != blobID }
                .min { $0.sortOrder < $1.sortOrder }
                .map { $0.sortOrder }

            if let firstSortOrder = firstRootBlobSortOrder {
                project.blobs[index].sortOrder = firstSortOrder - 1
            } else {
                let maxSortOrder = project.blobs
                    .filter { $0.folderID == nil }
                    .max { $0.sortOrder < $1.sortOrder }?
                    .sortOrder ?? -1
                project.blobs[index].sortOrder = maxSortOrder + 1
            }

            // Rebuild sort orders for both contexts
            if let oldFolderID = oldFolderID {
                rebuildFolderSortOrders(&project, folderID: oldFolderID)
            }
            rebuildRootSortOrders(&project)
        }

        updateProject(project)
    }

    // MARK: - Sort Order Management

    func rebuildSortOrders(in projectID: UUID, context folderID: UUID?) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let folderID = folderID {
            rebuildFolderSortOrders(&project, folderID: folderID)
        } else {
            rebuildRootSortOrders(&project)
        }

        updateProject(project)
    }

    func moveItem(in projectID: UUID, fromIndex: Int, toIndex: Int, context folderID: UUID?) {
        guard let projectIndex = projectIndex(projectID) else { return }
        guard fromIndex != toIndex else { return }

        var project = projects[projectIndex]

        if let folderID = folderID {
            // Folder context: all items are blobs; fromIndex/toIndex are 0-based within this folder's visible blobs
            var blobs = project.blobs
                .filter { $0.folderID == folderID && !$0.isHidden }
                .sorted { $0.sortOrder < $1.sortOrder }
            guard fromIndex >= 0, fromIndex < blobs.count,
                  toIndex >= 0, toIndex < blobs.count else { return }
            let moved = blobs.remove(at: fromIndex)
            blobs.insert(moved, at: toIndex)
            // Write new sort orders directly — don't call rebuildFolderSortOrders which would
            // re-sort by the old (unchanged) sortOrder values and undo the move.
            for (i, blob) in blobs.enumerated() {
                if let idx = project.blobs.firstIndex(where: { $0.id == blob.id }) {
                    project.blobs[idx].sortOrder = i
                }
            }
        } else {
            // Root context: fromIndex/toIndex index into dashboardItems (folders first, then blobs)
            let sortedFolders = project.folders.sorted { $0.sortOrder < $1.sortOrder }
            let sortedRootBlobs = project.blobs
                .filter { $0.folderID == nil && !$0.isHidden }
                .sorted { $0.sortOrder < $1.sortOrder }
            let folderCount = sortedFolders.count

            if fromIndex < folderCount {
                // Moving a folder; toIndex must also be within the folder section
                guard toIndex >= 0, toIndex < folderCount else { return }
                var folders = sortedFolders
                let moved = folders.remove(at: fromIndex)
                folders.insert(moved, at: toIndex)
                for (i, folder) in folders.enumerated() {
                    if let idx = project.folders.firstIndex(where: { $0.id == folder.id }) {
                        project.folders[idx].sortOrder = i
                    }
                }
            } else {
                // Moving a root blob; convert from allDashItems-space to blob-section-space
                let blobFromIndex = fromIndex - folderCount
                let blobToIndex   = toIndex   - folderCount
                guard blobFromIndex >= 0, blobFromIndex < sortedRootBlobs.count,
                      blobToIndex   >= 0, blobToIndex   < sortedRootBlobs.count else { return }
                var blobs = sortedRootBlobs
                let moved = blobs.remove(at: blobFromIndex)
                blobs.insert(moved, at: blobToIndex)
                for (i, blob) in blobs.enumerated() {
                    if let idx = project.blobs.firstIndex(where: { $0.id == blob.id }) {
                        project.blobs[idx].sortOrder = i
                    }
                }
            }
        }

        updateProject(project)
    }

    func moveBlobToFolder(_ blobID: UUID, to folderID: UUID, in projectID: UUID) {
        guard let projectIndex = projectIndex(projectID) else { return }

        var project = projects[projectIndex]

        if let index = project.blobs.firstIndex(where: { $0.id == blobID }) {
            let oldFolderID = project.blobs[index].folderID
            project.blobs[index].folderID = folderID
            project.blobs[index].sortOrder = (project.blobs
                .filter { $0.folderID == folderID && !$0.isHidden && $0.id != blobID }
                .min { $0.sortOrder < $1.sortOrder }?
                .sortOrder ?? 0) - 1

            // Rebuild sort orders for both old and new contexts
            if let oldFolderID = oldFolderID {
                rebuildFolderSortOrders(&project, folderID: oldFolderID)
            } else {
                rebuildRootSortOrders(&project)
            }
            rebuildFolderSortOrders(&project, folderID: folderID)
        }

        updateProject(project)
    }

    // MARK: - Blob Content I/O

    func loadBlobContent(blobID: UUID, in projectID: UUID) -> String? {
        let blobFile = rootPath + "/" + projectID.uuidString + "/" + blobID.uuidString + ".json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: blobFile)) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Blob Excerpt

    struct BlobExcerpt {
        var title: String?            // plain text from the first heading node
        var body: String?             // plain text from all non-heading nodes (used by sidebar)
        var bodyAttributed: AttributedString?  // rich text body with inline marks (used by card previews)
    }

    /// Parses TipTap JSON and returns a structured excerpt.
    /// Title = first heading node's text (only one, regardless of level).
    /// Body  = text from all non-heading nodes with inline bold/italic/underline preserved.
    func loadBlobExcerpt(blobID: UUID, in projectID: UUID) -> BlobExcerpt {
        guard let jsonString = loadBlobContent(blobID: blobID, in: projectID),
              let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let topNodes = root["content"] as? [[String: Any]] else {
            return BlobExcerpt()
        }

        var titleParts: [String] = []
        var bodyNodes:  [[String: Any]] = []
        var foundTitle = false

        for node in topNodes {
            let type = node["type"] as? String
            if type == "heading" {
                if !foundTitle {
                    extractText(from: node, into: &titleParts)
                    foundTitle = true
                }
                // subsequent headings intentionally skipped
            } else {
                bodyNodes.append(node)
            }
        }

        // Join text within each node with "" (text nodes already carry their own spacing),
        // then join top-level nodes with " " so paragraphs stay separated.
        var bodyParts: [String] = []
        for node in bodyNodes {
            var parts: [String] = []
            extractText(from: node, into: &parts)
            let nodeText = parts.joined()
            if !nodeText.isEmpty { bodyParts.append(nodeText) }
        }

        let title = titleParts.joined().trimmingCharacters(in: .whitespacesAndNewlines)
        let body  = bodyParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyAttributed = buildAttributedBody(from: bodyNodes)

        return BlobExcerpt(
            title:         title.isEmpty ? nil : title,
            body:          body.isEmpty  ? nil : body,
            bodyAttributed: bodyAttributed
        )
    }

    // MARK: - Attributed body builder

    private func buildAttributedBody(from nodes: [[String: Any]]) -> AttributedString? {
        var result = AttributedString()
        var isFirst = true

        for node in nodes {
            let part = attributedStringFromNode(node)
            guard !part.characters.isEmpty else { continue }
            if !isFirst {
                var sep = AttributedString(" ")
                sep.font = .system(size: 16, design: .monospaced)
                result += sep
            }
            result += part
            isFirst = false
        }

        return result.characters.isEmpty ? nil : result
    }

    private func attributedStringFromNode(_ node: [String: Any]) -> AttributedString {
        guard let type = node["type"] as? String else { return AttributedString() }

        if type == "text" {
            guard let text = node["text"] as? String, !text.isEmpty else { return AttributedString() }
            var segment = AttributedString(text)
            let marks = node["marks"] as? [[String: Any]] ?? []
            var isBold = false
            var isItalic = false
            var isUnderline = false
            for mark in marks {
                switch mark["type"] as? String {
                case "bold":      isBold = true
                case "italic":    isItalic = true
                case "underline": isUnderline = true
                default: break
                }
            }
            var font = Font.system(size: 16, weight: isBold ? .bold : .regular, design: .monospaced)
            if isItalic { font = font.italic() }
            segment.font = font
            if isUnderline { segment.underlineStyle = Text.LineStyle(pattern: .solid) }
            return segment
        } else {
            var result = AttributedString()
            if let children = node["content"] as? [[String: Any]] {
                for child in children { result += attributedStringFromNode(child) }
            }
            return result
        }
    }

    /// Extracts plain text from a blob's TipTap JSON.
    /// Pass maxWords: .max to get the full text (e.g. for clipboard copy).
    func loadBlobPlainText(blobID: UUID, in projectID: UUID, maxWords: Int = 30) -> String? {
        guard let jsonString = loadBlobContent(blobID: blobID, in: projectID),
              let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) else { return nil }

        // Walk top-level nodes, joining text within each node with "" to avoid
        // double spaces around bold/italic runs, then join nodes with " ".
        var topParts: [String] = []
        if let dict = root as? [String: Any],
           let topNodes = dict["content"] as? [Any] {
            for node in topNodes {
                var parts: [String] = []
                extractText(from: node, into: &parts)
                let t = parts.joined()
                if !t.isEmpty { topParts.append(t) }
            }
        }
        let full = topParts.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !full.isEmpty else { return nil }
        if maxWords == .max { return full }
        let words = full.split(separator: " ", omittingEmptySubsequences: true).prefix(maxWords)
        return words.joined(separator: " ")
    }

    /// Generates HTML from a blob's TipTap JSON, preserving headings, lists, and inline marks.
    func loadBlobHTML(blobID: UUID, in projectID: UUID) -> String? {
        guard let jsonString = loadBlobContent(blobID: blobID, in: projectID),
              let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let topNodes = root["content"] as? [[String: Any]] else { return nil }
        let html = topNodes.map { renderNodeHTML($0) }.joined()
        return html.isEmpty ? nil : html
    }

    private func renderNodeHTML(_ node: [String: Any]) -> String {
        guard let type = node["type"] as? String else { return "" }
        let children = node["content"] as? [[String: Any]] ?? []
        switch type {
        case "paragraph":
            return "<p>" + children.map { renderNodeHTML($0) }.joined() + "</p>"
        case "heading":
            let level = (node["attrs"] as? [String: Any])?["level"] as? Int ?? 1
            return "<h\(level)>" + children.map { renderNodeHTML($0) }.joined() + "</h\(level)>"
        case "bulletList":
            return "<ul>" + children.map { renderNodeHTML($0) }.joined() + "</ul>"
        case "orderedList":
            return "<ol>" + children.map { renderNodeHTML($0) }.joined() + "</ol>"
        case "listItem":
            return "<li>" + children.map { renderNodeHTML($0) }.joined() + "</li>"
        case "blockquote":
            return "<blockquote>" + children.map { renderNodeHTML($0) }.joined() + "</blockquote>"
        case "hardBreak":
            return "<br>"
        case "text":
            guard let text = node["text"] as? String else { return "" }
            let escaped = text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let marks = node["marks"] as? [[String: Any]] ?? []
            return marks.reduce(escaped) { result, mark in
                switch mark["type"] as? String {
                case "bold":      return "<strong>\(result)</strong>"
                case "italic":    return "<em>\(result)</em>"
                case "underline": return "<u>\(result)</u>"
                default:          return result
                }
            }
        default:
            return children.map { renderNodeHTML($0) }.joined()
        }
    }

    private func extractText(from node: Any, into result: inout [String]) {
        guard let dict = node as? [String: Any] else { return }
        if dict["type"] as? String == "text", let text = dict["text"] as? String {
            result.append(text)
        }
        if let children = dict["content"] as? [Any] {
            for child in children { extractText(from: child, into: &result) }
        }
    }

    func saveBlobContent(_ json: String, blobID: UUID, in projectID: UUID) {
        let blobFile = rootPath + "/" + projectID.uuidString + "/" + blobID.uuidString + ".json"
        guard let data = json.data(using: .utf8) else { return }
        do {
            try data.write(to: URL(fileURLWithPath: blobFile), options: .atomic)
            mutateProject(projectID) { project in
                if let index = project.blobs.firstIndex(where: { $0.id == blobID }) {
                    project.blobs[index].updatedAt = Date()
                }
            }
        } catch {
            print("[ProjectStore] Failed to save blob content: \(error)")
        }
    }

    // MARK: - Dashboard Helpers

    func dashboardItems(for projectID: UUID, folderID: UUID?) -> [DashboardItem] {
        guard let project = projects.first(where: { $0.id == projectID }) else { return [] }

        if let folderID = folderID {
            // Return active blobs in that folder
            let blobs = project.blobs
                .filter { $0.folderID == folderID && !$0.isHidden }
                .sorted { $0.sortOrder < $1.sortOrder }
            return blobs.map { .blob($0) }
        } else {
            // Folders always before blobs; each group sorted independently
            var items: [DashboardItem] = []

            let activeFolders = project.folders
                .sorted { $0.sortOrder < $1.sortOrder }
            items.append(contentsOf: activeFolders.map { .folder($0) })

            let activeRootBlobs = project.blobs
                .filter { $0.folderID == nil && !$0.isHidden }
                .sorted { $0.sortOrder < $1.sortOrder }
            items.append(contentsOf: activeRootBlobs.map { .blob($0) })

            return items
        }
    }

    func hiddenDashboardItems(for projectID: UUID) -> [DashboardItem] {
        guard let project = projects.first(where: { $0.id == projectID }) else { return [] }

        var items: [DashboardItem] = []

        // Add hidden folders
        let hiddenFolders = project.hiddenFolders
            .sorted { $0.sortOrder < $1.sortOrder }
        items.append(contentsOf: hiddenFolders.map { .folder($0) })

        // Add individually hidden blobs
        let hiddenBlobs = project.blobs
            .filter { $0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
        items.append(contentsOf: hiddenBlobs.map { .blob($0) })

        // Add blobs belonging to hidden folders (excluding already-added individually hidden ones)
        let hiddenBlobIDs = Set(hiddenBlobs.map { $0.id })
        let blobsInHiddenFolders = project.blobs
            .filter { blob in
                !hiddenBlobIDs.contains(blob.id) &&
                blob.folderID != nil && project.hiddenFolders.contains(where: { $0.id == blob.folderID })
            }
            .sorted { $0.sortOrder < $1.sortOrder }
        items.append(contentsOf: blobsInHiddenFolders.map { .blob($0) })

        return items
    }

    // MARK: - Private Helpers

    private func save(_ project: Project) {
        let projectPath = rootPath + "/" + project.id.uuidString
        let projectFile = projectPath + "/project.json"

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(project)
            try data.write(to: URL(fileURLWithPath: projectFile))
        } catch {
            print("Failed to save project: \(error)")
        }
    }

    private func projectIndex(_ id: UUID) -> Int? {
        projects.firstIndex { $0.id == id }
    }

    private func mutateProject(_ id: UUID, mutator: (inout Project) -> Void) {
        guard let index = projectIndex(id) else { return }
        mutator(&projects[index])
        save(projects[index])
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    private func updateProject(_ project: Project) {
        if let index = projectIndex(project.id) {
            DispatchQueue.main.async {
                self.projects[index] = project
                self.save(project)
            }
        }
    }

    private func rebuildRootSortOrders(_ project: inout Project) {
        // Folders and blobs maintain independent sort sequences
        let sortedFolders = project.folders.sorted { $0.sortOrder < $1.sortOrder }
        for (index, folder) in sortedFolders.enumerated() {
            if let i = project.folders.firstIndex(where: { $0.id == folder.id }) {
                project.folders[i].sortOrder = index
            }
        }

        let sortedBlobs = project.blobs
            .filter { $0.folderID == nil && !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
        for (index, blob) in sortedBlobs.enumerated() {
            if let i = project.blobs.firstIndex(where: { $0.id == blob.id }) {
                project.blobs[i].sortOrder = index
            }
        }
    }

    private func rebuildFolderSortOrders(_ project: inout Project, folderID: UUID) {
        let blobs = project.blobs
            .filter { $0.folderID == folderID && !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }

        for (index, blob) in blobs.enumerated() {
            if let blobIndex = project.blobs.firstIndex(where: { $0.id == blob.id }) {
                project.blobs[blobIndex].sortOrder = index
            }
        }
    }
}
