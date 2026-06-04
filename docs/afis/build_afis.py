# -*- coding: utf-8 -*-
"""Tek sayfa A4 kullanim afisi/brosuru uretir (HTML->PDF, Lucide ikon, BKM kirmizi)."""
import os, re, pathlib
from playwright.sync_api import sync_playwright

HERE=os.path.dirname(os.path.abspath(__file__))
ICON=os.path.join(HERE,"..","sunum","node_modules","lucide-static","icons")
def ic(name,color="#E30622",size=30,sw=2.2):
    s=open(os.path.join(ICON,name+".svg"),encoding="utf8").read()
    s=re.sub(r'stroke="[^"]*"',f'stroke="{color}"',s)
    s=s.replace('width="24"',f'width="{size}"').replace('height="24"',f'height="{size}"')
    s=s.replace('stroke-width="2"',f'stroke-width="{sw}"')
    return s

RED="#E30622"; DRED="#A6001A"; INK="#1c1c1c"; GREY="#666"; LGREY="#f4f4f4"

HTML=f"""<!DOCTYPE html><html lang="tr"><head><meta charset="utf-8"><style>
@page{{size:A4;margin:0}}*{{box-sizing:border-box;margin:0;padding:0}}
body{{font-family:"Segoe UI",Arial,sans-serif;color:{INK};-webkit-print-color-adjust:exact;print-color-adjust:exact}}
.page{{width:210mm;height:297mm;padding:14mm 13mm;position:relative}}
.hd{{display:flex;align-items:center;gap:12px;border-bottom:4px solid {RED};padding-bottom:10px}}
.hd .logo{{width:54px;height:54px;border-radius:14px;background:{RED};display:flex;align-items:center;justify-content:center}}
h1{{font-size:30pt;color:{RED};line-height:1.05;font-family:Georgia,serif}}
.tag{{font-size:12.5pt;color:{GREY};margin-top:2px}}
.concept{{background:{INK};color:#fff;border-radius:14px;padding:16px 20px;margin:14px 0;display:flex;align-items:center;gap:16px}}
.concept .big{{font-family:Georgia,serif;font-size:19pt;font-weight:bold;line-height:1.15}}
.concept .big span{{color:#ff6b76}}
.concept .sub{{font-size:11pt;opacity:.85;margin-top:3px}}
.sec{{font-size:13pt;font-weight:bold;color:{RED};text-transform:uppercase;letter-spacing:2px;margin:16px 0 8px;display:flex;align-items:center;gap:8px}}
.ritual{{display:flex;align-items:stretch;gap:8px}}
.rit{{flex:1;border:2px solid #e3e3e3;border-radius:12px;padding:12px;text-align:center}}
.rit .t{{font-family:Consolas,monospace;font-size:13pt;font-weight:bold;color:{INK};margin-top:6px}}
.rit .d{{font-size:9.5pt;color:{GREY};margin-top:3px}}
.arr{{display:flex;align-items:center;font-size:20pt;color:{RED};font-weight:bold}}
table{{width:100%;border-collapse:collapse;font-size:11pt}}
td{{padding:9px 10px;border-bottom:1px solid #ececec;vertical-align:middle}}
.cmd{{font-family:Consolas,monospace;font-weight:bold;color:{DRED};white-space:nowrap}}
.via{{color:{GREY};font-size:9.5pt}}
tr:nth-child(even) td{{background:{LGREY}}}
.row2{{display:flex;gap:14px;margin-top:6px}}
.box{{flex:1;border-radius:12px;padding:12px 14px;font-size:10.5pt}}
.warn{{background:#fdecee;border-left:5px solid {RED}}}
.tip{{background:#eef7f0;border-left:5px solid #2bb673}}
.box b{{color:{INK}}}
.ico{{width:38px;height:38px;border-radius:50%;background:{LGREY};display:inline-flex;align-items:center;justify-content:center;flex:0 0 auto}}
.cell{{display:flex;align-items:center;gap:10px}}
.ft{{position:absolute;bottom:10mm;left:13mm;right:13mm;display:flex;justify-content:space-between;font-size:9pt;color:{GREY};border-top:1px solid #e3e3e3;padding-top:8px}}
.lv{{display:flex;gap:6px;margin-top:6px}}
.lvb{{flex:1;text-align:center;border-radius:8px;padding:7px 4px;color:#fff;font-size:9.5pt;font-weight:bold}}
</style></head><body><div class="page">

<div class="hd">
  <div class="logo">{ic('sparkles','#fff',30)}</div>
  <div><h1>Claude Code — Hızlı Kullanım</h1>
  <div class="tag">Ne yazarsan ne olur · duvara as, bak, kullan</div></div>
</div>

<div class="concept">
  {ic('brain','#ff6b76',46,2)}
  <div><div class="big">Claude <span>hatırlamaz.</span> Her oturum sıfırdan.</div>
  <div class="sub">Bu yüzden bilgi dosyada yaşar: kural · journal · TODO. Otomatik kolaylıkların hepsi senin kurduğun skill / agent / hook sayesinde.</div></div>
</div>

<div class="sec">{ic('sunrise',RED,22)} Günlük ritüel</div>
<div class="ritual">
  <div class="rit">{ic('sunrise',RED,28)}<div class="t">günaydın</div><div class="d">dünü okur, "nerede kaldık" özeti</div></div>
  <div class="arr">→</div>
  <div class="rit">{ic('terminal',RED,28)}<div class="t">çalış + onayla</div><div class="d">hedefi söyle, planı onayla, commit'le</div></div>
  <div class="arr">→</div>
  <div class="rit">{ic('moon',RED,28)}<div class="t">iyi geceler</div><div class="d">günlüğe yazar, kaydeder</div></div>
</div>

<div class="sec">{ic('check',RED,22)} Ne dersen ne olur</div>
<table>
<tr><td class="cell">{ic('sunrise',RED,22)}<span class="cmd">günaydın</span></td><td>git + TODO + günlük okur, özetler <span class="via">· session-start hook + handoff</span></td></tr>
<tr><td class="cell">{ic('moon',RED,22)}<span class="cmd">iyi geceler</span></td><td>bugünü günlüğe yazar, TODO işaretler, commit'ler <span class="via">· session-handoff</span></td></tr>
<tr><td class="cell">{ic('git-commit',RED,22)}<span class="cmd">"commit'le"</span></td><td>tek-konu, doğru formatlı kayıt noktası <span class="via">· commit-discipline</span></td></tr>
<tr><td class="cell">{ic('scissors',RED,22)}<span class="cmd">"dosyaları böl"</span></td><td>15+ dosyayı anlamlı commit'lere ayırır <span class="via">· commit-splitter agent</span></td></tr>
<tr><td class="cell">{ic('shield-check',RED,22)}<span class="cmd">/security-check</span></td><td>güvenlik denetimi (auth, sır sızıntısı, validasyon)</td></tr>
<tr><td class="cell">{ic('circle-help',RED,22)}<span class="cmd">"hangi seçenek?"</span></td><td>5 danışman + sentez ile karar analizi <span class="via">· llm-council</span></td></tr>
</table>

<div class="sec">{ic('git-branch',RED,22)} Ustalık yolu</div>
<div class="lv">
  <div class="lvb" style="background:#8a94a6">L0 Acemi<br><span style="font-weight:400">kullan</span></div>
  <div class="lvb" style="background:#2bb673">L1 Junior<br><span style="font-weight:400">araç kullan</span></div>
  <div class="lvb" style="background:#2c7be5">L2 Senior<br><span style="font-weight:400">araç üret</span></div>
  <div class="lvb" style="background:#7d4ce0">L3 Leader<br><span style="font-weight:400">standartlaştır</span></div>
  <div class="lvb" style="background:#e0792c">L4 Plus<br><span style="font-weight:400">otomatikleştir</span></div>
</div>

<div class="row2">
  <div class="box warn"><b>⚠ Kural konuşmada yaşamaz.</b> "Aklında tut" deme → <b>"kurala yaz"</b> de. Yoksa bir sonraki oturum unutur.</div>
  <div class="box tip"><b>✓ Takılırsan:</b> "son değişikliği geri al" · commit bloklandıysa "neden?" sor · konu dağıldı → <span class="cmd" style="font-size:9.5pt">/compact</span></div>
</div>

<div class="ft"><span>claude-context-template · Kullanım Afişi</span><span>© Fikri Eren 2026</span></div>
</div></body></html>"""

out_html=os.path.join(HERE,"afis.html"); open(out_html,"w",encoding="utf8").write(HTML)
with sync_playwright() as p:
    b=p.chromium.launch();pg=b.new_page()
    pg.goto(pathlib.Path(out_html).resolve().as_uri(),wait_until="networkidle")
    pg.pdf(path=os.path.join(HERE,"Claude_Kullanim_Afisi.pdf"),prefer_css_page_size=True,print_background=True)
    pg2=b.new_page(viewport={"width":794,"height":1123});pg2.goto(pathlib.Path(out_html).resolve().as_uri(),wait_until="networkidle")
    pg2.screenshot(path=os.path.join(HERE,"_afis.png"),full_page=True)
    b.close()
print("OK afis")
