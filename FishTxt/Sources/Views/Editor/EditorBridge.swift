import Foundation
import WebKit
import AppKit
import Combine

struct EditorState: Equatable {
    var bold        = false
    var italic      = false
    var underline   = false
    var heading     = 0   // 0 = paragraph, 1–3 = heading level
    var bulletList  = false
    var orderedList = false
    var blockquote  = false
}

class EditorBridge: NSObject, ObservableObject, WKScriptMessageHandler {
    weak var webView: WKWebView?

    @Published var isReady    = false
    @Published var isDirty    = false
    @Published var editorState = EditorState()

    /// Called when the web toolbar's Close button is tapped.
    var onClose: (() -> Void)?
    /// Called when the web toolbar's Hide button is tapped.
    var onHide: (() -> Void)?

    // MARK: - JS → Swift (WKScriptMessageHandler)

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {
            case "editorReady":
                self.isReady = true

            case "documentChanged":
                self.isDirty = true

            case "stateUpdate":
                self.editorState = EditorState(
                    bold:        body["bold"]        as? Bool ?? false,
                    italic:      body["italic"]      as? Bool ?? false,
                    underline:   body["underline"]   as? Bool ?? false,
                    heading:     body["heading"]     as? Int  ?? 0,
                    bulletList:  body["bulletList"]  as? Bool ?? false,
                    orderedList: body["orderedList"] as? Bool ?? false,
                    blockquote:  body["blockquote"]  as? Bool ?? false
                )

            case "copyAll":
                if let text = body["text"] as? String {
                    let html = body["html"] as? String
                    Self.writeToClipboard(html: html, plainText: text)
                }

            case "closeEditor":
                self.onClose?()

            case "hideBlob":
                self.onHide?()

            case "headingVisible":
                let index = body["index"] as? Int ?? -1
                NotificationCenter.default.post(name: .activeHeadingChanged, object: index)

            default:
                break
            }
        }
    }

    // MARK: - Swift → JS (editor commands)

    func toggleBold()           { evaluate("window.editorBridge.toggleBold()"); refocusWebView() }
    func toggleItalic()         { evaluate("window.editorBridge.toggleItalic()"); refocusWebView() }
    func toggleUnderline()      { evaluate("window.editorBridge.toggleUnderline()"); refocusWebView() }
    func toggleBulletList()     { evaluate("window.editorBridge.toggleBulletList()"); refocusWebView() }
    func toggleOrderedList()    { evaluate("window.editorBridge.toggleOrderedList()"); refocusWebView() }
    func toggleBlockquote()     { evaluate("window.editorBridge.toggleBlockquote()"); refocusWebView() }
    func addFootnoteReference() { evaluate("window.editorBridge.addFootnoteReference()") }
    func copyAll()              { evaluate("window.editorBridge.copyAll()") }
    func focus() {
        refocusWebView()
        evaluate("window.editorBridge.focus()")
    }

    func setHeading(level: Int) {
        evaluate("window.editorBridge.setHeading(\(level))")
        refocusWebView()
    }

    func scrollToHeading(index: Int) {
        evaluate("if(window.scrollToHeading) window.scrollToHeading(\(index))")
    }

    func setAutoScroll(_ mode: String) {
        evaluate("window.editorBridge.setAutoScrollMode('\(mode)')")
    }

    // MARK: - Editor style (font size + family share one injected <style> tag)

    private var currentFontSize: Double = UserDefaults.standard.double(forKey: "fontSize") > 0
        ? UserDefaults.standard.double(forKey: "fontSize") : 16.0
    private var currentFontFamily: String = UserDefaults.standard.string(forKey: "fontFamily") ?? "Menlo"

    func setFontSize(_ size: Double) {
        currentFontSize = size
        applyEditorStyle()
    }

    func setFontFamily(_ family: String) {
        currentFontFamily = family
        applyEditorStyle()
    }

    private func applyEditorStyle() {
        let size = currentFontSize
        let maxWidth = Int(820.0 * size / 20.0)
        let cssFamily = fontFamilyCSS(currentFontFamily)
        let js = """
        (function(){
          var el = document.getElementById('ft-font');
          if (!el) { el = document.createElement('style'); el.id = 'ft-font'; document.head.appendChild(el); }
          el.textContent = '.ProseMirror, .ProseMirror h1, .ProseMirror h2, .ProseMirror h3 { font-family: \(cssFamily); } .ProseMirror { font-size: \(Int(size))px; max-width: \(maxWidth)px; }';
        })()
        """
        evaluate(js)
    }

    private func fontFamilyCSS(_ family: String) -> String {
        switch family {
        case "Palatino": return "Palatino, \"Palatino Linotype\", serif"
        default:         return "Menlo, Consolas, \"Courier New\", monospace"
        }
    }

    func setContent(_ jsonString: String) {
        let js = "(function(){ var c = \(jsonString); window.editorBridge.setContent(c); })()"
        evaluate(js)
    }

    func setContentAndScrollToTop(_ jsonString: String) {
        let js = """
        (function(){
            var c = \(jsonString);
            window.editorBridge.setContent(c);
            var ed = document.getElementById('editor');
            if (ed) ed.scrollTop = 0;
        })()
        """
        evaluate(js)
    }

    func getContent(completion: @escaping (String?) -> Void) {
        webView?.evaluateJavaScript("JSON.stringify(window.editor.getJSON())") { result, _ in
            completion(result as? String)
        }
    }

    func scrollToTop() {
        evaluate("""
        setTimeout(function(){
            if (window.editor) { window.editor.commands.focus('start'); }
            window.scrollTo(0, 0);
        }, 100)
        """)
    }

    func markClean() {
        DispatchQueue.main.async { self.isDirty = false }
    }

    /// Injects the active AppColors palette into the web editor's CSS variables.
    func applyColors() {
        evaluate(AppColors.shared.editorCSSInjection())
    }

    // MARK: - Private

    private func evaluate(_ js: String) {
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func refocusWebView() {
        DispatchQueue.main.async {
            if let webView = self.webView {
                webView.window?.makeFirstResponder(webView)
            }
        }
    }

    // MARK: - Notifications

    /// Writes HTML and plain text to the clipboard with proper UTF-8 encoding.
    /// Wraps the HTML fragment in a minimal document with a charset declaration so that
    /// apps like Pages and Word don't misinterpret multi-byte characters (curly quotes,
    /// em-dashes, etc.) as Latin-1.
    // MARK: - Clipboard

    static func writeToClipboard(html: String?, plainText: String?) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if let html = html {
            let doc = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>\(html)</body></html>"
            if let data = doc.data(using: .utf8) {
                pb.setData(data, forType: NSPasteboard.PasteboardType(rawValue: "public.html"))
            }
        }
        if let text = plainText {
            pb.setString(text, forType: .string)
        }
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let scrollToOutlineHeading = Notification.Name("scrollToOutlineHeading")
    static let activeHeadingChanged   = Notification.Name("activeHeadingChanged")
}
