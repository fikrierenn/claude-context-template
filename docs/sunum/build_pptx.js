const PptxGenJS = require("pptxgenjs");
const p = new PptxGenJS();
p.defineLayout({ name: "W", width: 13.333, height: 7.5 });
p.layout = "W";

// palet
const NAVY="1E2761", BLUE="2C7BE5", GREEN="2BB673", RED="E74C3C",
      PURPLE="7D4CE0", AMBER="E0992C", INK="16202C", LIGHT="F2F6FC",
      WHITE="FFFFFF", MUTE="9AA7B5", DARK="0B1E3A";
const HF="Georgia", BF="Calibri";

function footer(s, n){
  s.addText("© Fikri Eren 2026", {x:0.5,y:7.05,w:5,h:0.3,fontFace:BF,fontSize:9,color:MUTE});
  s.addText(String(n), {x:12.4,y:7.05,w:0.5,h:0.3,fontFace:BF,fontSize:9,color:MUTE,align:"right"});
}
function chip(s, txt, col){
  s.addText(txt.toUpperCase(), {x:0.6,y:0.45,w:5,h:0.35,fontFace:BF,fontSize:11,bold:true,color:col,charSpacing:2});
}
function title(s, txt){
  s.addText(txt, {x:0.6,y:0.8,w:12.1,h:0.95,fontFace:HF,fontSize:32,bold:true,color:NAVY,valign:"top"});
}
// kart
function card(s, x,y,w,h, head, body, accent){
  s.addShape(p.ShapeType.roundRect,{x,y,w,h,fill:{color:LIGHT},line:{color:accent,width:1.5},rectRadius:0.08});
  s.addText([
    {text:head+"\n",options:{fontFace:BF,fontSize:14,bold:true,color:NAVY}},
    {text:body,options:{fontFace:BF,fontSize:11,color:INK}}
  ],{x:x+0.18,y:y+0.14,w:w-0.36,h:h-0.28,valign:"top",lineSpacingMultiple:1.0});
}

// ---------- 1 KAPAK ----------
let s=p.addSlide(); s.background={color:DARK};
s.addText("EĞİTİM SUNUMU",{x:1,y:1.7,w:10,h:0.4,fontFace:BF,fontSize:14,bold:true,color:"7FA8D8",charSpacing:3});
s.addText("Claude'u Süper Güce Dönüştürmek",{x:1,y:2.2,w:11.3,h:1.8,fontFace:HF,fontSize:44,bold:true,color:WHITE,valign:"top"});
s.addText("Ham Claude ne yapar · Handikapları neydi · Skill / agent / hook / kural katmanı ona hangi süper güçleri kattı.",
  {x:1,y:4.0,w:10.5,h:1,fontFace:BF,fontSize:17,color:"D6E2F2"});
s.addText("claude-context-template · Eğitim · © Fikri Eren 2026",{x:1,y:6.7,w:11,h:0.4,fontFace:BF,fontSize:11,color:"8FA6C4"});

// ---------- 2 GÜNDEM ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Gündem",BLUE); title(s,"Bugün ne anlatacağız?");
const g=[
 ["1 · Claude nedir?","Ne yapar, hangi ortamlar (Chat/Desktop/Cowork/Terminal), neyi iyi yapar.",BLUE],
 ["2 · Ham Claude'un handikapları","Kutudan çıktığı haliyle 6 büyük zaaf. Neden tek başına yetmez.",RED],
 ["3 · Bizim katman = süper güçler","Hafıza, hook, skill, agent, kural — her zaafı kapatan yapı.",GREEN],
 ["4 · Handikap → Çözüm haritası","Hangi zaafı hangi yapı ile güçlendirdik.",AMBER],
 ["5 · Önce / Sonra","Somut: günaydın deyince ne oluyor, neden.",PURPLE],
 ["6 · Sonuç","Akıl Claude'da değil, kurduğun yapıda. Nasıl büyür.",BLUE],
];
g.forEach((c,i)=>{const col=i%3, row=Math.floor(i/3); card(s,0.6+col*4.05,2.0+row*2.3,3.8,2.0,c[0],c[1],c[2]);});
footer(s,2);

// ---------- 3 CLAUDE NEDIR ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 1 · Temel",BLUE); title(s,"Claude nedir?");
s.addText("Anthropic'in büyük dil modeli (LLM). Bizim için önemlisi: kod ve dosyalarla çalışan bir asistana dönüşmesi.",
  {x:0.6,y:1.75,w:12,h:0.6,fontFace:BF,fontSize:15,color:"37485C"});
card(s,0.6,2.5,5.9,2.6,"Genel Claude (sohbet)","• Soru-cevap, yazım, analiz, özet\n• Kod örneği üretir (kopyalarsın)\n• Dosyana/projene doğrudan dokunamaz",MUTE);
card(s,6.8,2.5,5.9,2.6,"Claude Code (asistan)","• Gerçek dosyaları okur, yazar, çalıştırır\n• git ile commit eder, test koşar\n• Çok adımlı görevi kendi yürütür\n• Her önemli adımda onay ister",BLUE);
s.addText("“Chatbot değil — proje klasöründe oturan, yönlendirme bekleyen kıdemli bir yazılımcı.”",
  {x:0.6,y:5.4,w:12,h:0.8,fontFace:HF,fontSize:17,italic:true,color:NAVY});
footer(s,3);

// ---------- 4 ORTAMLAR ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 1 · Temel",BLUE); title(s,"Claude'u nerede kullanırız?");
card(s,0.6,1.95,3.9,2.2,"💬 Chat (claude.ai)","Düşünme, taslak, doküman. Projeler + Skills. git/hook/terminal yok.",GREEN);
card(s,4.7,1.95,3.9,2.2,"🤝 Cowork","Ajan görevleri. Skill + MCP + plugin. İzole worktree.",PURPLE);
card(s,8.8,1.95,3.9,2.2,"🖥️ Desktop / Terminal","Tam güç: dosya + git + hook + agent. Bu sunumun odağı.",BLUE);
s.addText([
 {text:"Neyi iyi yapar?\n",options:{bold:true,fontSize:15,color:NAVY,fontFace:BF}},
 {text:"Tekrarlayan/mekanik işi hızlı bitirir · geniş kod tabanını tarar · çok dosyalı düşünür · açıklar, öğretir · yorulmaz, tutarlı hızda çalışır.",options:{fontSize:13,color:INK,fontFace:BF}}
],{x:0.6,y:4.45,w:12,h:1.1,valign:"top"});
card(s,0.6,5.6,12.1,0.95,"Ama...","kutudan çıktığı HAM haliyle ciddi handikapları var. Sıradaki bölüm.",AMBER);
footer(s,4);

// ---------- 5 HANDIKAPLAR ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 2 · Problem",RED); title(s,"Ham Claude'un 6 handikabı");
const h=[
 ["1 · Hafızasızlık","Her oturum SIFIRDAN başlar. Dünü, kararları, talimatları hatırlamaz."],
 ["2 · Tutarsızlık","Aynı işi her sefer farklı yapar. Standart kaymaz garantisi yok."],
 ["3 · Disiplinsizlik","Commit'i, test'i, planı kendiliğinden uygulamaz. Unutur."],
 ["4 · Domain körlüğü","Senin işini/mevzuatını bilmez; genel bilgiyle uydurabilir."],
 ["5 · Riskli işlem","Yanlışlıkla dosya siler, sır sızdırır, geri-alınamaz komut çalıştırır."],
 ["6 · Sahte 'bitti'","Çalıştırmadan 'tamam' der. Doğrulamaz, sessiz hata bırakır."],
];
h.forEach((c,i)=>{const col=i%3,row=Math.floor(i/3); card(s,0.6+col*4.05,1.95+row*2.25,3.8,2.0,c[0],c[1],RED);});
footer(s,5);

// ---------- 6 HAFIZA DERIN ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 2 · Derin",RED); title(s,"En büyük handikap: hafızasızlık");
s.addText("Claude her sabah hafızası silinmiş çok yetenekli bir stajyer gibidir. Dün ne yaptığınızı bilmez.",
  {x:0.6,y:1.75,w:12,h:0.6,fontFace:BF,fontSize:15,color:"37485C"});
const fl=[["Yeni oturum\n🧠 boş",RED],["Sen yine\nanlatırsın",AMBER],["Bir gün\nunutursun",RED],["Kural ihlali\n/ bug",RED]];
fl.forEach((n,i)=>{
  s.addShape(p.ShapeType.roundRect,{x:0.7+i*3.05,y:2.5,w:2.5,h:1.1,fill:{color:LIGHT},line:{color:n[1],width:1.5},rectRadius:0.08});
  s.addText(n[0],{x:0.7+i*3.05,y:2.5,w:2.5,h:1.1,fontFace:BF,fontSize:13,bold:true,color:NAVY,align:"center",valign:"middle"});
  if(i<3) s.addText("➜",{x:3.05+i*3.05,y:2.5,w:0.5,h:1.1,fontFace:BF,fontSize:22,color:BLUE,align:"center",valign:"middle"});
});
s.addText([
 {text:"Bedeli: ",options:{bold:true,color:NAVY}},
 {text:"her oturum tekrar = zaman+token israfı · tutarsızlık · bilgi konuşmada yaşar → /clear ile buharlaşır.",options:{}}
],{x:0.6,y:4.0,w:12,h:0.8,fontFace:BF,fontSize:13,color:INK});
s.addText("“Çözüm: hafızayı Claude'a değil, dosyalara emanet etmek.”",
  {x:0.6,y:5.0,w:12,h:0.7,fontFace:HF,fontSize:18,italic:true,color:NAVY});
footer(s,6);

// ---------- 7 ÇÖZÜM 5 SÜPER GÜÇ ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 3 · Çözüm",GREEN); title(s,"Bizim katman: süper güçler");
const sg=[
 ["🧠 Hafıza katmanı","CLAUDE.md + rules + journal + TODO. Bilgi dosyada yaşar, oturumlar arası taşınır.",GREEN],
 ["⚙️ Hook'lar","Otomatik tetiklenen script'ler. İnsan/LLM unutsa bile çalışır.",BLUE],
 ["📦 Skills","Çok adımlı iş reçeteleri. 'Şunu hep şöyle yap.'",PURPLE],
 ["🤖 Agent'lar","İzole uzman yardımcılar + model katmanı (haiku/sonnet/opus).",AMBER],
 ["📋 Kurallar","Kalıcı davranış: commit, plan, test, güvenlik disiplini.",GREEN],
 ["🚀 Bootstrap","Tüm yapıyı tek komutla her projeye kurar/günceller.",BLUE],
];
sg.forEach((c,i)=>{const col=i%3,row=Math.floor(i/3); card(s,0.6+col*4.05,1.95+row*2.25,3.8,2.0,c[0],c[1],c[2]);});
footer(s,7);

// ---------- 8 HAFIZA KATMANI ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Süper Güç 1",GREEN); title(s,"🧠 Hafıza katmanı — 3 kademe");
s.addTable([
 [{text:"Katman",options:{bold:true,color:WHITE,fill:NAVY}},{text:"Dosya",options:{bold:true,color:WHITE,fill:NAVY}},{text:"Ne tutar",options:{bold:true,color:WHITE,fill:NAVY}}],
 ["Kimlik","CLAUDE.md","Proje tanımı, stack, klasörler (değişmez)"],
 ["Kural",".claude/rules/*.md","Kalıcı davranış talimatları"],
 ["Süreç","TODO.md · journal/ · ADR/","Plan, öncelik, günlük, kararlar"],
],{x:0.6,y:2.0,w:12.1,fontFace:BF,fontSize:14,border:{type:"solid",color:"D4DCE6"},rowH:0.55,valign:"middle",color:INK});
card(s,0.6,4.6,12.1,1.4,"Kattığı süper güç","Claude her oturum başı bu dosyaları okur → 'hatırlar'. Dün ne yaptığını, hangi kuralın geçerli olduğunu bilir. ► Handikap 1 (hafızasızlık) kapandı.",GREEN);
footer(s,8);

// ---------- 9 HOOKLAR ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Süper Güç 2",BLUE); title(s,"⚙️ Hook'lar — unutulamayan refleksler");
s.addText("Olay tetikli script. Karara/hafızaya değil, mekanik çalışmaya dayanır → atlanamaz.",
  {x:0.6,y:1.75,w:12,h:0.5,fontFace:BF,fontSize:14,color:"37485C"});
card(s,0.6,2.4,3.9,2.2,"session-start","Oturum açılınca: son commit'ler, TODO, uncommitted, son günlük → otomatik özet.",BLUE);
card(s,4.7,2.4,3.9,2.2,"pre-commit-antipattern","Commit öncesi tarar: hardcoded şifre, riskli desen → commit'i bloklar.",RED);
card(s,8.8,2.4,3.9,2.2,"post-commit-journal","Her başarılı commit → günlüğe otomatik kayıt.",GREEN);
card(s,0.6,5.0,12.1,1.3,"Kattığı süper güç","'Claude dikkat etsin' demek yetmez — bazen atlar. Hook atlamaz. ► Handikap 3 (disiplinsizlik) + 5 (riskli işlem) kapandı.",AMBER);
footer(s,9);

// ---------- 10 SKILLS ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Süper Güç 3",PURPLE); title(s,"📦 Skills — iş reçeteleri");
s.addText("Çok adımlı, domain-bilgili işin tek dosyada standardı. Tetik söz ile çalışır.",
  {x:0.6,y:1.75,w:12,h:0.5,fontFace:BF,fontSize:14,color:"37485C"});
card(s,0.6,2.4,3.9,2.2,"session-handoff","'iyi geceler' → bugünü günlüğe yazar, TODO senkronlar, commit'ler.",PURPLE);
card(s,4.7,2.4,3.9,2.2,"plan-tracker","Çok adımlı planı TODO.md ile canlı senkron tutar.",PURPLE);
card(s,8.8,2.4,3.9,2.2,"llm-council","'hangi seçenek?' → 5 danışman + sentez ile karar analizi.",PURPLE);
card(s,0.6,5.0,12.1,1.3,"Kattığı süper güç","Domain bilgisi + adım sırası kalıcı. Herkes aynı reçeteyle çalışır. ► Handikap 2 (tutarsızlık) + 4 (domain körlüğü) kapandı.",GREEN);
footer(s,10);

// ---------- 11 AGENTS ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Süper Güç 4",AMBER); title(s,"🤖 Agent'lar — izole uzmanlar");
card(s,0.6,1.95,5.9,3.0,"Örnek agent'lar","• commit-splitter — 15+ dosyayı bucket'lara böler\n• security-reviewer — güvenlik denetimi (opus)\n• silent-failure-hunter — sessiz hata avı\n• build-validator / test-runner — hızlı kontrol (haiku)",AMBER);
card(s,6.8,1.95,5.9,3.0,"Model katmanı","haiku → mekanik, ucuz, hızlı tarama\nsonnet → dengeli analiz + üretim\nopus → yüksek-risk derin muhakeme\n\nSalt-okuma: denetçi agent yazamaz — 'raporla, çözme'.",BLUE);
card(s,0.6,5.15,12.1,1.2,"Kattığı süper güç","Paralel + uzmanlaşmış iş, kontrollü maliyet, bağımsız denetim. ► Handikap 6 (sahte bitti) için bağımsız doğrulayıcı.",GREEN);
footer(s,11);

// ---------- 12 KURALLAR ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Süper Güç 5",GREEN); title(s,"📋 Kurallar — kalıcı içgüdü");
s.addText("Her oturum yüklenen davranış anayasası (14 evrensel kural). Tetik gerekmez, hep aktif.",
  {x:0.6,y:1.75,w:12,h:0.5,fontFace:BF,fontSize:14,color:"37485C"});
card(s,0.6,2.4,5.9,2.5,"Disiplin","• commit-discipline — 1 commit=1 konu, 15 dosya eşiği\n• plan-first — büyük işte önce plan + onay\n• test-discipline — 'bitti' demeden test koş\n• todo-verification — iddiayı canlı kodla doğrula",GREEN);
card(s,6.8,2.4,5.9,2.5,"Güvenlik & kalite","• error-handling — sessiz yutma yasak\n• security-principles — sır/SQL/XSS koruması\n• before-major-change — silmeden grep + onay\n• agent-usage — doğru iş→agent→model",GREEN);
card(s,0.6,5.1,12.1,1.2,"Kattığı süper güç","Her zaaf için kalıcı koruma. ► Handikap 3 (disiplin) + 5 (güvenlik) + 6 (doğrulama) kapandı.",AMBER);
footer(s,12);

// ---------- 13 HARITA ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 4 · Harita",AMBER); title(s,"Handikap → nasıl güçlendirdik");
s.addTable([
 [{text:"Ham Claude zaafı",options:{bold:true,color:WHITE,fill:NAVY}},{text:"Bizim çözüm (yapı)",options:{bold:true,color:WHITE,fill:NAVY}},{text:"Sonuç",options:{bold:true,color:WHITE,fill:NAVY}}],
 ["1 · Hafızasızlık","3 katman hafıza + session-start hook","Her oturum dünü hatırlar"],
 ["2 · Tutarsızlık","Kurallar + Skills (reçete)","Her sefer aynı doğru sonuç"],
 ["3 · Disiplinsizlik","commit/plan/test kuralları + hook","Disiplin mekanik, atlanamaz"],
 ["4 · Domain körlüğü","Proje-özel skill + kural + ADR","Senin işini bilir, uydurmaz"],
 ["5 · Riskli işlem","pre-commit hook + before-major-change","Sır sızmaz, riskli işlem onaylı"],
 ["6 · Sahte 'bitti'","verify skill + test-discipline + denetçi agent","Çalıştırmadan 'tamam' yok"],
],{x:0.6,y:1.95,w:12.1,fontFace:BF,fontSize:12.5,border:{type:"solid",color:"D4DCE6"},rowH:0.62,valign:"middle",color:INK});
footer(s,13);

// ---------- 14 ÖNCE/SONRA ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 5 · Somut",PURPLE); title(s,"Önce / Sonra — günaydın");
s.addShape(p.ShapeType.roundRect,{x:0.6,y:2.0,w:5.9,h:3.2,fill:{color:"FDECEA"},line:{color:RED,width:1.5},rectRadius:0.08});
s.addText([
 {text:"ÖNCE (ham Claude)\n\n",options:{bold:true,fontSize:15,color:"C0392B"}},
 {text:"Sen: 'günaydın'\n\nClaude: 'Merhaba! Nasıl yardımcı olabilirim?'\n\n→ Dünü bilmez. Sen baştan anlatırsın. 10 dk kayıp.",options:{fontSize:13,color:INK}}
],{x:0.8,y:2.2,w:5.5,h:2.8,fontFace:BF,valign:"top"});
s.addShape(p.ShapeType.roundRect,{x:6.8,y:2.0,w:5.9,h:3.2,fill:{color:"E9F7EF"},line:{color:GREEN,width:1.5},rectRadius:0.08});
s.addText([
 {text:"SONRA (yapı kurulu)\n\n",options:{bold:true,fontSize:15,color:"1E7A4D"}},
 {text:"Sen: 'günaydın'\n\nClaude: 'Dün giriş formu bitti. Bugün şifre sıfırlama (Faz 0). 3 uncommitted dosya var. Başlayalım mı?'\n\n→ session-start hook + handoff skill okudu.",options:{fontSize:13,color:INK}}
],{x:7.0,y:2.2,w:5.5,h:2.8,fontFace:BF,valign:"top"});
card(s,0.6,5.4,12.1,1.1,"Tek kelime, arkada senin kurduğun yapı","git durumu + TODO Faz 0 + son günlük + özet. 'günaydın' sihirli değil — o iki dosya sayesinde çalışıyor.",AMBER);
footer(s,14);

// ---------- 15 TETIK -> YAPI ----------
s=p.addSlide(); s.background={color:WHITE}; chip(s,"Bölüm 5 · Somut",PURPLE); title(s,"Hangi söz → hangi yapı → ne yapar");
s.addTable([
 [{text:"Sen dersin",options:{bold:true,color:WHITE,fill:NAVY}},{text:"Hangi yapı sayesinde",options:{bold:true,color:WHITE,fill:NAVY}},{text:"Ne yapar",options:{bold:true,color:WHITE,fill:NAVY}}],
 ["günaydın","session-start hook + handoff","git/TODO/journal okur, özetler"],
 ["iyi geceler","session-handoff skill","günlüğe yazar, TODO işaretler, commit'ler"],
 ["dosyaları böl","commit-splitter agent","15+ dosyayı bucket'lara ayırır"],
 ["hangi seçenek?","llm-council skill","5 danışman + sentez"],
 ["(commit'te şifre)","pre-commit hook","sızıntıyı yakalar, bloklar"],
],{x:0.6,y:1.95,w:12.1,fontFace:BF,fontSize:13,border:{type:"solid",color:"D4DCE6"},rowH:0.6,valign:"middle",color:INK});
s.addText("Her kolaylık = bir tetik söz + senin kurduğun bir yapı. Yapıyı sil → kolaylık kaybolur.",
  {x:0.6,y:5.5,w:12,h:0.7,fontFace:HF,fontSize:16,italic:true,color:NAVY});
footer(s,15);

// ---------- 16 SONUÇ ----------
s=p.addSlide(); s.background={color:"0A3D2E"};
s.addText("BÖLÜM 6 · SONUÇ",{x:1,y:1.5,w:10,h:0.4,fontFace:BF,fontSize:14,bold:true,color:"BFE9D4",charSpacing:3});
s.addText("Akıl Claude'da değil —\nkurduğun yapıda.",{x:1,y:2.0,w:11.3,h:1.8,fontFace:HF,fontSize:40,bold:true,color:WHITE,valign:"top"});
s.addText("Ham Claude güçlü ama disiplinsiz. Hafıza + hook + skill + agent + kural katmanı, her handikabı süper güce çevirdi. Daha fazla kolaylık istiyorsan: daha fazla yapı yaz.",
  {x:1,y:4.0,w:10.8,h:1.2,fontFace:BF,fontSize:16,color:"D6F0E2"});
s.addText("Kullan (Acemi/Junior) → Üret (Senior) → Standartlaştır (Leader) → Otomatikleştir (Plus)",
  {x:1,y:5.3,w:11,h:0.5,fontFace:BF,fontSize:14,bold:true,color:"8FD9B5"});
s.addText("claude-context-template · Eğitim Sunumu · © Fikri Eren 2026",{x:1,y:6.8,w:11,h:0.4,fontFace:BF,fontSize:11,color:"7FB89C"});

p.writeFile({fileName:"Claude_Egitim_Sunumu.pptx"}).then(f=>console.log("yazildi:",f));
