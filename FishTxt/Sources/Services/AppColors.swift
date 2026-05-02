import SwiftUI

/// Loads color palettes from colors.json and exposes SwiftUI Color properties.
/// Palette structure: { "paletteName": { "color_key": [R, G, B] } }
class AppColors: ObservableObject {
    static let shared = AppColors()

    // 60% — writing surface and its text
    @Published var surface: Color        = .black
    @Published var surfaceSunken: Color  = .black
    @Published var surfaceRaised: Color  = .black
    @Published var textBody: Color       = .white
    @Published var textResting: Color    = .gray
    @Published var textMuted: Color      = .gray
    @Published var borderCard: Color     = .gray

    // 30% — app chrome
    @Published var chromeSidebar: Color  = .black
    @Published var chromePanel: Color    = .black
    @Published var chromeToolbar: Color  = .black

    // 10% — emphasis and accent
    @Published var textHeading: Color    = .gray
    @Published var metaIndication: Color  = .blue
    @Published var metaConfirmation: Color = .green
    @Published var destructive: Color    = .red

    /// Whether the current palette is a dark theme (used to set preferredColorScheme).
    @Published var isDark: Bool = true

    /// Background for the settings panel window. Darker than `settingsBox` regardless of palette tone.
    var settingsPanel: Color { isDark ? surface : chromePanel }

    /// Background for settings GroupBox rows. Lighter than `settingsPanel` regardless of palette tone.
    var settingsBox: Color { isDark ? chromePanel : surface }

    /// Names of all palettes found in colors.json, sorted alphabetically.
    private(set) var availablePalettes: [String] = []

    /// Maps palette name → "dark" or "light", read from each palette's `type` field.
    private(set) var paletteTypes: [String: String] = [:]

    /// Raw 0–255 RGB values for the active palette. Used to inject CSS into the web editor.
    private(set) var rawPalette: [String: [Double]] = [:]

    init() {
        let palette = UserDefaults.standard.string(forKey: "colorPalette") ?? "paper"
        loadColors(palette: palette)
    }

    /// Returns palette names whose `type` field matches the given value, sorted alphabetically.
    func palettes(ofType type: String) -> [String] {
        availablePalettes.filter { paletteTypes[$0] == type }
    }

    func loadColors(palette: String) {
        guard
            let url = Bundle.main.url(forResource: "colors", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        else {
            print("AppColors: colors.json missing or malformed")
            return
        }

        availablePalettes = root.keys.sorted()
        paletteTypes = root.compactMapValues { $0["type"] as? String }

        let resolvedPalette: String
        if root[palette] != nil {
            resolvedPalette = palette
        } else {
            resolvedPalette = "paper"
            UserDefaults.standard.set(resolvedPalette, forKey: "colorPalette")
        }

        guard let dict = root[resolvedPalette] ?? root.values.first else {
            print("AppColors: palette '\(resolvedPalette)' not found")
            return
        }

        func c(_ key: String) -> Color {
            guard let v = dict[key] as? [Double] else { return .gray }
            return Color(red: v[0] / 255, green: v[1] / 255, blue: v[2] / 255)
        }

        rawPalette = dict.compactMapValues { $0 as? [Double] }
        surface        = c("surface")
        surfaceSunken  = c("surface_sunken")
        surfaceRaised  = c("surface_raised")
        textBody       = c("text_body")
        textResting    = c("text_resting")
        textMuted      = c("text_muted")
        borderCard     = c("border_card")
        chromeSidebar  = c("chrome_sidebar")
        chromePanel    = c("chrome_panel")
        chromeToolbar  = c("chrome_toolbar")
        textHeading    = c("text_heading")
        metaIndication   = c("meta_indication")
        metaConfirmation = c("meta_confirmation")
        destructive    = c("destructive")

        isDark = paletteTypes[resolvedPalette] == "dark"
    }

    /// Returns the light counterpart palette's key colors, or nil if the current palette
    /// is light (no astig mode needed) or has no named counterpart.
    func astigLightColors() -> (surface: String, textBody: String, textHeading: String, metaIndication: String, textMuted: String)? {
        guard isDark else { return nil }
        let stored = UserDefaults.standard.string(forKey: "astigPalette") ?? ""
        guard !stored.isEmpty,
              paletteTypes[stored] == "light",
              let url = Bundle.main.url(forResource: "colors", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]],
              let light = root[stored] else { return nil }
        func rgb(_ key: String) -> String {
            guard let v = light[key] as? [Double], v.count >= 3 else { return "rgb(128,128,128)" }
            return "rgb(\(Int(v[0])),\(Int(v[1])),\(Int(v[2])))"
        }
        return (rgb("surface"), rgb("text_body"), rgb("text_heading"), rgb("meta_indication"), rgb("text_muted"))
    }

    /// Document-start script for astig mode — injected as a WKUserScript alongside the color
    /// variables so the editor page has the correct state before any rendering happens.
    func astigDocStartJS() -> String {
        let enabled = UserDefaults.standard.bool(forKey: "astigMode")
        guard enabled, let colors = astigLightColors() else {
            return "window.__ft_astig=false;"
        }
        return """
        window.__ft_astig=true;
        (function(){
          var r=document.documentElement.style;
          r.setProperty('--astig-surface',         '\(colors.surface)');
          r.setProperty('--astig-text-body',       '\(colors.textBody)');
          r.setProperty('--astig-text-heading',    '\(colors.textHeading)');
          r.setProperty('--astig-meta-indication', '\(colors.metaIndication)');
          r.setProperty('--astig-text-muted',      '\(colors.textMuted)');
        })();
        """
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
          r.setProperty('--surface',           '\(rgb("surface"))');
          r.setProperty('--surface-sunken',    '\(rgb("surface_sunken"))');
          r.setProperty('--chrome-panel',      '\(rgb("chrome_panel"))');
          r.setProperty('--text-body',         '\(rgb("text_body"))');
          r.setProperty('--text-heading',      '\(rgb("text_heading"))');
          r.setProperty('--text-muted',        '\(rgb("text_muted"))');
          r.setProperty('--meta-indication',   '\(rgb("meta_indication"))');
          r.setProperty('--meta-confirmation', '\(rgb("meta_confirmation"))');
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
            guard let v = rawPalette["meta_indication"], v.count >= 3 else { return "rgba(128,128,128,0.3)" }
            return "rgba(\(Int(v[0])),\(Int(v[1])),\(Int(v[2])),0.3)"
        }()
        return """
        (function(){
          var r = document.documentElement.style;
          r.setProperty('--surface',           '\(rgb("surface"))');
          r.setProperty('--surface-sunken',    '\(rgb("surface_sunken"))');
          r.setProperty('--chrome-panel',      '\(rgb("chrome_panel"))');
          r.setProperty('--text-body',         '\(rgb("text_body"))');
          r.setProperty('--text-heading',      '\(rgb("text_heading"))');
          r.setProperty('--text-muted',        '\(rgb("text_muted"))');
          r.setProperty('--meta-indication',   '\(rgb("meta_indication"))');
          r.setProperty('--meta-confirmation', '\(rgb("meta_confirmation"))');
          var sel = document.getElementById('ft-sel');
          if (!sel) { sel = document.createElement('style'); sel.id = 'ft-sel'; document.head.appendChild(sel); }
          sel.textContent = '::selection { background: \(selectionBg); }';
        })()
        """
    }
}
