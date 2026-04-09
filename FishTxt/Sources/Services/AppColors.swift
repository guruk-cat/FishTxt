import SwiftUI

/// Loads color values from colors.json in the app bundle.
/// Supports multiple named palettes via the nested JSON format: { "paletteName": { "color_key": [R, G, B] } }
/// Use AppColors.shared throughout the app instead of hardcoding RGB values.
class AppColors: ObservableObject {
    static let shared = AppColors()

    @Published var backgroundPrimary: Color   = .black
    @Published var backgroundSecondary: Color = .black
    @Published var backgroundHighlight: Color = .black
    @Published var contentPrimary: Color      = .white
    @Published var contentSecondary: Color    = .gray
    @Published var contentTertiary: Color     = .gray
    @Published var accent: Color              = .blue
    @Published var confirmation: Color        = .green
    @Published var sidebarBackground: Color   = .black
    @Published var cardBorder: Color          = .gray
    @Published var destructive: Color         = .red

    /// Whether the current palette is a dark theme (used to set preferredColorScheme).
    @Published var isDark: Bool = true

    /// Names of all palettes found in colors.json, sorted alphabetically.
    private(set) var availablePalettes: [String] = []

    /// Raw 0–255 RGB values for the active palette. Used to inject CSS into the web editor.
    private(set) var rawPalette: [String: [Double]] = [:]

    init() {
        let palette = UserDefaults.standard.string(forKey: "colorPalette") ?? "coast"
        loadColors(palette: palette)
    }

    func loadColors(palette: String) {
        guard
            let url = Bundle.main.url(forResource: "colors", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONDecoder().decode([String: [String: [Double]]].self, from: data)
        else {
            print("AppColors: colors.json missing or malformed")
            return
        }

        availablePalettes = root.keys.sorted()

        let resolvedPalette: String
        if root[palette] != nil {
            resolvedPalette = palette
        } else {
            resolvedPalette = "coast"
            UserDefaults.standard.set(resolvedPalette, forKey: "colorPalette")
        }

        guard let dict = root[resolvedPalette] ?? root.values.first else {
            print("AppColors: palette '\(resolvedPalette)' not found")
            return
        }

        func c(_ key: String) -> Color {
            guard let v = dict[key] else { return .gray }
            return Color(red: v[0] / 255, green: v[1] / 255, blue: v[2] / 255)
        }

        rawPalette = dict

        backgroundPrimary   = c("background_primary")
        backgroundSecondary = c("background_secondary")
        backgroundHighlight = c("background_highlight")
        contentPrimary      = c("content_primary")
        contentSecondary    = c("content_secondary")
        contentTertiary     = c("content_tertiary")
        accent              = c("accent")
        confirmation        = c("confirmation")
        sidebarBackground   = c("sidebar_background")
        cardBorder          = c("card_border")
        destructive         = c("destructive")

        // Perceived luminance of background_primary — W3C formula
        if let bg = dict["background_primary"] {
            let luminance = (bg[0] * 299 + bg[1] * 587 + bg[2] * 114) / 1000
            isDark = luminance < 128
        }
    }

    /// Sets only the CSS custom properties on document.documentElement.
    /// Safe to run at document-start (no document.head access).
    /// Used as a persistent WKUserScript to eliminate the flash of old colors on load.
    func editorCSSVariablesJS() -> String {
        func rgb(_ key: String) -> String {
            guard let v = rawPalette[key], v.count >= 3 else { return "rgb(128,128,128)" }
            return "rgb(\(Int(v[0])),\(Int(v[1])),\(Int(v[2])))"
        }
        return """
        (function(){
          var r = document.documentElement.style;
          r.setProperty('--bg-primary',          '\(rgb("background_primary"))');
          r.setProperty('--bg-secondary',        '\(rgb("background_secondary"))');
          r.setProperty('--sidebar-background',  '\(rgb("sidebar_background"))');
          r.setProperty('--content-primary',     '\(rgb("content_primary"))');
          r.setProperty('--content-secondary',   '\(rgb("content_secondary"))');
          r.setProperty('--content-tertiary',    '\(rgb("content_tertiary"))');
          r.setProperty('--accent',              '\(rgb("accent"))');
          r.setProperty('--confirmation',        '\(rgb("confirmation"))');
        })()
        """
    }

    /// Full injection: CSS variables + ::selection override.
    /// Requires document.head — call from webView(_:didFinish:) or on theme change.
    func editorCSSInjection() -> String {
        func rgb(_ key: String) -> String {
            guard let v = rawPalette[key], v.count >= 3 else { return "rgb(128,128,128)" }
            return "rgb(\(Int(v[0])),\(Int(v[1])),\(Int(v[2])))"
        }
        let selectionBg: String = {
            guard let v = rawPalette["accent"], v.count >= 3 else { return "rgba(128,128,128,0.3)" }
            return "rgba(\(Int(v[0])),\(Int(v[1])),\(Int(v[2])),0.3)"
        }()
        return """
        (function(){
          var r = document.documentElement.style;
          r.setProperty('--bg-primary',          '\(rgb("background_primary"))');
          r.setProperty('--bg-secondary',        '\(rgb("background_secondary"))');
          r.setProperty('--sidebar-background',  '\(rgb("sidebar_background"))');
          r.setProperty('--content-primary',     '\(rgb("content_primary"))');
          r.setProperty('--content-secondary',   '\(rgb("content_secondary"))');
          r.setProperty('--content-tertiary',    '\(rgb("content_tertiary"))');
          r.setProperty('--accent',              '\(rgb("accent"))');
          r.setProperty('--confirmation',        '\(rgb("confirmation"))');
          var sel = document.getElementById('ft-sel');
          if (!sel) { sel = document.createElement('style'); sel.id = 'ft-sel'; document.head.appendChild(sel); }
          sel.textContent = '::selection { background: \(selectionBg); } #custom-cursor { box-shadow: 0 0 4px var(--accent), 0 0 8px var(--accent); }';
        })()
        """
    }
}
