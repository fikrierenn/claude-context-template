const fs = require("fs");
const path = require("path");
const ICON = path.join(__dirname, "node_modules/lucide-static/icons");

// lucide svg oku, boyut+renk container ile dondur (stroke=currentColor zaten)
function ic(name, size=22, sw=2){
  let s = fs.readFileSync(path.join(ICON, name+".svg"), "utf8");
  s = s.replace(/width="24"/,'width="'+size+'"').replace(/height="24"/,'height="'+size+'"');
  s = s.replace(/stroke-width="2"/,'stroke-width="'+sw+'"');
  return s;
}
// renkli daire icinde ikon
function circ(name, bg, size=20){
  return `<span class="ic" style="background:${bg}">${ic(name,size,2.2)}</span>`;
}

const NAVY="#06283D", TEAL="#1C7293", AQUA="#2EC4B6", RED="#E63946",
      AMBER="#F4A259", GREEN="#2BB673", PURPLE="#7D4CE0", INK="#0f1b2d", MUTE="#7c8ba0";

// donut: yuzde halka
function donut(pct, color, label, sub){
  const r=70, c=2*Math.PI*r, off=c*(1-pct/100);
  return `<svg width="200" height="200" viewBox="0 0 200 200">
    <circle cx="100" cy="100" r="${r}" fill="none" stroke="#13415a" stroke-width="20"/>
    <circle cx="100" cy="100" r="${r}" fill="none" stroke="${color}" stroke-width="20"
       stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${off}"
       transform="rotate(-90 100 100)"/>
    <text x="100" y="96" text-anchor="middle" font-family="Georgia,serif" font-size="46" font-weight="bold" fill="#fff">${label}</text>
    <text x="100" y="122" text-anchor="middle" font-family="Segoe UI,Arial" font-size="13" fill="#9fc6d6">${sub}</text>
  </svg>`;
}
// katmanli 3D stack (mimari)
function stack(items){ // items: [{icon,bg,title,desc}]
  let y=0, out="";
  items.forEach((it,i)=>{
    out += `<div class="layer" style="background:${it.bg};margin-left:${i*8}px;">
      <span class="lic">${ic(it.icon,22,2.2)}</span>
      <span class="lt">${it.title}</span><span class="ld">${it.desc}</span></div>`;
  });
  return `<div class="stack">${out}</div>`;
}
// yatay bar (once/sonra sure)
function bars(){
  return `<svg width="430" height="120" viewBox="0 0 430 120">
    <text x="0" y="20" font-size="13" fill="#7c8ba0">Önce (ham)</text>
    <rect x="0" y="28" width="300" height="26" rx="6" fill="${RED}"/>
    <text x="310" y="46" font-size="15" font-weight="bold" fill="${RED}">~10 dk / oturum</text>
    <text x="0" y="84" font-size="13" fill="#7c8ba0">Sonra (yapı)</text>
    <rect x="0" y="92" width="14" height="26" rx="6" fill="${GREEN}"/>
    <text x="24" y="110" font-size="15" font-weight="bold" fill="${GREEN}">~0 dk · otomatik</text>
  </svg>`;
}

const CSS = `
@page{size:297mm 167mm;margin:0}*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Segoe UI",Helvetica,Arial,sans-serif;color:${INK};-webkit-print-color-adjust:exact;print-color-adjust:exact}
.s{width:297mm;height:167mm;page-break-after:always;position:relative;overflow:hidden}.s:last-child{page-break-after:auto}
.pad{padding:15mm 17mm;height:100%}
h1,.tt{font-family:Georgia,serif}
.kick{font-size:11.5pt;letter-spacing:4px;text-transform:uppercase;font-weight:700;color:${TEAL}}
.tt{font-size:30pt;font-weight:bold;color:${NAVY};line-height:1.1}
.sub{font-size:14.5pt;color:#43586e;line-height:1.5}.mute{color:${MUTE}}
.dark{background:radial-gradient(120% 130% at 80% 10%,#0d4f6b 0%,${NAVY} 55%,#04141f 100%);color:#eaf3f8}
.dark .kick{color:${AQUA}}.dark .tt{color:#fff}
.ft{position:absolute;bottom:7mm;left:17mm;right:17mm;display:flex;justify-content:space-between;font-size:8.5pt;color:#9fb0c2}
.dark .ft{color:#7fa8b8;border-top:1px solid rgba(255,255,255,.12);padding-top:6px}
.ic{width:42px;height:42px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;color:#fff;margin-bottom:9px}
.card{background:#fff;border-radius:14px;box-shadow:0 6px 20px rgba(6,40,61,.10);padding:16px 18px;border:1px solid #e7eef4}
.card h3{font-size:13.5pt;color:${NAVY};margin-bottom:4px}.card p{font-size:10.5pt;color:#37485c;line-height:1.4}
.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:15px}.grid2{display:grid;grid-template-columns:1fr 1fr;gap:18px}
.num{font-family:Georgia,serif;font-size:150pt;font-weight:bold;line-height:1;position:absolute;right:10mm;top:6mm}
.chip{display:inline-block;background:#eef5f9;border:1px solid #d3e1ec;border-radius:20px;padding:4px 13px;font-size:10.5pt;color:${TEAL};margin:3px 4px 0 0;font-weight:600}
table{border-collapse:collapse;width:100%;font-size:11pt}th{background:${NAVY};color:#fff;text-align:left;padding:8px 11px}
td{border-bottom:1px solid #e3eaf1;padding:7px 11px;color:#27384a}tr:nth-child(even) td{background:#f4f9fc}
.tdico{display:inline-flex;vertical-align:middle;margin-right:6px;color:${GREEN}}
.stack{display:flex;flex-direction:column;gap:9px}
.layer{display:flex;align-items:center;gap:12px;border-radius:12px;padding:11px 16px;color:#fff;box-shadow:0 4px 14px rgba(6,40,61,.18);width:88%}
.layer .lic{display:inline-flex}.layer .lt{font-weight:bold;font-size:13pt}.layer .ld{font-size:10.5pt;opacity:.9}
.flow{display:flex;align-items:stretch;gap:10px}.arrow{color:${AQUA};font-size:22pt;align-self:center}
.fnode{flex:1;border-radius:12px;padding:12px;font-size:11pt;text-align:center;display:flex;flex-direction:column;justify-content:center;gap:4px;align-items:center}
`;

let H = `<!DOCTYPE html><html lang="tr"><head><meta charset="utf-8"><style>${CSS}</style></head><body>`;
const FT=(n)=>`<div class="ft"><span>© Fikri Eren 2026</span><span>${String(n).padStart(2,"0")} / 16</span></div>`;

// 1 KAPAK
H+=`<div class="s dark"><div class="pad" style="display:flex;flex-direction:column;justify-content:center">
<div class="kick">Eğitim · claude-context-template</div>
<h1 style="font-size:50pt;color:#fff;line-height:1.04;margin:14px 0">Claude'u Süper<br>Güce Dönüştürmek</h1>
<div class="sub" style="color:#bfe0ea;max-width:175mm">Ham model ne yapar · handikapları neydi · skill / agent / hook / kural katmanı ona hangi süper güçleri kattı.</div>
<div style="margin-top:24px"><span class="chip" style="background:rgba(46,196,182,.12);border-color:${AQUA};color:#7fe9dc">6 bölüm</span><span class="chip" style="background:rgba(46,196,182,.12);border-color:${AQUA};color:#7fe9dc">~20 dk</span><span class="chip" style="background:rgba(46,196,182,.12);border-color:${AQUA};color:#7fe9dc">Acemi → Plus</span></div>
${FT(1)}</div></div>`;

// 2 GÜNDEM
const ag=[["cpu",TEAL,"Claude nedir?","Ne yapar, hangi ortamlar, neyi iyi yapar."],
["alert-triangle",RED,"Handikaplar","Ham haliyle 6 büyük zaaf."],
["zap",GREEN,"Süper güçler","Hafıza, hook, skill, agent, kural."],
["layers",AMBER,"Çözüm haritası","Hangi zaafı hangi yapı kapattı."],
["workflow",AQUA,"Önce / Sonra","Somut: günaydın deyince ne oluyor."],
["rocket",NAVY,"Sonuç","Akıl Claude'da değil, kurduğun yapıda."]];
H+=`<div class="s"><div class="pad"><div class="kick">Gündem</div>
<div class="tt" style="margin:6px 0 16px">Yolculuk altı durakta</div><div class="grid3">`;
ag.forEach(c=>H+=`<div class="card">${circ(c[0],c[1])}<h3>${c[2]}</h3><p>${c[3]}</p></div>`);
H+=`</div>${FT(2)}</div></div>`;

// 3 DIVIDER 01
H+=`<div class="s dark"><div class="num" style="color:rgba(46,196,182,.18)">01</div><div class="pad" style="display:flex;flex-direction:column;justify-content:center">
<div class="kick">Bölüm 1</div><h1 style="font-size:42pt;color:#fff;margin-top:10px">Claude nedir,<br>ne yapar?</h1>
<div class="sub" style="color:${AQUA};margin-top:12px">Temeli netleştirelim — sonra zaaflara geçeceğiz.</div>${FT(3)}</div></div>`;

// 4 CLAUDE NEDIR
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 1 · Temel</div>
<div class="tt" style="margin:6px 0 6px">İki yüzü var</div>
<div class="sub" style="margin-bottom:16px">Anthropic'in LLM'i. Bizim için kritik: kod ve dosyalarla çalışan asistana dönüşmesi.</div>
<div class="grid2">
<div class="card" style="border-top:4px solid ${MUTE}">${circ("message-circle",MUTE)}<h3>Genel Claude (sohbet)</h3><p>Soru-cevap, yazım, analiz. Kod örneği üretir — ama projene <b>doğrudan dokunamaz</b>.</p></div>
<div class="card" style="border-top:4px solid ${TEAL}">${circ("monitor",TEAL)}<h3>Claude Code (asistan)</h3><p>Dosyaları okur/yazar/çalıştırır · git commit · test koşar · çok adımlı görevi yürütür · her adımda <b>onay ister</b>.</p></div></div>
<div class="card" style="margin-top:16px;background:${NAVY};border:none"><p style="color:#cfe6ee;font-family:Georgia,serif;font-size:16pt;font-style:italic">"Chatbot değil — proje klasöründe oturan, yönlendirme bekleyen kıdemli bir yazılımcı."</p></div>
${FT(4)}</div></div>`;

// 5 ORTAMLAR
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 1 · Temel</div>
<div class="tt" style="margin:6px 0 16px">Nerede kullanılır?</div><div class="grid3">
<div class="card" style="border-top:4px solid ${GREEN}">${circ("message-circle",GREEN)}<h3>Chat (claude.ai)</h3><p>Düşünme, taslak, doküman. Projeler + Skills. <span class="mute">git/hook yok.</span></p></div>
<div class="card" style="border-top:4px solid ${PURPLE}">${circ("users",PURPLE)}<h3>Cowork</h3><p>Ajan görevleri. Skill + MCP + plugin. İzole worktree.</p></div>
<div class="card" style="border-top:4px solid ${TEAL}">${circ("monitor",TEAL)}<h3>Desktop / Terminal</h3><p>Tam güç: dosya + git + hook + agent. <b>Bu sunumun odağı.</b></p></div></div>
<div style="margin-top:16px"><span class="mute" style="font-size:13pt;font-weight:600">İyi yaptıkları:</span></div>
<div style="margin-top:4px"><span class="chip">mekanik işi hızlı bitirir</span><span class="chip">geniş kod tabanını tarar</span><span class="chip">çok dosyalı düşünür</span><span class="chip">açıklar, öğretir</span><span class="chip">tutarlı hız</span></div>
<div class="card" style="margin-top:14px;border-left:5px solid ${AMBER}"><p style="font-size:12pt"><b>Ama</b> — kutudan çıktığı <b>ham</b> haliyle ciddi handikapları var.</p></div>
${FT(5)}</div></div>`;

// 6 DIVIDER 02
H+=`<div class="s dark"><div class="num" style="color:rgba(230,57,70,.22)">02</div><div class="pad" style="display:flex;flex-direction:column;justify-content:center">
<div class="kick" style="color:#ff8b93">Bölüm 2 · Problem</div><h1 style="font-size:42pt;color:#fff;margin-top:10px">Ham Claude'un<br>handikapları</h1>
<div class="sub" style="color:#ffc9cd;margin-top:12px">Güçlü ama disiplinsiz.</div>${FT(6)}</div></div>`;

// 7 STAT donut
H+=`<div class="s dark"><div class="pad" style="display:flex;align-items:center;gap:50px">
<div>${donut(100,RED,"%100","hafıza kaybı")}</div>
<div style="flex:1"><div class="kick" style="color:#ff8b93">En büyük zaaf</div>
<div class="sub" style="color:#dfeaf0;font-size:19pt;margin-top:10px;max-width:150mm">Her yeni oturumda <b style="color:${AQUA}">tam hafıza kaybı</b>. Claude dünü, kararları, talimatları hatırlamaz — her sabah hafızası silinmiş bir stajyer.</div>
<div class="sub" style="margin-top:14px;color:#8fb0c0">Sonuç: tekrar anlatım · tutarsızlık · "bir gün unutursun → bug".</div></div>
${FT(7)}</div></div>`;

// 8 6 HANDIKAP
const hd=[["1 · Hafızasızlık","Her oturum sıfırdan. Dünü hatırlamaz."],
["2 · Tutarsızlık","Aynı işi her sefer farklı yapar."],
["3 · Disiplinsizlik","Commit/test/plan'ı kendiliğinden uygulamaz."],
["4 · Domain körlüğü","Senin işini bilmez; uydurabilir."],
["5 · Riskli işlem","Dosya siler, sır sızdırır."],
["6 · Sahte \"bitti\"","Çalıştırmadan 'tamam' der."]];
H+=`<div class="s"><div class="pad"><div class="kick" style="color:${RED}">Bölüm 2 · Problem</div>
<div class="tt" style="margin:6px 0 14px">Altı handikap</div><div class="grid3">`;
hd.forEach(c=>H+=`<div class="card" style="border-left:5px solid ${RED}"><div style="display:flex;align-items:center;gap:8px;color:${RED};margin-bottom:4px">${ic("alert-triangle",18,2.2)}<h3 style="margin:0">${c[0]}</h3></div><p>${c[1]}</p></div>`);
H+=`</div>${FT(8)}</div></div>`;

// 9 DIVIDER 03
H+=`<div class="s dark"><div class="num" style="color:rgba(43,182,115,.22)">03</div><div class="pad" style="display:flex;flex-direction:column;justify-content:center">
<div class="kick" style="color:#7fe9b0">Bölüm 3 · Çözüm</div><h1 style="font-size:42pt;color:#fff;margin-top:10px">Bizim katman:<br>süper güçler</h1>
<div class="sub" style="color:#bfead2;margin-top:12px">Ham model + <span style="color:${AQUA}">.claude/</span> kalıcı yapısı = her zaafa cevap.</div>${FT(9)}</div></div>`;

// 10 MIMARI STACK
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 3 · Mimari</div>
<div class="tt" style="margin:6px 0 16px">Beş bileşenli yapı</div>
${stack([
{icon:"brain",bg:GREEN,title:"Hafıza katmanı",desc:"CLAUDE.md + rules + journal + TODO"},
{icon:"cpu",bg:TEAL,title:"Hook'lar",desc:"olay tetikli — unutsa bile mekanik çalışır"},
{icon:"package",bg:PURPLE,title:"Skills",desc:"çok adımlı iş reçeteleri"},
{icon:"bot",bg:AMBER,title:"Agent'lar",desc:"izole uzmanlar + model katmanı"},
{icon:"scroll-text",bg:NAVY,title:"Kurallar",desc:"14 evrensel kalıcı davranış"}])}
${FT(10)}</div></div>`;

// 11 HOOK + FLOW
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 3 · Nasıl çalışır</div>
<div class="tt" style="margin:6px 0 14px">Hafıza dışsallaştırılır</div>
<div class="flow" style="margin:14px 0">
<div class="fnode" style="background:#fdecee;border:1px solid ${RED}">${ic("brain",26,2)}<b>Yeni oturum</b><span class="mute">boş başlar</span></div>
<div class="arrow">➜</div>
<div class="fnode" style="background:#eef5f9;border:1px solid ${TEAL}">${ic("cpu",26,2)}<b>session-start hook</b><span>git + TODO + journal okur</span></div>
<div class="arrow">➜</div>
<div class="fnode" style="background:#e9f7ef;border:1px solid ${GREEN}">${ic("circle-check",26,2)}<b>bağlam yüklü</b><span>"nerede kaldık" özeti</span></div></div>
<div class="grid3" style="margin-top:8px">
<div class="card">${circ("terminal",TEAL)}<h3>session-start</h3><p>Açılışta otomatik durum özeti.</p></div>
<div class="card">${circ("shield-check",RED)}<h3>pre-commit</h3><p>Şifre/riskli desen → commit'i bloklar.</p></div>
<div class="card">${circ("book-open",GREEN)}<h3>post-commit</h3><p>Her commit → günlüğe otomatik kayıt.</p></div></div>
${FT(11)}</div></div>`;

// 12 DIVIDER 04
H+=`<div class="s dark"><div class="num" style="color:rgba(244,162,89,.22)">04</div><div class="pad" style="display:flex;flex-direction:column;justify-content:center">
<div class="kick" style="color:#ffd0a0">Bölüm 4 · Harita</div><h1 style="font-size:42pt;color:#fff;margin-top:10px">Handikap →<br>nasıl güçlendirdik</h1>${FT(12)}</div></div>`;

// 13 HARITA TABLO
const map=[["Hafızasızlık","3 katman hafıza + session-start hook","Her oturum dünü hatırlar"],
["Tutarsızlık","Kurallar + Skills (reçete)","Her sefer aynı doğru sonuç"],
["Disiplinsizlik","commit/plan/test kuralları + hook","Disiplin mekanik, atlanamaz"],
["Domain körlüğü","Proje-özel skill + kural + ADR","Senin işini bilir, uydurmaz"],
["Riskli işlem","pre-commit hook + before-major-change","Sır sızmaz, riskli işlem onaylı"],
["Sahte \"bitti\"","verify skill + test-discipline + denetçi agent","Çalıştırmadan 'tamam' yok"]];
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 4 · Eşleme</div>
<div class="tt" style="margin:6px 0 10px">Her zaaf bir yapı ile kapandı</div>
<table><tr><th>Ham zaaf</th><th>Çözüm (yapı)</th><th>Sonuç</th></tr>`;
map.forEach((r,i)=>H+=`<tr><td><b>${i+1}</b> ${r[0]}</td><td>${r[1]}</td><td><span class="tdico">${ic("check",15,2.5)}</span>${r[2]}</td></tr>`);
H+=`</table>${FT(13)}</div></div>`;

// 14 ONCE/SONRA + bar
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 5 · Somut</div>
<div class="tt" style="margin:6px 0 12px">Tek kelime: <span style="font-family:Consolas,monospace;color:${TEAL}">günaydın</span></div>
<div class="grid2">
<div class="card" style="border-top:4px solid ${RED};background:#fff7f8"><div class="kick" style="color:${RED}">Önce · ham</div><p style="margin-top:8px;font-size:11.5pt">Claude: <i>"Merhaba! Nasıl yardımcı olabilirim?"</i></p><p style="margin-top:8px;color:#b03038"><b>→ Dünü bilmez. Baştan anlatırsın.</b></p></div>
<div class="card" style="border-top:4px solid ${GREEN};background:#f5fcf8"><div class="kick" style="color:#1e7a4d">Sonra · yapı kurulu</div><p style="margin-top:8px;font-size:11.5pt">Claude: <i>"Dün giriş formu bitti. Bugün şifre sıfırlama (Faz 0). 3 uncommitted. Başlayalım mı?"</i></p><p style="margin-top:8px;color:#1e7a4d"><b>→ session-start + handoff okudu.</b></p></div></div>
<div style="display:flex;align-items:center;gap:30px;margin-top:12px">
<div class="card" style="flex:0 0 auto">${bars()}</div>
<div class="card" style="flex:1;background:${NAVY};border:none"><p style="font-size:12.5pt;color:#cfe6ee"><b style="color:${AQUA}">"günaydın" sihirli değil.</b> Arkada git + TODO + günlük + özet — hepsi <b>senin kurduğun yapı</b> sayesinde.</p></div></div>
${FT(14)}</div></div>`;

// 15 TETIK -> YAPI
const tr=[["günaydın","session-start hook + handoff","git/TODO/journal okur, özetler"],
["iyi geceler","session-handoff skill","günlüğe yazar, TODO işaretler, commit'ler"],
["dosyaları böl","commit-splitter agent","15+ dosyayı bucket'lara ayırır"],
["hangi seçenek?","llm-council skill","5 danışman + sentez"],
["(commit'te şifre)","pre-commit hook","sızıntıyı yakalar, bloklar"]];
H+=`<div class="s"><div class="pad"><div class="kick">Bölüm 5 · Somut</div>
<div class="tt" style="margin:6px 0 10px">Söz → yapı → eylem</div>
<table><tr><th>Sen dersin</th><th>Hangi yapı sayesinde</th><th>Ne yapar</th></tr>`;
tr.forEach(r=>H+=`<tr><td style="font-family:Consolas,monospace;color:${TEAL}">${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td></tr>`);
H+=`</table><div class="card" style="margin-top:14px;border-left:5px solid ${AQUA}"><p style="font-size:12.5pt;font-family:Georgia,serif;font-style:italic;color:${NAVY}">Her kolaylık = bir tetik söz + senin kurduğun bir yapı. Yapıyı sil → kolaylık kaybolur.</p></div>
${FT(15)}</div></div>`;

// 16 KAPANIS
H+=`<div class="s dark"><div class="pad" style="display:flex;flex-direction:column;justify-content:center">
<div class="kick">Bölüm 6 · Sonuç</div>
<h1 style="font-size:46pt;color:#fff;line-height:1.06;margin:12px 0">Akıl Claude'da değil —<br><span style="color:${AQUA}">kurduğun yapıda.</span></h1>
<div class="sub" style="color:#cfe6ee;max-width:185mm">Ham model güçlü ama disiplinsiz. Hafıza + hook + skill + agent + kural katmanı her handikabı süper güce çevirdi. Daha fazla kolaylık istersen: daha fazla yapı yaz.</div>
<div style="margin-top:22px;display:flex;align-items:center;gap:10px;color:#7fe9dc;font-size:13.5pt;font-weight:600">${ic("rocket",22,2.2)} Kullan → Üret → Standartlaştır → Otomatikleştir</div>
${FT(16)}</div></div>`;

H+=`</body></html>`;
fs.writeFileSync(path.join(__dirname,"egitim_sunumu_v3.html"), H);
console.log("yazildi: egitim_sunumu_v3.html ("+H.length+" byte)");
