// Privacy-conscious source diagnostics. No raw logs, visitor IDs, IPs or token values.
const token=process.env.GOATCOUNTER_TOKEN;
if(!token)throw Error("Missing GOATCOUNTER_TOKEN secret");
const base="https://wiktor-portfolio.goatcounter.com/api/v0";
let requestAt=0;
async function read(path,params={}){
 const remaining=Math.max(0,370-(Date.now()-requestAt));
 if(remaining)await new Promise(r=>setTimeout(r,remaining));
 requestAt=Date.now();
 const u=new URL(base+path);
 for(const [key,value] of Object.entries(params))u.searchParams.set(key,String(value));
 const res=await fetch(u,{headers:{Authorization:"Bearer "+token,"Content-Type":"application/json",Accept:"application/json"},signal:AbortSignal.timeout(20000)});
 if(!res.ok)throw Error(path+" HTTP "+res.status);
 return res.json();
}
const now=new Date();now.setUTCMinutes(0,0,0);
const range=h=>({start:new Date(now.getTime()-h*3600000).toISOString(),end:now.toISOString(),limit:100});
const sites=await read("/sites");
const site=sites.sites?.find(s=>s.code==="wiktor-portfolio");
console.log("DIAGNOSTIC sourceSiteFound="+Boolean(site)+" receivedDataEver="+Boolean(site?.received_data));
for(const hours of [3,6,24,168]){
 const q=range(hours);
 const hits=await read("/stats/hits",q);
 const total=await read("/stats/total",q);
 const all=Array.isArray(hits.hits)?hits.hits:[];
 const pages=all.filter(h=>!h.event);
 const pl=pages.filter(h=>["/portfolio/","/portfolio/index.html"].includes(h.path));
 const en=pages.filter(h=>h.path==="/portfolio/en.html");
 const pageViews=pages.reduce((n,x)=>n+(Number(x.count)||0),0);
 const totalViews=Math.max(0,(Number(total.total)||0)-(Number(total.total_events)||0));
 console.log("DIAGNOSTIC "+hours+"h hasViews="+(totalViews>0)+" hasPL="+pl.some(x=>Number(x.count)>0)+" hasEN="+en.some(x=>Number(x.count)>0)+" pathViewsPositive="+(pageViews>0)+" totalMatchesPaths="+(pageViews===totalViews)+" anyEvents="+all.some(x=>x.event)+" pathsMore="+Boolean(hits.more)+" pathCount="+pages.length);
}
