import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appColors: AppColors
    @Environment(\.dismiss) private var dismiss

    // Defaults
    @AppStorage("colorPalette") private var colorPalette: String = "paper"
    @AppStorage("fontFamily") private var fontFamily: String = "Menlo"
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("autoScroll") private var autoScroll: String = "centered"
    @AppStorage("printProfile") private var printProfile: String = "default"
    @AppStorage("imageLimitHalfWidth") private var imageLimitHalfWidth: Bool = false
    @AppStorage("astigMode") private var astigMode: Bool = false
    @AppStorage("astigPalette") private var astigPalette: String = "paper"
    @AppStorage("lastDarkPalette") private var lastDarkPalette: String = ""
    @State private var availablePrintProfiles: [String] = []

    private var mainPaletteOptions: [String] {
        astigMode ? appColors.palettes(ofType: "dark") : appColors.availablePalettes
    }

    private var lightPaletteOptions: [String] {
        appColors.palettes(ofType: "light")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("SETTINGS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.shared.textHeading)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.shared.textMuted)
                        .frame(width: 22, height: 22)
                        .background(AppColors.shared.surface)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.borderCard, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()
                .background(AppColors.shared.borderCard)

            // Settings form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Editor
                    settingsSection {
                        settingsRow("Font family") {
                            Picker("", selection: $fontFamily) {
                                Text("Menlo").tag("Menlo")
                                Text("Palatino").tag("Palatino")
                            }
                            .pickerStyle(.menu)
                        }
                        Divider().padding(.leading, 12)
                        settingsRow("Font size") {
                            HStack(spacing: 6) {
                                Button(action: { if fontSize > 10 { fontSize -= 1 } }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.shared.textResting)
                                        .frame(width: 22, height: 22)
                                        .background(AppColors.shared.settingsPanel)
                                        .cornerRadius(5)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.borderCard, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Text("\(Int(fontSize))pt")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.shared.textResting)
                                    .frame(width: 36, alignment: .center)

                                Button(action: { if fontSize < 36 { fontSize += 1 } }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.shared.textResting)
                                        .frame(width: 22, height: 22)
                                        .background(AppColors.shared.settingsPanel)
                                        .cornerRadius(5)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.borderCard, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Divider().padding(.leading, 12)
                        settingsRow("Limit imgage width") {
                            Toggle("", isOn: $imageLimitHalfWidth)
                                .toggleStyle(.switch)
                                .tint(AppColors.shared.metaIndication)
                                .controlSize(.mini)
                        }
                        Divider().padding(.leading, 12)
                        settingsRow("Auto-scroll when hitting bottom") {
                            Toggle("", isOn: Binding(
                                get: { autoScroll == "centered" },
                                set: { autoScroll = $0 ? "centered" : "regular" }
                            ))
                            .toggleStyle(.switch)
                            .tint(AppColors.shared.metaIndication)
                            .controlSize(.mini)
                        }
                    }
                    
                    // MARK: Colors
                    settingsSection {
                        settingsRow("Color palette") {
                            Picker("", selection: $colorPalette) {
                                ForEach(mainPaletteOptions, id: \.self) { palette in
                                    Text(palette.replacingOccurrences(of: "_", with: " ").capitalized).tag(palette)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: colorPalette) { newPalette in
                                appColors.loadColors(palette: newPalette)
                                if appColors.paletteTypes[newPalette] == "dark" {
                                    lastDarkPalette = newPalette
                                }
                            }
                        }
                        Divider().padding(.leading, 12)
                        settingsRow("Astigmatism palette") {
                            Picker("", selection: $astigPalette) {
                                ForEach(lightPaletteOptions, id: \.self) { palette in
                                    Text(palette.replacingOccurrences(of: "_", with: " ").capitalized).tag(palette)
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(!astigMode)
                            .opacity(astigMode ? 1.0 : 0.35)
                        }
                        Divider().padding(.leading, 12)
                        settingsRow("Astigmatism mode") {
                            Toggle("", isOn: $astigMode)
                                .toggleStyle(.switch)
                                .tint(AppColors.shared.metaIndication)
                                .controlSize(.mini)
                                .onChange(of: astigMode) { enabled in
                                    if enabled { autoCorrectPalettesForAstig() }
                                }
                        }
                    }

                    // MARK: Printing
                    settingsSection {
                        settingsRow("Print profile") {
                            Picker("", selection: $printProfile) {
                                ForEach(availablePrintProfiles, id: \.self) { profile in
                                    Text(profile.replacingOccurrences(of: "_", with: " ").capitalized).tag(profile)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(20)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 380, height: 420)
        .background(AppColors.shared.settingsPanel)
        .task {
            loadPrintProfiles()
            if lastDarkPalette.isEmpty || appColors.paletteTypes[lastDarkPalette] != "dark" {
                lastDarkPalette = appColors.paletteTypes[colorPalette] == "dark"
                    ? colorPalette
                    : (appColors.palettes(ofType: "dark").first ?? "")
            }
        }
    }

    // MARK: - Layout helpers

    @ViewBuilder
    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                content()
            }
        }
        .groupBoxStyle(SurfaceGroupBoxStyle(background: appColors.settingsBox))
    }

    @ViewBuilder
    private func settingsRow<Content: View>(_ label: String, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.shared.textResting)
            Spacer()
            control()
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }

    /// When astig mode is turned on, ensure the main palette is dark and the astig palette
    /// is a light palette. Falls back to last-used or first-in-line as needed.
    private func autoCorrectPalettesForAstig() {
        if appColors.paletteTypes[colorPalette] != "dark" {
            let darkList = appColors.palettes(ofType: "dark")
            let next = darkList.contains(lastDarkPalette) ? lastDarkPalette : (darkList.first ?? colorPalette)
            if next != colorPalette {
                colorPalette = next
                appColors.loadColors(palette: next)
                lastDarkPalette = next
            }
        }
        let lightList = appColors.palettes(ofType: "light")
        if !lightList.contains(astigPalette) {
            astigPalette = lightList.first ?? ""
        }
    }

    private func loadPrintProfiles() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "css", subdirectory: "print-profiles") else {
            print("[SettingsView] No print profiles found in bundle")
            availablePrintProfiles = []
            return
        }
        availablePrintProfiles = urls
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }
}

private struct SurfaceGroupBoxStyle: GroupBoxStyle {
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            configuration.content
        }
        .frame(maxWidth: .infinity)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppColors.shared)
}
