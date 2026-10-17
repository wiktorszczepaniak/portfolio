"use strict";
(() => {
  const ORIGIN = "https://wiktor-portfolio.goatcounter.com";
  const KEY = "portfolio_intelligence_readonly_token_v1";
  let token = localStorage.getItem(KEY) || sessionStorage.getItem(KEY) || "";
  const cache = new Map();
  let pendingResolve = null, lastRequest = 0;
  const $ = id => document.getElementById(id);
  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
  const integer = x => {const n=Number(x);return Number.isFinite(n)?Math.max(0,Math.round(n)):0};
  const params = dates => new URLSearchParams(dates).toString();

  async function call(path, options={}, overrideToken) {
    const t = overrideToken || token;
    const delay = Math.max(0, 520 - (Date.now() - lastRequest));
    if (delay) await sleep(delay);
    lastRequest = Date.now();
    let url = ORIGIN + "/api/v0" + path;
    if (options.params) url += "?" + params(options.params);
    let result;
    try {
      result = await fetch(url, {
        method:"GET", mode:"cors", cache:"no-store",
        headers:{"Authorization":"Bearer "+t,"Accept":"application/json","Content-Type":"application/json"}
      });
    } catch(e) {
      throw Error("Brak połączenia z GoatCounter. Sprawdź adres witryny lub blokadę przeglądarki.");
    }
    if (result.status === 401 || result.status === 403) {
      if (!overrideToken) {
        token = "";localStorage.removeItem(KEY);sessionStorage.removeItem(KEY);
      }
      throw Error("Token jest nieprawidłowy albo nie ma uprawnienia Read statistics.");
    }
    if (!result.ok) throw Error("GoatCounter API: HTTP "+result.status+". Sprawdź, czy witryna jest aktywna.");
    const json = await result.json();
    if (!json || typeof json!=="object")throw Error("Nieprawidłowa odpowiedź GoatCounter.");
    return json;
  }

  function modal(message="") {
    $("connect-overlay").hidden=false;
    $("connect-error").hidden=!message;
    $("connect-error").textContent=message;
    $("goat-token").value="";
    $("goat-token").focus();
    return new Promise(resolve=>{pendingResolve=resolve});
  }
  async function ensureToken() {
    if (token) return;
    await modal();
  }

  $("connect-form").addEventListener("submit",async event=>{
    event.preventDefault();
    const candidate=$("goat-token").value.trim(),button=$("connect-button");
    if (!candidate) return;
    button.disabled=true;button.textContent="Sprawdzam połączenie...";
    $("connect-error").hidden=true;
    try {
      await call("/me",{},candidate);
      token=candidate;
      if ($("remember-key").checked) {
        localStorage.setItem(KEY,candidate);sessionStorage.removeItem(KEY);
      } else {
        sessionStorage.setItem(KEY,candidate);localStorage.removeItem(KEY);
      }
      $("connect-overlay").hidden=true;$("goat-token").value="";
      cache.clear();
      if(pendingResolve){const done=pendingResolve;pendingResolve=null;done()}
      else document.getElementById("refresh").click();
    } catch(err) {
      $("connect-error").hidden=false;
      $("connect-error").textContent=String(err.message||"Nie udało się połączyć.");
    } finally {button.disabled=false;button.textContent="Połącz i pokaż dashboard ↗"}
  });

  $("manage-key").addEventListener("click",()=>{modal().then(()=>document.getElementById("refresh").click())});

  function dateRange(days) {
    const end=new Date(),round=new Date(Date.UTC(end.getUTCFullYear(),end.getUTCMonth(),end.getUTCDate(),end.getUTCHours()));
    const start=new Date(round.getTime()-days*86400000);
    const previous=new Date(start.getTime()-days*86400000);
    const format=d=>d.toISOString();
    return {now:round,start,previous,p:{start:format(start),end:format(round)},before:{start:format(previous),end:format(start)}};
  }
  function series(items,start,end) {
    const map=new Map();
    for (const item of Array.isArray(items)?items:[]) {
      const day=String(item?.day||"").slice(0,10);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(day))continue;
      let n=integer(item.daily);
      if(!n && Array.isArray(item.hourly))n=item.hourly.reduce((s,x)=>s+integer(x),0);
      map.set(day,(map.get(day)||0)+n);
    }
    const result=[];
    const d=new Date(Date.UTC(start.getUTCFullYear(),start.getUTCMonth(),start.getUTCDate()));
    const last=new Date(Date.UTC(end.getUTCFullYear(),end.getUTCMonth(),end.getUTCDate()));
    while(d<=last) {
      const day=d.toISOString().slice(0,10);result.push({date:day,count:map.get(day)||0});d.setUTCDate(d.getUTCDate()+1);
    }
    return result;
  }
  function cleanStats(raw) {
    return (Array.isArray(raw)?raw:[]).map(item=>({
      name:String(item?.name||"Nieznane").slice(0,120),
      count:integer(item?.count)
    }));
  }
  async function build(days) {
    const dates=dateRange(days);
    const total=await call("/stats/total",{params:dates.p});
    const previous=await call("/stats/total",{params:dates.before});
    const hits=await call("/stats/hits",{params:{...dates.p,limit:100}});
    const toprefs=await call("/stats/toprefs",{params:{...dates.p,limit:100}});
    const browsers=await call("/stats/browsers",{params:{...dates.p,limit:100}});
    const locations=await call("/stats/locations",{params:{...dates.p,limit:100}});
    const pages=(Array.isArray(hits.hits)?hits.hits:[]).filter(p=>!p.event).map(p=>({
      path:String(p.path||"/").slice(0,120),title:String(p.title||"").slice(0,120),count:integer(p.count)
    }));
    const record={
      total:integer(total.total),previous:integer(previous.total),
      daily:series(total.stats,dates.start,dates.now),
      pages,toprefs:cleanStats(toprefs.stats),browsers:cleanStats(browsers.stats),locations:cleanStats(locations.stats)
    };
    return {schema:2,status:"ready",updated_at:new Date().toISOString(),periods:{[String(days)]:record}};
  }
  window.GoatData={
    async load(days) {
      await ensureToken();
      const key=String(days);
      const cached=cache.get(key);
      if (cached&&Date.now()-cached.when<60000)return cached.value;
      try {
        const value=await build(Number(days));
        cache.set(key,{when:Date.now(),value});
        return value;
      } catch(err) {
        if(!token) {
          await modal(String(err.message));
          return this.load(days);
        }
        throw err;
      }
    },
    invalidate(days){cache.delete(String(days))}
  };
})();
