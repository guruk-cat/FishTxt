import SwiftUI
import WebKit

struct WebEditorView: NSViewRepresentable {
    @ObservedObject var bridge: EditorBridge
    @AppStorage("autoScroll") private var autoScrollMode: String = "regular"

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Inject active palette colors before any CSS is computed — eliminates the flash of
        // hardcoded colors. Runs on every page load so theme switches also take effect immediately.
        let colorScript = WKUserScript(
            source: AppColors.shared.editorCSSVariablesJS(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(colorScript)

        // Weak wrapper prevents retain cycle between WKUserContentController and EditorBridge.
        let weakHandler = WeakMessageHandler(handler: bridge)
        config.userContentController.add(weakHandler, name: "editorBridge")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        bridge.webView = webView

        if let url = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.updateAutoScroll(autoScrollMode)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bridge: bridge)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let bridge: EditorBridge
        private var lastScrollMode: String = ""

        init(bridge: EditorBridge) {
            self.bridge = bridge
        }

        func updateAutoScroll(_ mode: String) {
            guard mode != lastScrollMode else { return }
            lastScrollMode = mode
            bridge.setAutoScroll(mode)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.bridge.applyColors()
                let scrollMode = UserDefaults.standard.string(forKey: "autoScroll") ?? "regular"
                self.bridge.setAutoScroll(scrollMode)
                self.lastScrollMode = scrollMode
                webView.evaluateJavaScript("window.editorBridge?.focus()", completionHandler: nil)
                webView.becomeFirstResponder()
            }
        }
    }
}

// MARK: - Retain-cycle prevention

class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var handler: EditorBridge?

    init(handler: EditorBridge) {
        self.handler = handler
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}
