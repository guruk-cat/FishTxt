#!/usr/bin/env python3
# FishTxt Color Preview
# Opens localhost:8765

import json, http.server, socketserver, webbrowser, threading
from pathlib import Path

COLORS_PATH = Path(__file__).parent.parent / "FishTxt/Resources/colors.json"
HTML_PATH = Path(__file__).parent / "color_preview.html"
PORT = 8765

def load_colors():
  with open(COLORS_PATH) as f:
    return json.load(f)
    
def load_html():
  with open(HTML_PATH) as f:
    return f.read()

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # suppress request logs

    def do_GET(self):
        if self.path not in ('/', '/index.html'):
            self.send_response(404); self.end_headers(); return
        try:
            colors = load_colors()
            body = HTML_TEMPLATE.replace('__COLORS_JSON__', json.dumps(colors, indent=2))
            data = body.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            err = f'<pre style="color:tomato;padding:2rem">Error reading colors.json:\n{e}</pre>'.encode()
            self.send_response(500)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(err)


# HTML template 
# COLORS_JSON is replaced at serve time with the live contents of colors.json
HTML_TEMPLATE = load_html()

def main():
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        url = f"http://localhost:{PORT}"
        print(f"\n  FishTxt Color Preview  →  {url}")
        print(f"  ⌘R (or Ctrl+R) in the browser re-reads colors.json.")
        print(f"  Ctrl+C to stop.\n")
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n  Stopped.")


if __name__ == "__main__":
    main()
