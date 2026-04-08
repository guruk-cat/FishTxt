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

        // Toolbar init — injected after all module scripts have run, so window.editor
        // and window.editorBridge are guaranteed to exist. No retry loop needed.
        let toolbarScript = WKUserScript(
            source: Self.toolbarInitJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(toolbarScript)

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

// MARK: - Toolbar init script

extension WebEditorView {
    static let toolbarInitJS = """
    (function () {
      var ed = window.editor;
      var eb = window.editorBridge;

      // ── Active state ──────────────────────────────────────────────
      function updateToolbar() {
        toggle('bold-btn',      ed.isActive('bold'));
        toggle('italic-btn',    ed.isActive('italic'));
        toggle('underline-btn', ed.isActive('underline'));
        toggle('quote-btn',     ed.isActive('blockquote'));
        var h = ed.isActive('heading', {level:1}) ? 1
              : ed.isActive('heading', {level:2}) ? 2
              : ed.isActive('heading', {level:3}) ? 3 : 0;
        var label = document.getElementById('heading-label');
        if (label) label.textContent = h > 0 ? 'H' + h : 'Headings';
        toggle('heading-menu', h > 0);
        toggle('list-menu', ed.isActive('bulletList') || ed.isActive('orderedList'));
      }
      function toggle(id, active) {
        var el = document.getElementById(id);
        if (el) el.classList.toggle('active', active);
      }
      try { ed.on('transaction',     updateToolbar); } catch(e) {}
      try { ed.on('selectionUpdate', updateToolbar); } catch(e) {}
      setInterval(updateToolbar, 100);
      updateToolbar();

      // ── Formatting commands ────────────────────────────────────────
      function on(id, fn) {
        var el = document.getElementById(id);
        if (el) el.addEventListener('click', fn);
      }
      on('bold-btn',      function () { eb.toggleBold(); });
      on('italic-btn',    function () { eb.toggleItalic(); });
      on('underline-btn', function () { eb.toggleUnderline(); });
      on('quote-btn',     function () { eb.toggleBlockquote(); });
      on('ref-btn',       function () { eb.addFootnoteReference(); });

      // ── Heading dropdown ──────────────────────────────────────────
      var headingMenu = document.getElementById('heading-menu');
      var headingDrop = document.getElementById('heading-dropdown');
      headingMenu.addEventListener('click', function (e) {
        e.stopPropagation();
        listDrop.classList.remove('open');
        headingDrop.classList.toggle('open');
      });
      headingDrop.querySelectorAll('.dropdown-item').forEach(function (item) {
        item.addEventListener('click', function (e) {
          e.stopPropagation();
          eb.setHeading(parseInt(item.dataset.level, 10));
          headingDrop.classList.remove('open');
        });
      });

      // ── List dropdown ─────────────────────────────────────────────
      var listMenu = document.getElementById('list-menu');
      var listDrop = document.getElementById('list-dropdown');
      listMenu.addEventListener('click', function (e) {
        e.stopPropagation();
        headingDrop.classList.remove('open');
        listDrop.classList.toggle('open');
      });
      document.getElementById('bullet-item').addEventListener('click', function (e) {
        e.stopPropagation();
        eb.toggleBulletList();
        listDrop.classList.remove('open');
      });
      document.getElementById('ordered-item').addEventListener('click', function (e) {
        e.stopPropagation();
        eb.toggleOrderedList();
        listDrop.classList.remove('open');
      });

      // ── Chrome → Swift ────────────────────────────────────────────
      on('copy-btn',  function () { eb.copyAll(); });
      on('hide-btn',  function () { post({ type: 'hideBlob' }); });
      on('close-btn', function () { post({ type: 'closeEditor' }); });
      function post(msg) {
        var h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.editorBridge;
        if (h) h.postMessage(msg);
      }

      // ── Close dropdowns on outside click ─────────────────────────
      document.addEventListener('click', function () {
        headingDrop.classList.remove('open');
        listDrop.classList.remove('open');
      });
    })();
    """
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
