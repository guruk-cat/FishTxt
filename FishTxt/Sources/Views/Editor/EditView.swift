import SwiftUI
import Combine
import AppKit

enum SaveStatus: Equatable {
    case idle, saving, saved
}

struct EditView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors

    let blobID: UUID
    let projectID: UUID
    let onClose: () -> Void

    @StateObject private var bridge = EditorBridge()
    @State private var saveStatus: SaveStatus = .idle
    @State private var hasLoaded = false
    @State private var escMonitor: Any?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                headerBar
                WebEditorView(bridge: bridge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppColors.shared.backgroundPrimary)

            saveIsland
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(bridge.$isReady.filter { $0 }) { _ in
            guard !hasLoaded else { return }
            hasLoaded = true
            if let json = store.loadBlobContent(blobID: blobID, in: projectID) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    bridge.setContent(json)
                    bridge.scrollToTop()
                    bridge.markClean()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveDocument)) { _ in
            performSave(completion: nil)
        }
        .onReceive(
            bridge.$isDirty
                .filter { $0 }
                .debounce(for: .seconds(5), scheduler: RunLoop.main)
        ) { _ in
            performSave(completion: nil)
        }
        .onChange(of: appColors.backgroundPrimary) { _ in
            bridge.applyColors()
        }
        .onAppear {
            escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // Escape
                    saveAndClose()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = escMonitor {
                NSEvent.removeMonitor(monitor)
                escMonitor = nil
            }
        }
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 0) {
            ToolbarView(bridge: bridge)
            Spacer()
            chromeButtons
        }
        .frame(height: 44)
        .background(AppColors.shared.backgroundPrimary)
    }

    private var chromeButtons: some View {
        HStack(spacing: 4) {
            ChromeButton(symbol: "doc.on.clipboard", tip: "Copy")  { bridge.copyAll() }
            ChromeButton(symbol: "eye.slash",         tip: "Hide")  { saveAndHide() }
            ChromeButton(symbol: "xmark",             tip: "Close") { saveAndClose() }
        }
        .padding(.trailing, 12)
    }

    // MARK: - Save status island

    @ViewBuilder
    private var saveIsland: some View {
        if saveStatus != .idle {
            HStack(spacing: 5) {
                if saveStatus == .saving {
                    ProgressView()
                        .scaleEffect(0.55)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(AppColors.shared.confirmation)
                }
                Text(saveStatus == .saving ? "Saving..." : "Saved!")
                    .font(.system(size: 11))
                    .foregroundColor(
                        saveStatus == .saving
                            ? AppColors.shared.contentSecondary
                            : AppColors.shared.confirmation
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.shared.backgroundPrimary.opacity(0.95))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.shared.cardBorder, lineWidth: 1))
            .padding(14)
            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .bottomTrailing)))
        }
    }

    // MARK: - Save logic

    private func performSave(completion: (() -> Void)?) {
        guard bridge.isDirty else { completion?(); return }
        withAnimation(.easeInOut(duration: 0.15)) { saveStatus = .saving }
        bridge.getContent { json in
            guard let json = json else { completion?(); return }
            store.saveBlobContent(json, blobID: blobID, in: projectID)
            withAnimation(.easeInOut(duration: 0.15)) { saveStatus = .saved }
            bridge.markClean()
            completion?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) { saveStatus = .idle }
            }
        }
    }

    private func saveAndClose() {
        performSave { onClose() }
    }

    private func saveAndHide() {
        performSave {
            store.hideBlob(blobID, in: projectID)
            onClose()
        }
    }
}

// MARK: - Chrome button with hover highlight

private struct ChromeButton: View {
    let symbol: String
    let tip: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundColor(isHovered ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary)
                .frame(width: 28, height: 28)
                .background(AppColors.shared.backgroundSecondary)
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.cardBorder, lineWidth: 1))
                .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(tip)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    ZStack {
        AppColors.shared.backgroundSecondary.ignoresSafeArea()
        EditView(blobID: UUID(), projectID: UUID(), onClose: {})
            .environmentObject(ProjectStore())
            .environmentObject(AppColors.shared)
    }
}
