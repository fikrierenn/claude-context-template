const P=require("pptxgenjs"); const path=require("path");
const p=new P(); p.defineLayout({name:"W",width:13.333,height:7.5}); p.layout="W";
const ICO=path.join(__dirname,"_icons");
const NAVY="06283D",TEAL="1C7293",AQUA="2EC4B6",RED="E63946",AMBER="F4A259",
      GREEN="2BB673",PURPLE="7D4CE0",INK="0F1B2D",MUTE="7C8BA0",WHITE="FFFFFF";
const HF="Georgia",BF="Calibri";
const png=n=>path.join(ICO,n+".png");

function ft(s,n){s.addText("© Fikri Eren 2026",{x:0.5,y:7.08,w:5,h:0.3,fontFace:BF,fontSize:9,color:MUTE});
  s.addText(String(n).padStart(2,"0")+" / 16",{x:11.8,y:7.08,w:1.1,h:0.3,fontFace:BF,fontSize:9,color:MUTE,align:"right"});}
function circ(s,x,y,d,bg,icon){s.addShape(p.ShapeType.ellipse,{x,y,w:d,h:d,fill:{color:bg}});
  const ip=d*0.55; s.addImage({path:png(icon),x:x+(d-ip)/2,y:y+(d-ip)/2,w:ip,h:ip});}
function card(s,x,y,w,h,topColor){s.addShape(p.ShapeType.roundRect,{x,y,w,h,rectRadius:0.09,
  fill:{color:WHITE},line:{color:"E7EEF4",width:1},shadow:{type:"outer",blur:9,offset:3,angle:90,color:"06283D",opacity:0.12}});
  if(topColor)s.addShape(p.ShapeType.roundRect,{x,y,w,h:0.07,rectRadius:0.03,fill:{color:topColor},line:{color:topColor}});}
function kick(s,t,c){s.addText(t.toUpperCase(),{x:0.6,y:0.45,w:9,h:0.35,fontFace:BF,fontSize:11,bold:true,color:c||TEAL,charSpacing:2});}
function title(s,t){s.addText(t,{x:0.6,y:0.82,w:12,h:0.9,fontFace:HF,fontSize:30,bold:true,color:NAVY,valign:"top"});}
function dpad(s){s.background={color:NAVY};}

// 1 KAPAK
let s=p.addSlide(); dpad(s);
s.addText("EĞİTİM · CLAUDE-CONTEXT-TEMPLATE",{x:1,y:1.5,w:11,h:0.4,fontFace:BF,fontSize:13,bold:true,color:"5FD3C4",charSpacing:3});
s.addText("Claude'u Süper Güce\nDönüştürmek",{x:1,y:2.0,w:11.3,h:2,fontFace:HF,fontSize:46,bold:true,color:WHITE,valign:"top"});
s.addText("Ham model ne yapar · handikapları neydi · skill / agent / hook / kural katmanı ona hangi süper güçleri kattı.",
  {x:1,y:4.4,w:10.8,h:1,fontFace:BF,fontSize:16,color:"BFE0EA"});
["6 bölüm","~20 dk","Acemi → Plus"].forEach((t,i)=>{
  s.addShape(p.ShapeType.roundRect,{x:1+i*1.9,y:5.6,w:1.75,h:0.45,rectRadius:0.22,fill:{color:NAVY},line:{color:AQUA,width:1}});
  s.addText(t,{x:1+i*1.9,y:5.6,w:1.75,h:0.45,fontFace:BF,fontSize:11,color:"7FE9DC",align:"center",valign:"middle"});});
s.addText("© Fikri Eren 2026",{x:1,y:6.9,w:11,h:0.3,fontFace:BF,fontSize:10,color:"8FA6C4"});

// 2 GÜNDEM
s=p.addSlide(); kick(s,"Gündem"); title(s,"Yolculuk altı durakta");
const ag=[["cpu",TEAL,"Claude nedir?","Ne yapar, hangi ortamlar, neyi iyi yapar."],
["alert-triangle",RED,"Handikaplar","Ham haliyle 6 büyük zaaf."],
["zap",GREEN,"Süper güçler","Hafıza, hook, skill, agent, kural."],
["layers",AMBER,"Çözüm haritası","Hangi zaafı hangi yapı kapattı."],
["workflow",AQUA,"Önce / Sonra","Somut: günaydın deyince ne oluyor."],
["rocket",NAVY,"Sonuç","Akıl Claude'da değil, kurduğun yapıda."]];
ag.forEach((c,i)=>{const col=i%3,row=Math.floor(i/3),x=0.6+col*4.15,y=1.95+row*2.35;
  card(s,x,y,3.9,2.1); circ(s,x+0.25,y+0.25,0.62,c[1],c[0]);
  s.addText(c[2],{x:x+0.25,y:y+0.95,w:3.4,h:0.4,fontFace:BF,fontSize:14,bold:true,color:NAVY});
  s.addText(c[3],{x:x+0.25,y:y+1.35,w:3.45,h:0.6,fontFace:BF,fontSize:11,color:"37485C"});});
ft(s,2);

// 3 DIVIDER 01
s=p.addSlide(); dpad(s); s.addText("01",{x:8.5,y:-0.3,w:5,h:4,fontFace:HF,fontSize:200,bold:true,color:"0E3A50"});
s.addText("BÖLÜM 1",{x:1,y:2.4,w:8,h:0.4,fontFace:BF,fontSize:13,bold:true,color:AQUA,charSpacing:3});
s.addText("Claude nedir,\nne yapar?",{x:1,y:2.9,w:9,h:1.8,fontFace:HF,fontSize:40,bold:true,color:WHITE,valign:"top"});
s.addText("Temeli netleştirelim — sonra zaaflara geçeceğiz.",{x:1,y:4.7,w:9,h:0.5,fontFace:BF,fontSize:15,color:AQUA}); ft(s,3);

// 4 CLAUDE NEDIR
s=p.addSlide(); kick(s,"Bölüm 1 · Temel"); title(s,"İki yüzü var");
s.addText("Anthropic'in LLM'i. Kritik olan: kod ve dosyalarla çalışan asistana dönüşmesi.",{x:0.6,y:1.7,w:12,h:0.5,fontFace:BF,fontSize:14,color:"43586E"});
function bigcard(x,top,icon,ibg,h,b){card(s,x,2.3,5.9,2.3,top); circ(s,x+0.25,2.55,0.6,ibg,icon);
  s.addText(h,{x:x+0.25,y:3.25,w:5.3,h:0.4,fontFace:BF,fontSize:14,bold:true,color:NAVY});
  s.addText(b,{x:x+0.25,y:3.65,w:5.4,h:0.8,fontFace:BF,fontSize:11,color:"37485C"});}
bigcard(0.6,MUTE,"message-circle",MUTE,0,"Soru-cevap, yazım, analiz. Kod örneği üretir — ama projene doğrudan dokunamaz.");
bigcard(6.8,TEAL,"monitor",TEAL,0,"Dosyaları okur/yazar/çalıştırır · git commit · test koşar · her adımda onay ister.");
s.addText("Genel Claude (sohbet)",{x:0.85,y:3.25,w:5,h:0.4,fontFace:BF,fontSize:14,bold:true,color:NAVY,fontFace:BF});
s.addShape(p.ShapeType.roundRect,{x:0.6,y:4.8,w:12.1,h:1.2,rectRadius:0.09,fill:{color:NAVY}});
s.addText("“Chatbot değil — proje klasöründe oturan, yönlendirme bekleyen kıdemli bir yazılımcı.”",
  {x:0.9,y:4.8,w:11.5,h:1.2,fontFace:HF,fontSize:16,italic:true,color:"CFE6EE",valign:"middle"}); ft(s,4);

// 5 ORTAMLAR
s=p.addSlide(); kick(s,"Bölüm 1 · Temel"); title(s,"Nerede kullanılır?");
const orт=[["message-circle",GREEN,"Chat (claude.ai)","Düşünme, taslak, doküman. git/hook yok."],
["users",PURPLE,"Cowork","Ajan görevleri. Skill + MCP + plugin."],
["monitor",TEAL,"Desktop / Terminal","Tam güç: dosya + git + hook + agent."]];
orт.forEach((c,i)=>{const x=0.6+i*4.15;card(s,x,1.95,3.9,2.0,c[1]);circ(s,x+0.25,2.2,0.6,c[1],c[0]);
  s.addText(c[2],{x:x+0.25,y:2.9,w:3.4,h:0.4,fontFace:BF,fontSize:13.5,bold:true,color:NAVY});
  s.addText(c[3],{x:x+0.25,y:3.3,w:3.45,h:0.6,fontFace:BF,fontSize:10.5,color:"37485C"});});
s.addText("İyi yaptıkları: mekanik işi hızlı bitirir · geniş kod tabanını tarar · çok dosyalı düşünür · açıklar · tutarlı hız.",
  {x:0.6,y:4.25,w:12,h:0.6,fontFace:BF,fontSize:12.5,color:"43586E"});
card(s,0.6,5.0,12.1,1.0,AMBER); s.addText("Ama — kutudan çıktığı HAM haliyle ciddi handikapları var.",
  {x:0.9,y:5.0,w:11.5,h:1.0,fontFace:BF,fontSize:13,color:INK,valign:"middle"}); ft(s,5);

// 6 DIVIDER 02
s=p.addSlide(); dpad(s); s.addText("02",{x:8.5,y:-0.3,w:5,h:4,fontFace:HF,fontSize:200,bold:true,color:"4A1F25"});
s.addText("BÖLÜM 2 · PROBLEM",{x:1,y:2.4,w:8,h:0.4,fontFace:BF,fontSize:13,bold:true,color:"FF8B93",charSpacing:3});
s.addText("Ham Claude'un\nhandikapları",{x:1,y:2.9,w:9,h:1.8,fontFace:HF,fontSize:40,bold:true,color:WHITE,valign:"top"});
s.addText("Güçlü ama disiplinsiz.",{x:1,y:4.7,w:9,h:0.5,fontFace:BF,fontSize:15,color:"FFC9CD"}); ft(s,6);

// 7 STAT donut (native chart)
s=p.addSlide(); dpad(s);
s.addChart(p.ChartType.doughnut,[{name:"hafiza",labels:["kayıp"],values:[100]}],
  {x:0.7,y:1.7,w:4,h:4,holeSize:62,showLegend:false,showValue:false,
   chartColors:[RED],dataBorder:{pt:0,color:NAVY}});
s.addText("%100",{x:0.7,y:3.0,w:4,h:0.8,fontFace:HF,fontSize:40,bold:true,color:WHITE,align:"center"});
s.addText("hafıza kaybı",{x:0.7,y:3.8,w:4,h:0.4,fontFace:BF,fontSize:12,color:"9FC6D6",align:"center"});
s.addText("EN BÜYÜK ZAAF",{x:5.2,y:2.0,w:7,h:0.4,fontFace:BF,fontSize:12,bold:true,color:"FF8B93",charSpacing:2});
s.addText([{text:"Her yeni oturumda ",options:{}},{text:"tam hafıza kaybı",options:{color:"2EC4B6",bold:true}},
  {text:". Claude dünü, kararları, talimatları hatırlamaz — her sabah hafızası silinmiş bir stajyer.",options:{}}],
  {x:5.2,y:2.5,w:7.3,h:2,fontFace:BF,fontSize:17,color:"DFEAF0",valign:"top"});
s.addText("Sonuç: tekrar anlatım · tutarsızlık · 'bir gün unutursun → bug'.",{x:5.2,y:4.6,w:7.3,h:0.6,fontFace:BF,fontSize:13,color:"8FB0C0"}); ft(s,7);

// 8 6 HANDIKAP
s=p.addSlide(); kick(s,"Bölüm 2 · Problem",RED); title(s,"Altı handikap");
const hd=[["1 · Hafızasızlık","Her oturum sıfırdan. Dünü hatırlamaz."],
["2 · Tutarsızlık","Aynı işi her sefer farklı yapar."],["3 · Disiplinsizlik","Commit/test/plan'ı uygulamaz."],
["4 · Domain körlüğü","Senin işini bilmez; uydurabilir."],["5 · Riskli işlem","Dosya siler, sır sızdırır."],
["6 · Sahte 'bitti'","Çalıştırmadan 'tamam' der."]];
hd.forEach((c,i)=>{const col=i%3,row=Math.floor(i/3),x=0.6+col*4.15,y=1.95+row*2.3;
  card(s,x,y,3.9,2.0); s.addShape(p.ShapeType.roundRect,{x,y,w:0.08,h:2.0,fill:{color:RED},line:{color:RED}});
  s.addImage({path:png("alert-triangle"),x:x+0.25,y:y+0.25,w:0.32,h:0.32});
  s.addText(c[0],{x:x+0.7,y:y+0.22,w:3,h:0.4,fontFace:BF,fontSize:13,bold:true,color:NAVY});
  s.addText(c[1],{x:x+0.25,y:y+0.8,w:3.45,h:0.9,fontFace:BF,fontSize:11,color:"37485C"});});
ft(s,8);

// 9 DIVIDER 03
s=p.addSlide(); dpad(s); s.addText("03",{x:8.5,y:-0.3,w:5,h:4,fontFace:HF,fontSize:200,bold:true,color:"123F2E"});
s.addText("BÖLÜM 3 · ÇÖZÜM",{x:1,y:2.4,w:8,h:0.4,fontFace:BF,fontSize:13,bold:true,color:"7FE9B0",charSpacing:3});
s.addText("Bizim katman:\nsüper güçler",{x:1,y:2.9,w:9,h:1.8,fontFace:HF,fontSize:40,bold:true,color:WHITE,valign:"top"});
s.addText("Ham model + .claude/ kalıcı yapısı = her zaafa cevap.",{x:1,y:4.7,w:10,h:0.5,fontFace:BF,fontSize:15,color:"BFEAD2"}); ft(s,9);

// 10 MIMARI STACK
s=p.addSlide(); kick(s,"Bölüm 3 · Mimari"); title(s,"Beş bileşenli yapı");
const st=[["brain",GREEN,"Hafıza katmanı","CLAUDE.md + rules + journal + TODO"],
["cpu",TEAL,"Hook'lar","olay tetikli — unutsa bile mekanik çalışır"],
["package",PURPLE,"Skills","çok adımlı iş reçeteleri"],
["bot",AMBER,"Agent'lar","izole uzmanlar + model katmanı"],
["scroll-text",NAVY,"Kurallar","14 evrensel kalıcı davranış"]];
st.forEach((c,i)=>{const x=0.6+i*0.22,y=2.0+i*0.92,w=10.8-i*0.22;
  s.addShape(p.ShapeType.roundRect,{x,y,w,h:0.78,rectRadius:0.09,fill:{color:c[1]},
    shadow:{type:"outer",blur:8,offset:3,angle:90,color:"06283D",opacity:0.22}});
  s.addImage({path:png(c[0]),x:x+0.25,y:y+0.21,w:0.36,h:0.36});
  s.addText(c[2],{x:x+0.8,y:y,w:3,h:0.78,fontFace:BF,fontSize:13.5,bold:true,color:WHITE,valign:"middle"});
  s.addText(c[3],{x:x+3.7,y:y,w:w-3.9,h:0.78,fontFace:BF,fontSize:11,color:"FFFFFF",valign:"middle"});});
ft(s,10);

// 11 HOOK FLOW
s=p.addSlide(); kick(s,"Bölüm 3 · Nasıl çalışır"); title(s,"Hafıza dışsallaştırılır");
const fn=[["brain","Yeni oturum","boş başlar","FDECEE",RED],
["cpu","session-start hook","git+TODO+journal","EEF5F9",TEAL],
["circle-check","bağlam yüklü","'nerede kaldık'","E9F7EF",GREEN]];
fn.forEach((c,i)=>{const x=0.7+i*4.3;s.addShape(p.ShapeType.roundRect,{x,y:1.95,w:3.6,h:1.3,rectRadius:0.09,fill:{color:c[3]},line:{color:c[4],width:1}});
  s.addImage({path:png(c[0]),x:x+1.5,y:2.1,w:0.5,h:0.5});
  s.addText(c[1],{x,y:2.65,w:3.6,h:0.35,fontFace:BF,fontSize:12,bold:true,color:NAVY,align:"center"});
  s.addText(c[2],{x,y:2.98,w:3.6,h:0.3,fontFace:BF,fontSize:10,color:"5A6B80",align:"center"});
  if(i<2)s.addText("➜",{x:x+3.6,y:1.95,w:0.7,h:1.3,fontFace:BF,fontSize:24,color:AQUA,align:"center",valign:"middle"});});
const hk=[["terminal",TEAL,"session-start","Açılışta otomatik durum özeti."],
["shield-check",RED,"pre-commit","Şifre/riskli desen → bloklar."],
["book-open",GREEN,"post-commit","Her commit → günlüğe kayıt."]];
hk.forEach((c,i)=>{const x=0.6+i*4.15,y=3.7;card(s,x,y,3.9,1.7);circ(s,x+0.25,y+0.22,0.55,c[1],c[0]);
  s.addText(c[2],{x:x+0.95,y:y+0.28,w:2.8,h:0.4,fontFace:BF,fontSize:12.5,bold:true,color:NAVY});
  s.addText(c[3],{x:x+0.25,y:y+0.85,w:3.45,h:0.7,fontFace:BF,fontSize:10.5,color:"37485C"});});
ft(s,11);

// 12 DIVIDER 04
s=p.addSlide(); dpad(s); s.addText("04",{x:8.5,y:-0.3,w:5,h:4,fontFace:HF,fontSize:200,bold:true,color:"4A3418"});
s.addText("BÖLÜM 4 · HARİTA",{x:1,y:2.4,w:8,h:0.4,fontFace:BF,fontSize:13,bold:true,color:"FFD0A0",charSpacing:3});
s.addText("Handikap →\nnasıl güçlendirdik",{x:1,y:2.9,w:9.5,h:1.8,fontFace:HF,fontSize:40,bold:true,color:WHITE,valign:"top"}); ft(s,12);

// 13 HARITA TABLO
s=p.addSlide(); kick(s,"Bölüm 4 · Eşleme"); title(s,"Her zaaf bir yapı ile kapandı");
const hd2=(t)=>({text:t,options:{bold:true,color:WHITE,fill:NAVY,fontFace:BF}});
const rows=[[hd2("Ham zaaf"),hd2("Çözüm (yapı)"),hd2("Sonuç")],
["1 Hafızasızlık","3 katman hafıza + session-start hook","Her oturum dünü hatırlar"],
["2 Tutarsızlık","Kurallar + Skills (reçete)","Her sefer aynı doğru sonuç"],
["3 Disiplinsizlik","commit/plan/test kuralları + hook","Disiplin mekanik, atlanamaz"],
["4 Domain körlüğü","Proje-özel skill + kural + ADR","Senin işini bilir, uydurmaz"],
["5 Riskli işlem","pre-commit + before-major-change","Sır sızmaz, riskli işlem onaylı"],
["6 Sahte 'bitti'","verify + test-discipline + denetçi agent","Çalıştırmadan 'tamam' yok"]];
s.addTable(rows,{x:0.6,y:1.95,w:12.1,fontFace:BF,fontSize:12,border:{type:"solid",color:"E3EAF1",pt:1},rowH:0.6,valign:"middle",color:INK,fill:{color:WHITE}});
ft(s,13);

// 14 ONCE/SONRA + bar chart
s=p.addSlide(); kick(s,"Bölüm 5 · Somut"); title(s,"Tek kelime: günaydın");
card(s,0.6,1.95,5.9,1.9,RED);
s.addText("ÖNCE · HAM",{x:0.85,y:2.1,w:5,h:0.3,fontFace:BF,fontSize:11,bold:true,color:RED,charSpacing:1});
s.addText("Claude: 'Merhaba! Nasıl yardımcı olabilirim?'\n→ Dünü bilmez. Baştan anlatırsın.",{x:0.85,y:2.5,w:5.4,h:1.2,fontFace:BF,fontSize:12,color:INK});
card(s,6.8,1.95,5.9,1.9,GREEN);
s.addText("SONRA · YAPI KURULU",{x:7.05,y:2.1,w:5,h:0.3,fontFace:BF,fontSize:11,bold:true,color:"1E7A4D",charSpacing:1});
s.addText("Claude: 'Dün giriş bitti. Bugün şifre sıfırlama (Faz 0). 3 uncommitted. Başlayalım mı?'\n→ session-start + handoff okudu.",{x:7.05,y:2.5,w:5.4,h:1.3,fontFace:BF,fontSize:12,color:INK});
s.addChart(p.ChartType.bar,[{name:"dk",labels:["Önce","Sonra"],values:[10,0.3]}],
  {x:0.6,y:4.1,w:5.5,h:2.4,barDir:"bar",showLegend:false,showValue:true,chartColors:[RED,GREEN],
   catAxisLabelFontSize:12,valAxisHidden:true,dataLabelFontSize:11,dataLabelColor:INK});
s.addShape(p.ShapeType.roundRect,{x:6.5,y:4.5,w:6.2,h:1.6,rectRadius:0.09,fill:{color:NAVY}});
s.addText([{text:"\"günaydın\" sihirli değil. ",options:{color:"2EC4B6",bold:true}},
 {text:"Arkada git + TODO + günlük + özet — hepsi senin kurduğun yapı sayesinde.",options:{color:"CFE6EE"}}],
 {x:6.8,y:4.5,w:5.7,h:1.6,fontFace:BF,fontSize:13,valign:"middle"}); ft(s,14);

// 15 TETIK -> YAPI
s=p.addSlide(); kick(s,"Bölüm 5 · Somut"); title(s,"Söz → yapı → eylem");
const tr=[[hd2("Sen dersin"),hd2("Hangi yapı sayesinde"),hd2("Ne yapar")],
["günaydın","session-start hook + handoff","git/TODO/journal okur, özetler"],
["iyi geceler","session-handoff skill","günlüğe yazar, TODO işaretler, commit'ler"],
["dosyaları böl","commit-splitter agent","15+ dosyayı bucket'lara ayırır"],
["hangi seçenek?","llm-council skill","5 danışman + sentez"],
["(commit'te şifre)","pre-commit hook","sızıntıyı yakalar, bloklar"]];
s.addTable(tr,{x:0.6,y:1.95,w:12.1,fontFace:BF,fontSize:12.5,border:{type:"solid",color:"E3EAF1",pt:1},rowH:0.6,valign:"middle",color:INK,fill:{color:WHITE}});
s.addShape(p.ShapeType.roundRect,{x:0.6,y:5.6,w:12.1,h:0.9,rectRadius:0.09,fill:{color:"EAF7F5"},line:{color:AQUA,width:1}});
s.addText("Her kolaylık = bir tetik söz + senin kurduğun bir yapı. Yapıyı sil → kolaylık kaybolur.",
  {x:0.9,y:5.6,w:11.5,h:0.9,fontFace:HF,fontSize:14,italic:true,color:NAVY,valign:"middle"}); ft(s,15);

// 16 KAPANIS
s=p.addSlide(); dpad(s);
s.addText("BÖLÜM 6 · SONUÇ",{x:1,y:1.6,w:8,h:0.4,fontFace:BF,fontSize:13,bold:true,color:"5FD3C4",charSpacing:3});
s.addText([{text:"Akıl Claude'da değil —\n",options:{color:WHITE}},{text:"kurduğun yapıda.",options:{color:"2EC4B6"}}],
  {x:1,y:2.1,w:11.3,h:1.8,fontFace:HF,fontSize:44,bold:true,valign:"top"});
s.addText("Ham model güçlü ama disiplinsiz. Hafıza + hook + skill + agent + kural katmanı her handikabı süper güce çevirdi. Daha fazla kolaylık istersen: daha fazla yapı yaz.",
  {x:1,y:4.1,w:10.8,h:1.2,fontFace:BF,fontSize:16,color:"CFE6EE"});
s.addText("Kullan → Üret → Standartlaştır → Otomatikleştir",{x:1,y:5.4,w:11,h:0.5,fontFace:BF,fontSize:14,bold:true,color:"7FE9DC"});
s.addText("© Fikri Eren 2026",{x:1,y:6.9,w:11,h:0.3,fontFace:BF,fontSize:10,color:"7FB89C"});

p.writeFile({fileName:"Claude_Egitim_Sunumu_v3.pptx"}).then(f=>console.log("yazildi:",f));
