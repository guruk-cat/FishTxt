import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appColors: AppColors
    @Environment(\.dismiss) private var dismiss

    // Defaults
    @AppStorage("colorPalette") private var colorPalette: String = "coast"
    @AppStorage("fontFamily") private var fontFamily: String = "Menlo"
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("autoScroll") private var autoScroll: String = "regular"
    @AppStorage("printProfile") private var printProfile: String = "default"

    @State private var availablePrintProfiles: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.shared.contentPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.shared.contentTertiary)
                        .frame(width: 22, height: 22)
                        .background(AppColors.shared.backgroundPrimary)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()
                .background(AppColors.shared.cardBorder)

            // Settings form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Editor
                    settingsSection("Editor") {
                        settingsRow("Font") {
                            TextField("Font family", text: $fontFamily)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(AppColors.shared.contentPrimary)
                                .frame(width: 140)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.shared.backgroundPrimary)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(AppColors.shared.cardBorder, lineWidth: 1)
                                )
                        }

                        settingsRow("Font size") {
                            HStack(spacing: 6) {
                                Button(action: { if fontSize > 10 { fontSize -= 1 } }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.shared.contentSecondary)
                                        .frame(width: 22, height: 22)
                                        .background(AppColors.shared.backgroundPrimary)
                                        .cornerRadius(5)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.cardBorder, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Text("\(Int(fontSize))pt")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.shared.contentPrimary)
                                    .frame(width: 36, alignment: .center)

                                Button(action: { if fontSize < 36 { fontSize += 1 } }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.shared.contentSecondary)
                                        .frame(width: 22, height: 22)
                                        .background(AppColors.shared.backgroundPrimary)
                                        .cornerRadius(5)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.cardBorder, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // MARK: Appearance
                    settingsSection("Appearance") {
                        settingsRow("Color palette") {
                            Picker("", selection: $colorPalette) {
                                ForEach(appColors.availablePalettes, id: \.self) { palette in
                                    Text(palette.replacingOccurrences(of: "_", with: " ").capitalized).tag(palette)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                            .onChange(of: colorPalette) { newPalette in
                                appColors.loadColors(palette: newPalette)
                            }
                        }
                        
                        settingsRow("Auto scroll") {
                            Picker("", selection: $autoScroll) {
                                Text("Regular").tag("regular")
                                Text("Centered").tag("centered")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }

                        settingsRow("Print profile") {
                            Picker("", selection: $printProfile) {
                                ForEach(availablePrintProfiles, id: \.self) { profile in
                                    Text(profile.replacingOccurrences(of: "_", with: " ").capitalized).tag(profile)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                        }
                    }
                }
                .padding(20)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 380, height: 380)
        .background(AppColors.shared.backgroundSecondary)
        .task {
            loadPrintProfiles()
        }
    }

    // MARK: - Layout helpers

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColors.shared.contentTertiary)
                .tracking(1.0)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }

    @ViewBuilder
    private func settingsRow<Content: View>(_ label: String, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.shared.contentSecondary)
                .frame(width: 90, alignment: .leading)

            control()
        }
    }

    private func loadPrintProfiles() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "css", subdirectory: "print-profiles") else {
            print("[SettingsView] No print profiles found in bundle")
            availablePrintProfiles = []
            return
        }
        print("[SettingsView] Found \(urls.count) print profiles: \(urls.map { $0.lastPathComponent})")
        availablePrintProfiles = urls
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppColors.shared)
}
