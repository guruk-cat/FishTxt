import SwiftUI

/// Formatting toolbar for the blob editor.
/// Renders left-aligned formatting controls only — no file operations, no save button.
/// Intended to be embedded inside EditView's header bar.
struct ToolbarView: View {
    @ObservedObject var bridge: EditorBridge

    private let c = AppColors.shared

    var body: some View {
        HStack(spacing: 2) {
            // Heading dropdown
            Menu {
                Button("Paragraph") { bridge.setHeading(level: 0) }
                Divider()
                Button("Heading 1") { bridge.setHeading(level: 1) }
                Button("Heading 2") { bridge.setHeading(level: 2) }
                Button("Heading 3") { bridge.setHeading(level: 3) }
            } label: {
                let active = bridge.editorState.heading > 0
                Text(active ? "H\(bridge.editorState.heading)" : "¶")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(active ? c.accent : c.contentPrimary)
                    .frame(minWidth: 28)
                    .animation(.easeInOut(duration: 0.15), value: bridge.editorState.heading)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            formatButton("B", font: .system(size: 14, weight: .bold),
                         active: bridge.editorState.bold) { bridge.toggleBold() }

            formatButton("I", font: .system(size: 14, weight: .regular).italic(),
                         active: bridge.editorState.italic) { bridge.toggleItalic() }

            underlineButton(active: bridge.editorState.underline) { bridge.toggleUnderline() }

            formatButton("Quote", active: bridge.editorState.blockquote) {
                bridge.toggleBlockquote()
            }

            formatButton("Ref.", active: false) {
                bridge.addFootnoteReference()
            }

            // List dropdown
            Menu {
                Button("Bullet List")   { bridge.toggleBulletList() }
                Button("Numbered List") { bridge.toggleOrderedList() }
            } label: {
                let active = bridge.editorState.bulletList || bridge.editorState.orderedList
                Text("List")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(active ? c.accent : c.contentPrimary)
                    .frame(minWidth: 32)
                    .animation(.easeInOut(duration: 0.15), value: active)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.leading, 12)
    }

    // MARK: - Helpers

    private func formatButton(
        _ label: String,
        font: Font = .system(size: 13, weight: .regular),
        active: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(font)
                .foregroundColor(active ? c.accent : c.contentPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .animation(.easeInOut(duration: 0.15), value: active)
        }
        .buttonStyle(.plain)
    }

    private func underlineButton(active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("U")
                .font(.system(size: 14))
                .underline()
                .foregroundColor(active ? c.accent : c.contentPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .animation(.easeInOut(duration: 0.15), value: active)
        }
        .buttonStyle(.plain)
    }
}
