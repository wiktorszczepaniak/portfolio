"use strict";
/* Three verified, fixed-for-the-day job missions. Progress is stored ONLY locally. */
(() => {
  const STORAGE_KEY = "ws_ninja_daily_quests_v1";
  const XP_PER_APPLICATION = 3;
  const MAX_MISSION_XP_PER_PERIOD = 18;
  const format = new Intl.DateTimeFormat("pl-PL", {day:"numeric",month:"long",year:"numeric",timeZone:"Europe/Warsaw"});
  const dayFormat = new Intl.DateTimeFormat("en-GB",{year:"numeric",month:"2-digit",day:"2-digit",timeZone:"Europe/Warsaw"});
  let state = {days:{}};
  let persistence = true;
  function dayKey(date = new Date()) {
    const parts=Object.fromEntries(dayFormat.formatToParts(date).filter(p=>p.type!=="literal").map(p=>[p.type,p.value]));
    return parts.year+"-"+parts.month+"-"+parts.day;
  }
  function safeJob(job) {
    try {
      const url=new URL(job.url);
      if(url.protocol!=="https:"||url.hostname!=="rocketjobs.pl"||!url.pathname.startsWith("/oferta-pracy/"))return null;
      if(job.validThrough && Date.parse(job.validThrough) <= Date.now())return null;
      const title=String(job.title||"").trim().slice(0,145),company=String(job.company||"").trim().slice(0,100);
      if(!title||!company)return null;
      return {url:url.href,title,company,location:String(job.location||"Sprawdź szczegóły").slice(0,95),validThrough:job.validThrough||null};
    }catch{return null;}
  }
  function read() {
    try {
      const raw=JSON.parse(localStorage.getItem(STORAGE_KEY)||"{}");
      if(raw&&raw.days&&typeof raw.days==="object")state={days:raw.days};
    }catch {persistence=false;}
  }
  function save() {
    const cutoff=Date.now()-400*86400000;
    for(const date of Object.keys(state.days)){
      if(!/^\d{4}-\d{2}-\d{2}$/.test(date)||Date.parse(date+"T00:00:00Z")<cutoff)delete state.days[date];
    }
    try{localStorage.setItem(STORAGE_KEY,JSON.stringify(state));}
    catch{persistence=false;}
  }
  function todaysRecord(market){
    const date=dayKey();
    const existing=state.days[date];
    // Never turn yesterday's or unverified job leads into today's assignments.
    const isFresh=market?.status==="ready"&&market?.checkedAt
      &&Number.isFinite(Date.parse(market.checkedAt))&&dayKey(new Date(market.checkedAt))===date;
    const fresh=isFresh?(Array.isArray(market.jobs)?market.jobs:[])
      .map(safeJob).filter(Boolean).filter((j,i,a)=>a.findIndex(x=>x.url===j.url)===i).slice(0,3):[];
    if(existing && Array.isArray(existing.jobs) && existing.jobs.length){
      // The first report of the day may have fewer than three offers.
      // Add missing verified offers later without changing finished missions.
      if(existing.jobs.length<3 && fresh.length){
        const known=new Set(existing.jobs.map(job=>job.url));
        for(const job of fresh){
          if(existing.jobs.length>=3)break;
          if(!known.has(job.url)){existing.jobs.push(job);known.add(job.url);}
        }
        save();
      }
      return {date,record:existing};
    }
    if(!fresh.length)return {date,record:null};
    const record={jobs:fresh,done:[],savedAt:new Date().toISOString()};
    state.days[date]=record;save();
    return {date,record};
  }
  function earnedXp() {
    let total=0;
    for(const record of Object.values(state.days)){
      if(!Array.isArray(record?.jobs)||!Array.isArray(record?.done))continue;
      const urls=new Set(record.jobs.map(job=>job.url));
      total+=new Set(record.done.filter(url=>urls.has(url))).size*XP_PER_APPLICATION;
    }
    return total;
  }
  function getXp(period) {
    const days=Number(period);
    if(![7,30,90,365].includes(days))return 0;
    const today=dayKey();
    const first=new Date(today+"T00:00:00Z");
    first.setUTCDate(first.getUTCDate()-days+1);
    const cutoff=first.toISOString().slice(0,10);
    let completed=0;
    for(const [day,record] of Object.entries(state.days)){
      if(day<cutoff||day>today||!Array.isArray(record?.jobs)||!Array.isArray(record?.done))continue;
      const urls=new Set(record.jobs.map(job=>job.url));
      const unique=new Set(record.done.filter(url=>urls.has(url)));
      completed+=unique.size;
    }
    return Math.min(MAX_MISSION_XP_PER_PERIOD,completed*XP_PER_APPLICATION);
  }
  function draw(market){
    const root=document.getElementById("daily-quests-list");
    if(!root)return;
    root.replaceChildren();
    const {date,record}=todaysRecord(market);
    const title=document.getElementById("daily-quests-date");
    const progress=document.getElementById("daily-quests-progress");
    const hint=document.getElementById("daily-quests-hint");
    title.textContent=format.format(new Date())+" · +"+XP_PER_APPLICATION+" EXP za aplikację";
    hint.textContent=persistence
      ?"Zebrane EXP z aplikacji: "+earnedXp()+". Do rankingu w wybranym okresie liczy się maks. "+MAX_MISSION_XP_PER_PERIOD+" EXP z misji. Postęp zapisany tylko tutaj."
      :"Przeglądarka blokuje zapis. Zaznaczenia mogą zniknąć po odświeżeniu.";
    if(!record){
      progress.textContent="0 / 3";
      const message=document.createElement("p");
      message.className="quest-empty";
      message.textContent=market?.status==="unavailable"
        ?"Nie udało się dziś potwierdzić ofert. Niczego nie podstawiam na chybił trafił."
        :"Czekam na trzy aktualne oferty z dzisiejszego sprawdzenia RocketJobs. Zajrzyj po kolejnej synchronizacji.";
      root.append(message);
      return;
    }
    const done=new Set(Array.isArray(record.done)?record.done:[]);
    progress.textContent=record.jobs.filter(job=>done.has(job.url)).length+" / "+record.jobs.length;
    for(const [i,job] of record.jobs.entries()){
      const card=document.createElement("article");card.className="daily-quest"+(done.has(job.url)?" completed":"");
      const ordinal=document.createElement("span");ordinal.className="daily-quest-number";ordinal.textContent="MISJA "+String(i+1).padStart(2,"0");
      const heading=document.createElement("strong");heading.textContent=job.title;
      const sub=document.createElement("span");sub.className="daily-quest-meta";sub.textContent=job.company+" · "+job.location;
      const offer=document.createElement("a");offer.className="daily-quest-open";offer.textContent="Zobacz ofertę ↗";offer.href=job.url;offer.rel="noopener noreferrer";offer.target="_blank";
      const label=document.createElement("label");label.className="daily-quest-toggle";
      const box=document.createElement("input");box.type="checkbox";box.checked=done.has(job.url);
      box.setAttribute("aria-label","Wysłałem aplikację: "+job.title+" · "+job.company);
      const indicator=document.createElement("span");indicator.textContent=box.checked?"Zaliczone":"Aplikowałem";
      const xp=document.createElement("b");xp.textContent="+"+XP_PER_APPLICATION+" EXP";
      label.append(box,indicator,xp);
      box.addEventListener("change",()=>{
        const selected=new Set(record.done||[]);
        if(box.checked)selected.add(job.url);else selected.delete(job.url);
        record.done=[...selected];save();draw(market);
        document.dispatchEvent(new Event("daily-quest-change"));
      });
      card.append(ordinal,heading,sub,offer,label);
      root.append(card);
    }
    if(record.jobs.length<3){
      const notice=document.createElement("p");
      notice.className="quest-empty";
      notice.textContent="Dzisiaj udało się zweryfikować tylko "+record.jobs.length+" oferty. Brakujących nie wymyślam.";
      root.append(notice);
    }
  }
  read();
  window.DailyQuests={render:draw,getXp,earnedXp,dayKey};
})();
