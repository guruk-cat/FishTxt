import SwiftUI

struct CardView: View {
    @EnvironmentObject var appColors: AppColors
    @EnvironmentObject var store: ProjectStore

    let item: DashboardItem
    let projectID: UUID
    let folderID: UUID?
    let isReadOnly: Bool
    let height: CGFloat
    let onBlobTap: (UUID) -> Void
    let onFolderTap: (UUID) -> Void
    let isDropPreview: Bool
    let isDropConfirm: Bool
    let dropConfirmOpacity: Double
    let isCreateGlow: Bool
    let createGlowOpacity: Double

    @State private var isHovered: Bool = false
    @State private var excerpt: ProjectStore.BlobExcerpt?
    @State private var copyConfirmed: Bool = false

    var body: some View {
        Group {
            if case .ghost = item {
                ghostCardContent()
            } else {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? AppColors.shared.backgroundHighlight : AppColors.shared.backgroundPrimary)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.shared.cardBorder, lineWidth: 1)

                    // Drop preview glow: shown when this folder is the hover target during a blob drag
                    if isDropPreview {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.shared.accent, lineWidth: 2)
                            .shadow(color: AppColors.shared.accent.opacity(0.6), radius: 6, x: 0, y: 0)
                    }

                    // Glow: shown after successful drop, fades out
                    if isDropConfirm {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.shared.accent.opacity(dropConfirmOpacity), lineWidth: 2)
                            .shadow(
                                color: AppColors.shared.accent.opacity(dropConfirmOpacity * 0.6),
                                radius: 6, x: 0, y: 0
                            )
                    }

                    // Create glow: shown after a new item is created, fades out
                    if isCreateGlow {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.shared.accent.opacity(createGlowOpacity), lineWidth: 2)
                            .shadow(
                                color: AppColors.shared.accent.opacity(createGlowOpacity * 0.6),
                                radius: 6, x: 0, y: 0
                            )
                    }

                    switch item {
                    case .folder(let folder):
                        folderCardContent(folder)
                    case .blob(let blob):
                        blobCardContent(blob)
                    case .ghost:
                        EmptyView()
                    }
                }
                .onHover { isHovered = $0 }
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap()
                }
            }
        }
        .frame(height: height)
    }

    // MARK: - Folder Card
    private func folderCardContent(_ folder: BlobFolder) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.shared.contentSecondary)

            Text(folder.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.shared.contentSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }

    // MARK: - Blob Card
    private func blobCardContent(_ blob: Blob) -> some View {
        ZStack(alignment: .topTrailing) {
            if excerpt != nil && excerpt?.title == nil && excerpt?.bodyAttributed == nil {
                // Empty state — centered
                Text("Empty")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(AppColors.shared.contentTertiary)
                    .italic()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Preview: optional heading + body text, clipped to card bounds
                VStack(alignment: .leading, spacing: 8) {
                    if let title = excerpt?.title {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.shared.contentSecondary)
                            .lineLimit(2)
                    }
                    if let body = excerpt?.bodyAttributed {
                        Text(body)
                            .foregroundColor(AppColors.shared.contentPrimary)
                            .lineSpacing(16 * 0.25)
                            .lineLimit(excerpt?.title != nil ? 8 : 10)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .clipped()
            }

            // Copy button (appears on hover)
            if isHovered {
                Button(action: {
                    let html = store.loadBlobHTML(blobID: blob.id, in: projectID)
                    let text = store.loadBlobPlainText(blobID: blob.id, in: projectID, maxWords: .max)
                    if html != nil || text != nil {
                        EditorBridge.writeToClipboard(html: html, plainText: text)
                        withAnimation(.easeInOut(duration: 0.15)) { copyConfirmed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeOut(duration: 0.3)) { copyConfirmed = false }
                        }
                    }
                }) {
                    Image(systemName: copyConfirmed ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(copyConfirmed ? AppColors.shared.confirmation : AppColors.shared.contentSecondary)
                        .frame(width: 20, height: 20)
                        .background(AppColors.shared.backgroundSecondary)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppColors.shared.confirmation.opacity(copyConfirmed ? 1 : 0), lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 0.15), value: copyConfirmed)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: blob.id) {
            let result = await Task.detached(priority: .utility) {
                store.loadBlobExcerpt(blobID: blob.id, in: projectID)
            }.value
            excerpt = result
        }
    }

    // MARK: - Ghost Card
    private func ghostCardContent() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(
                style: StrokeStyle(lineWidth: 2, dash: [5, 5])
            )
            .foregroundColor(AppColors.shared.contentTertiary)
            .frame(height: height)
    }

    // MARK: - Tap Handler
    private func handleTap() {
        switch item {
        case .folder(let folder):
            onFolderTap(folder.id)
        case .blob(let blob):
            onBlobTap(blob.id)
        case .ghost:
            break
        }
    }
}

#Preview {
    VStack {
        HStack {
            CardView(
                item: .folder(BlobFolder(name: "Sample Folder")),
                projectID: UUID(),
                folderID: nil,
                isReadOnly: false,
                height: 80,
                onBlobTap: { _ in },
                onFolderTap: { _ in },
                isDropPreview: false,
                isDropConfirm: false,
                dropConfirmOpacity: 0.0,
                isCreateGlow: false,
                createGlowOpacity: 0.0
            )

            CardView(
                item: .blob(Blob()),
                projectID: UUID(),
                folderID: nil,
                isReadOnly: false,
                height: 200,
                onBlobTap: { _ in },
                onFolderTap: { _ in },
                isDropPreview: false,
                isDropConfirm: false,
                dropConfirmOpacity: 0.0,
                isCreateGlow: false,
                createGlowOpacity: 0.0
            )

            CardView(
                item: .ghost,
                projectID: UUID(),
                folderID: nil,
                isReadOnly: false,
                height: 200,
                onBlobTap: { _ in },
                onFolderTap: { _ in },
                isDropPreview: false,
                isDropConfirm: false,
                dropConfirmOpacity: 0.0,
                isCreateGlow: false,
                createGlowOpacity: 0.0
            )
        }
        .padding()
    }
    .background(AppColors.shared.backgroundSecondary)
    .environmentObject(AppColors.shared)
    .environmentObject(ProjectStore())
}
