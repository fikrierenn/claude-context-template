import sys, pathlib
from playwright.sync_api import sync_playwright

FOOTER = ('<div style="font-size:8px;width:100%;text-align:center;color:#8a94a6;'
          'font-family:Segoe UI,Arial;padding:0 8mm;">© Fikri Eren 2026'
          '&nbsp;·&nbsp;<span class="pageNumber"></span>/<span class="totalPages"></span></div>')
EMPTY = '<div></div>'

def render(html_path, pdf_path):
    uri = pathlib.Path(html_path).resolve().as_uri()
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page()
        pg.goto(uri, wait_until="networkidle")
        pg.pdf(path=pdf_path, format="A4", print_background=True,
               prefer_css_page_size=True, display_header_footer=True,
               header_template=EMPTY, footer_template=FOOTER)
        b.close()
    print("OK", pdf_path)

if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2])
