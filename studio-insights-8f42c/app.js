"use strict";
const $ = id => document.getElementById(id);
const number = new Intl.NumberFormat("pl-PL");
const dateFormat = new Intl.DateTimeFormat("pl-PL",{day:"numeric",month:"short",year:"numeric",timeZone:"UTC"});
const stampFormat = new Intl.DateTimeFormat("pl-PL",{dateStyle:"medium",timeStyle:"short",timeZone:"Europe/Warsaw"});
const regions = new Intl.DisplayNames(["pl"],{type:"region"});
let data = null, period = "7";
const SVG_NS = "http://www.w3.org/2000/svg";
const fmt = n => number.format(Math.max(0,Math.round(Number(n)||0)));
const integer = n => Math.max(0,Number(n)||0);
const dayName = d => dateFormat.format(new Date(d+"T12:00:00Z"));
const current = () => data?.periods?.[period] || null;
const s = (tag, attributes={}) => {const el=document.createElementNS(SVG_NS,tag);for(const [k,v] of Object.entries(attributes))el.setAttribute(k,String(v));return el};
const txt = (tag,className,value) => {const el=document.createElement(tag);if(className)el.className=className;el.textContent=String(value);return el};
function setStatus(message,warning=false){$("status").textContent=message;$("status").closest(".status-row").classList.toggle("error",warning);$("sync-mark").classList.toggle("warn",warning);$("sync-text").textContent=warning?"Wymaga uwagi":"Raport dostępny"}
function rank(target,items,labeler,limit=5){
 const box=$(target);box.replaceChildren();const rows=(Array.isArray(items)?items:[]).filter(x=>integer(x.count)>0).sort((a,b)=>b.count-a.count).slice(0,limit);
 if(!rows.length){box.append(txt("div","rank-empty","Brak danych dla wybranego okresu."));return}
 const sum=rows.reduce((n,x)=>n+integer(x.count),0);
 for(const entry of rows){
  const wrap=txt("div","rank",""),line=txt("div","rank-top",""),left=txt("span","rank-name",labeler(entry.name)),right=txt("span","rank-num",fmt(entry.count));
  const meter=txt("div","rank-meter",""),fill=txt("span","rank-fill","");
  fill.style.width=(sum?Math.min(100,integer(entry.count)/sum*100):0)+"%";
  line.append(left,right);meter.append(fill);wrap.append(line,meter);box.append(wrap);
 }
}
function country(code){
 const raw=String(code||"ZZ").toUpperCase();
 if(raw==="ZZ"||raw.length!==2||!/^[A-Z]{2}$/.test(raw))return "Nieznany kraj";
 try{const flag=String.fromCodePoint(...[...raw].map(c=>127397+c.charCodeAt(0)));return flag+"  "+regions.of(raw)}catch{return raw}
}
function source(name){const raw=String(name||"").trim();return !raw?"Bezpośrednie / nieznane":raw.slice(0,95)}
const VOIVODESHIPS=[
 ["02","Dolnośląskie"],["04","Kujawsko-pomorskie"],["06","Lubelskie"],["08","Lubuskie"],
 ["10","Łódzkie"],["12","Małopolskie"],["14","Mazowieckie"],["16","Opolskie"],
 ["18","Podkarpackie"],["20","Podlaskie"],["22","Pomorskie"],["24","Śląskie"],
 ["26","Świętokrzyskie"],["28","Warmińsko-mazurskie"],["30","Wielkopolskie"],["32","Zachodniopomorskie"]
];
function normalizeRegion(text){
 return String(text||"").toLocaleLowerCase("pl-PL").normalize("NFD").replace(/[\\u0300-\\u036f]/g,"")
   .replace(/^wojewodztwo\\s+/,"").replace(/[^a-z0-9]/g,"");
}
function regionCode(name){
 const raw=String(name||"").trim();
 const m=raw.match(/^(?:PL[-_ ])?([0-9]{2})$/i);
 if(m && VOIVODESHIPS.some(r=>r[0]===m[1]))return m[1];
 const normalized=normalizeRegion(raw);
 const alias={"lodz":"10","lodzkie":"10","mazovia":"14","masovia":"14","mazowieckie":"14",
 "silesia":"24","slaskie":"24","lesserpoland":"12","malopolskie":"12",
 "greaterpoland":"30","wielkopolskie":"30","lower silesian":"02"};
 if(alias[normalized])return alias[normalized];
 const hit=VOIVODESHIPS.find(item=>normalizeRegion(item[1])===normalized);
 return hit?hit[0]:null;
}
function showRegions(rows){
 const list=Array.isArray(rows)?rows.filter(x=>integer(x.count)>0):[];
 const matched=new Map(),other=[];
 for(const item of list){
  const code=regionCode(item.name);
  if(code)matched.set(code,(matched.get(code)||0)+integer(item.count));
  else other.push(item);
 }
 const total=Array.from(matched.values()).reduce((a,b)=>a+b,0);
 const max=Math.max(1,...matched.values());
 const summary=$("region-summary");
 summary.classList.toggle("empty",list.length===0);
 summary.textContent=list.length?
   "Dane regionalne w Polsce · "+fmt(list.reduce((n,r)=>n+integer(r.count),0))+" zarejestrowanych odsłon z przypisanym regionem.":
   "Brak podziału na województwa. W ustawieniach GoatCounter sprawdź zbieranie regionów dla kraju PL. Wcześniejszych lokalizacji nie da się odtworzyć.";
 const tiles=$("region-tiles");tiles.replaceChildren();
 for(const [code,name] of VOIVODESHIPS){
  const n=matched.get(code)||0,card=txt("div","region-tile"+(matched.has(code)?"":" unknown"),"");
  if(matched.has(code))card.style.backgroundColor="rgba(198,246,106,"+(0.07+0.24*n/max).toFixed(3)+")";
  card.append(txt("span","region-label",name),txt("strong","region-value",matched.has(code)?fmt(n):"—"));
  card.title=matched.has(code)?name+" · "+fmt(n)+" odsłon":name+" · brak danych";tiles.append(card);
 }
 const ranked=Array.from(matched,([code,count])=>({name:VOIVODESHIPS.find(x=>x[0]===code)?.[1]||code,count}));
 ranked.push(...other);
 rank("region-list",ranked,x=>String(x),6);
}
function pages(rows,total){
 const body=$("page-rows");body.replaceChildren();const items=(rows||[]).filter(x=>integer(x.count)>0).sort((a,b)=>b.count-a.count).slice(0,8);
 $("page-count").textContent=items.length+" STRON";
 if(!items.length){const tr=document.createElement("tr"),td=txt("td","table-empty","Brak danych dla wybranego okresu.");td.colSpan=4;tr.append(td);body.append(tr);return}
 items.forEach((item,i)=>{
  const tr=document.createElement("tr");
  const idx=txt("td","",String(i+1).padStart(2,"0")),name=document.createElement("td"),path=txt("span","page-path",item.path||"/"),title=txt("span","page-title",item.title||"Portfolio"),visits=txt("td","",fmt(item.count)),pct=txt("td","",(total?100*integer(item.count)/total:0).toFixed(1)+"%");
  name.append(path,title);tr.append(idx,name,visits,pct);body.append(tr);
 });
}
function language(rows){
 let pl=0,en=0;
 for(const item of rows||[]){
  const path=String(item.path||"").toLowerCase().split("?")[0].replace(/\/$/,"/");
  if(path.endsWith("/en.html")||path==="/en.html")en+=integer(item.count);
  else if(path.endsWith("/index.html")||path==="/portfolio/"||path==="/"||path==="/portfolio")pl+=integer(item.count);
 }
 const all=pl+en,share=all?100*en/all:0,plShare=all?100*pl/all:0;
 $("kpi-en").textContent=all?Math.round(share)+"%":"—";
 $("kpi-en-description").textContent=all?fmt(en)+" odsłon EN z "+fmt(all)+" rozpoznanych":"Brak podziału na wersje";
 $("en-value").textContent=all?plShare===0?"100%":share.toFixed(1)+"%":"—";
 $("pl-value").textContent=all?plShare.toFixed(1)+"%":"—";
 $("donut-value").textContent=all?Math.round(share)+"% EN":"—";
 $("donut").style.background=all?`conic-gradient(var(--green) 0% ${plShare}%,var(--violet) ${plShare}% 100%)`:"conic-gradient(#3a4340 0% 100%)";
}
function chart(rows){
 const box=$("chart");box.replaceChildren();
 const values=(rows||[]).map(x=>({date:String(x.date||""),count:integer(x.count)}));
 if(!values.length){box.append(txt("div","empty-state","Brak danych do wyświetlenia wykresu."));return}
 const width=1000,height=265,left=45,right=12,top=14,bottom=232,max=Math.max(1,...values.map(x=>x.count));
 const svg=s("svg",{viewBox:`0 0 ${width} ${height}`,preserveAspectRatio:"none",role:"img","aria-label":"Wykres dziennych odsłon w wybranym okresie"});
 const defs=s("defs"),linear=s("linearGradient",{id:"traffic-gradient",x1:"0",x2:"0",y1:"0",y2:"1"});linear.append(s("stop",{offset:"0%","stop-color":"#c6f66a","stop-opacity":".24"}),s("stop",{offset:"100%","stop-color":"#c6f66a","stop-opacity":"0"}));defs.append(linear);svg.append(defs);
 const x=i=>left+(values.length<2?.5:i/(values.length-1))*(width-left-right),y=v=>bottom-(v/max)*(bottom-top);
 for(let i=0;i<5;i++){
  const h=top+(bottom-top)*i/4;
  svg.append(s("line",{x1:left,y1:h,x2:width-right,y2:h,class:"gridline"}));
  const t=s("text",{x:35,y:h+4,"text-anchor":"end",class:"axis"});t.textContent=fmt(max*(4-i)/4);svg.append(t);
 }
 const plotted=values.map((r,i)=>[x(i),y(r.count)]);
 const line=plotted.map((p,i)=>(i?"L":"M")+p[0].toFixed(2)+","+p[1].toFixed(2)).join(" ");
 const area=s("path",{d:line+" L "+plotted[plotted.length-1][0]+","+bottom+" L "+plotted[0][0]+","+bottom+" Z",fill:"url(#traffic-gradient)"});
 const stroke=s("path",{d:line,class:"trend"});
 svg.append(area,stroke);
 const step=values.length>90?30:values.length>30?10:values.length>12?4:1;
 const marks=[0,Math.floor((values.length-1)/2),values.length-1];
 for(const i of [...new Set(marks)]){
  const el=s("text",{x:x(i),y:260,"text-anchor":i===0?"start":i===values.length-1?"end":"middle",class:"axis"});el.textContent=values[i].date.slice(5);svg.append(el);
 }
 const cross=s("line",{x1:left,x2:left,y1:top,y2:bottom,class:"focus-line",visibility:"hidden"});
 const dot=s("circle",{cx:left,cy:bottom,r:5,fill:"#c6f66a",stroke:"#172319","stroke-width":3,visibility:"hidden"});svg.append(cross,dot);
 const tooltip=$("tooltip");
 function show(i){
  const row=values[i];cross.setAttribute("x1",x(i));cross.setAttribute("x2",x(i));cross.setAttribute("visibility","visible");dot.setAttribute("cx",x(i));dot.setAttribute("cy",y(row.count));dot.setAttribute("visibility","visible");
  tooltip.textContent=dayName(row.date)+"  ·  "+fmt(row.count)+" odsłon";tooltip.hidden=false;
  const r=box.getBoundingClientRect(),p=x(i)/width;tooltip.style.left=Math.max(70,Math.min(window.innerWidth-70,r.left+p*r.width))+"px";tooltip.style.top=Math.max(50,r.top+(y(row.count)/height)*r.height)+"px";
 }
 function hide(){cross.setAttribute("visibility","hidden");dot.setAttribute("visibility","hidden");tooltip.hidden=true}
 const hit=s("rect",{x:left,y:top,width:width-left-right,height:bottom-top,fill:"transparent",style:"cursor:crosshair"});
 hit.addEventListener("pointermove",e=>{const r=box.getBoundingClientRect();const relative=(e.clientX-r.left)/r.width;const index=Math.max(0,Math.min(values.length-1,Math.round((relative*width-left)/(width-left-right)*(values.length-1))));show(index)});
 hit.addEventListener("pointerleave",hide);hit.addEventListener("pointercancel",hide);svg.append(hit);
 box.append(svg);
 $("chart-period").textContent=period==="365"?"12M":period+"D";
 const peak=values.reduce((best,row)=>row.count>best.count?row:best,values[0]);
 $("kpi-best").textContent=values.some(v=>v.count>0)?fmt(peak.count):"0";
 $("kpi-best-date").textContent=values.some(v=>v.count>0)?dayName(peak.date):"Brak zarejestrowanych odsłon";
 $("chart-summary").textContent=values.length+" punktów dziennych · ostatni dzień może być niepełny";
}
function draw(){
 const r=current();if(!r)return;
 const total=integer(r.total),old=integer(r.previous),days=Number(period);
 $("kpi-views").textContent=fmt(total);
 $("kpi-average").textContent=(total/days).toLocaleString("pl-PL",{maximumFractionDigits:1});
 const delta=$("kpi-change");delta.classList.remove("negative","neutral");
 if(!old){delta.textContent=total?"NOWY RUCH":"0%";delta.classList.add("neutral")}
 else{const change=(total-old)/old*100;delta.textContent=(change>0?"+":"")+change.toFixed(1)+"%";if(change<0)delta.classList.add("negative")}
 chart(r.daily);rank("referrers",r.toprefs,source);
 rank("countries",r.locations,country);rank("browsers",r.browsers,x=>String(x));
 showRegions(r.regions);rank("systems",r.systems,x=>String(x));
 rank("campaigns",r.campaigns,x=>String(x),6);
 language(r.pages);pages(r.pages,total);
}
async function refresh(){
 const btn=$("refresh");btn.disabled=true;
 try{
  const json=await window.GoatData.load(period);
  if(json.status!=="ready"||json.schema!==2||!json.periods){throw Error("setup")}
  data=json;draw();
  const time=Date.parse(json.updated_at),stale=!Number.isFinite(time)||Date.now()-time>6*3600000;
  setStatus(stale?"Raport jest starszy niż 6 godzin. Wyniki mogą być nieaktualne.":"Statystyki pobrane pomyślnie.",stale);
  $("timestamp").textContent="Ostatnia synchronizacja: "+stampFormat.format(new Date(json.updated_at));
 }catch(err){
  const setup=String(err.message)==="setup";
  setStatus(setup?"Połącz token GoatCounter, aby wyświetlić statystyki.":String(err.message||"Nie udało się pobrać danych.")+" Nie oznacza to zera odwiedzin.",true);
  $("timestamp").textContent="Dane rzeczywiste, bez wartości demonstracyjnych";
 }finally{btn.disabled=false}
}
document.querySelectorAll("[data-period]").forEach(button=>button.addEventListener("click",()=>{
 period=button.dataset.period;
 document.querySelectorAll("[data-period]").forEach(x=>{const active=x===button;x.classList.toggle("active",active);x.setAttribute("aria-pressed",String(active))});
 refresh();
}));
$("refresh").addEventListener("click",()=>{window.GoatData.invalidate(period);refresh()});
document.querySelectorAll(".nav-item").forEach(link=>link.addEventListener("click",()=>{
 document.querySelectorAll(".nav-item").forEach(x=>x.classList.toggle("active",x===link));
}));
refresh();
