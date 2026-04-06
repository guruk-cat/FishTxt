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
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }

            default:
                break
            }
        }
    }

    // MARK: - Swift → JS (editor commands)

    func toggleBold()           { evaluate("window.editorBridge.toggleBold()") }
    func toggleItalic()         { evaluate("window.editorBridge.toggleItalic()") }
    func toggleUnderline()      { evaluate("window.editorBridge.toggleUnderline()") }
    func toggleBulletList()     { evaluate("window.editorBridge.toggleBulletList()") }
    func toggleOrderedList()    { evaluate("window.editorBridge.toggleOrderedList()") }
    func toggleBlockquote()     { evaluate("window.editorBridge.toggleBlockquote()") }
    func addFootnoteReference() { evaluate("window.editorBridge.addFootnoteReference()") }
    func copyAll()              { evaluate("window.editorBridge.copyAll()") }
    func focus()                { evaluate("window.editorBridge.focus()") }

    func setHeading(level: Int) {
        evaluate("window.editorBridge.setHeading(\(level))")
    }

    func setContent(_ jsonString: String) {
        let js = "(function(){ var c = \(jsonString); window.editorBridge.setContent(c); })()"
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
}
