/**
 * GitHub Actions only. Pulls aggregate data with a secret API token, then
 * encrypts the snapshot before writing anything to the public repository.
 * Never print or persist the token or the plaintext data.
 */
import {pbkdf2Sync,hkdfSync,randomBytes,createCipheriv} from "node:crypto";
import {mkdir,writeFile,rename} from "node:fs/promises";
import {dirname} from "node:path";
import {collectMarket,buildReport} from "./ninja-report.mjs";

const TOKEN = process.env.GOATCOUNTER_TOKEN || "";
if (!TOKEN) throw Error("GOATCOUNTER_TOKEN secret missing");
const ORIGIN = "https://wiktor-portfolio.goatcounter.com";
const OUTPUT = "studio-insights-8f42c/data.enc.json";
const MASTER_SALT = "wiktor-portfolio-intelligence-master-v1";
const INFO = Buffer.from("wiktor-portfolio-stats-payload-2026");
const ITERATIONS = 220000;
const PERIODS = [7,30,90,365];
let previousRequest = 0;

function pause(ms){return new Promise(resolve=>setTimeout(resolve,ms))}
function number(value){const n=Number(value);return Number.isFinite(n)?Math.max(0,Math.round(n)):0}
async function get(path,params={}){
  const wait=Math.max(0,370-(Date.now()-previousRequest));
  if(wait)await pause(wait);
  previousRequest=Date.now();
  const url=new URL(ORIGIN+"/api/v0"+path);
  for(const [key,value] of Object.entries(params))url.searchParams.set(key,String(value));
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),20000);
  let response;
  try {
    response=await fetch(url,{headers:{"Authorization":"Bearer "+TOKEN,"Content-Type":"application/json","Accept":"application/json"},redirect:"error",signal:controller.signal});
  }catch{throw Error("GoatCounter network error at "+path)}finally{clearTimeout(timer)}
  if(!response.ok)throw Error("GoatCounter "+path+": HTTP "+response.status);
  const value=await response.json();
  if(!value||typeof value!=="object")throw Error("Unexpected GoatCounter response at "+path);
  return value;
}
function daySeries(raw,first,last){
  const m=new Map();
  for(const item of Array.isArray(raw)?raw:[]){
    const d=String(item?.day||"").slice(0,10);
    if(!/^\d{4}-\d{2}-\d{2}$/.test(d))continue;
    let count=number(item?.daily);
    if(!count&&Array.isArray(item.hourly))count=item.hourly.reduce((n,h)=>n+number(h),0);
    m.set(d,(m.get(d)||0)+count);
  }
  const series=[];
  const day=new Date(first.getTime());
  while(day.getTime()<=last.getTime()){
    const label=day.toISOString().slice(0,10);
    series.push({date:label,count:m.get(label)||0});
    day.setUTCDate(day.getUTCDate()+1);
  }
  return series;
}
function toList(raw,field="stats"){
  return (Array.isArray(raw?.[field])?raw[field]:[]).map(item=>({
    name:String(item?.name||"Nieznane").slice(0,130),count:number(item?.count)
  })).slice(0,100);
}
async function optionalStats(page,period){
  try{return toList(await get("/stats/"+page,{...period,limit:100}))}
  catch(error){console.log("Optional category unavailable:",page,String(error.message));return[]}
}
async function makePeriod(days,now){
  const utcDay = new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth(),now.getUTCDate()));
  const first = new Date(utcDay.getTime()-(days-1)*86400000);
  const prev = new Date(first.getTime()-days*86400000);
  const q={start:first.toISOString(),end:now.toISOString()};
  const old={start:prev.toISOString(),end:first.toISOString()};
  const pageResponse=await get("/stats/hits",{...q,limit:100});
  const previousResponse=await get("/stats/hits",{...old,limit:100});
  if(pageResponse.more||previousResponse.more)throw Error("Too many paths/events for a complete report");
  const records=Array.isArray(pageResponse.hits)?pageResponse.hits:[];
  const nonEvents=records.filter(p=>!p?.event);
  const pages=nonEvents.map(p=>({
    path:String(p?.path||"/").slice(0,150),
    title:String(p?.title||"").slice(0,150),
    count:number(p?.count)
  }));
  const events=records.filter(p=>p?.event && /^portfolio-(?:end|lang|video|case|contact)-/.test(String(p?.path||"")))
    .map(p=>({path:String(p.path).slice(0,150),title:String(p.title||"").slice(0,130),count:number(p.count)}));
  const previousPages=(Array.isArray(previousResponse.hits)?previousResponse.hits:[])
    .filter(p=>!p?.event);
  const toprefs=await optionalStats("toprefs",q);
  const browsers=await optionalStats("browsers",q);
  const locationResponse=await get("/stats/locations",{...q,limit:100});
  const locations=toList(locationResponse);
  // Query PL directly: an empty country summary must not hide API failures.
  let regions=[],regionHealth={api:"unknown"};
  try{
    const response=await get("/stats/locations/PL",{...q,limit:100});
    if(!Array.isArray(response.stats))throw Error("Invalid region response");
    regions=toList(response).filter(item=>item.count>0 && !/^(Poland|Polska|PL|\(unknown\)|unknown|nieznane)?$/i.test(item.name));
    regionHealth={api:"ok",hasNamedRegions:regions.length>0,complete:!response.more};
  }catch(error){
    regionHealth={api:"error"};
    console.log("Region API request failed:",String(error.message));
  }
  console.log("::notice title=PL region health::period="+days+"; api="+regionHealth.api+"; named_regions="+(regionHealth.hasNamedRegions??"unknown"));
  const systems=await optionalStats("systems",q);
  const sizes=await optionalStats("sizes",q);
  const campaigns=await optionalStats("campaigns",q);
  return {
    total:pages.reduce((n,p)=>n+p.count,0),
    previous:previousPages.reduce((n,p)=>n+number(p.count),0),
    daily:daySeries(nonEvents.flatMap(p=>Array.isArray(p.stats)?p.stats:[]),first,utcDay),
    pages,events,toprefs,browsers,locations,regions,regionHealth,systems,sizes,campaigns
  };
}
const now=new Date();
now.setUTCMinutes(0,0,0); // GoatCounter recommends hour-aligned query windows.
let plRegionCollection=null;
try{
  const response=await get("/sites");
  const site=(Array.isArray(response.sites)?response.sites:[])
    .find(item=>item?.code==="wiktor-portfolio");
  // GoatCounter serializes this field as "setttings" in current releases.
  const settings=site?.settings ?? site?.setttings;
  const rawRegions=settings?.collect_regions;
  const regions=Array.isArray(rawRegions)?rawRegions:typeof rawRegions==="string"?rawRegions.split(",").map(code=>code.trim()):null;
  const flags=settings?.collect;
  if(Array.isArray(regions) && Number.isInteger(flags))
    plRegionCollection=(flags & 16)!==0 && (flags & 32)!==0 && regions.some(code=>String(code).toUpperCase()==="PL");
}catch(error){
  console.log("::notice title=PL configuration read error::"+String(error.message));
}
console.log("::notice title=PL region configuration::"+(plRegionCollection===null?"unknown":plRegionCollection?"enabled":"disabled"));
const snapshot={schema:2,status:"ready",updated_at:now.toISOString(),
  note:"Aggregates only; values are GoatCounter counts, not verified unique individuals.",
  plRegionCollection,
  periods:{}};
for(const days of PERIODS){
  snapshot.periods[String(days)]=await makePeriod(days,now);
  console.log("Collected period",days,"days");
}
// Build a short report from the last completed 24-hour window. It is encrypted
// with the analytics snapshot; job boards receive no visitor information.
const market=await collectMarket(new Date());
let recent=null;
try{recent=await get("/stats/hits",{start:new Date(now.getTime()-86400000).toISOString(),end:now.toISOString(),limit:100});}
catch{console.log("::notice title=Ninja activity check::unavailable; previous analytics remain independent");}
snapshot.ninjaReport=buildReport(recent,market,now);
console.log("::notice title=Ninja report::status="+snapshot.ninjaReport.status+"; encrypted=true");
const master=pbkdf2Sync(TOKEN,MASTER_SALT,ITERATIONS,32,"sha256");
const salt=randomBytes(16),iv=randomBytes(12);
const aesKey=Buffer.from(hkdfSync("sha256",master,salt,INFO,32));
const cipher=createCipheriv("aes-256-gcm",aesKey,iv);
const clear=Buffer.from(JSON.stringify(snapshot));
const encrypted=Buffer.concat([cipher.update(clear),cipher.final(),cipher.getAuthTag()]);
const output=JSON.stringify({version:1,algorithm:"AES-256-GCM",updated_at:now.toISOString(),
  salt:salt.toString("base64"),iv:iv.toString("base64"),
  ciphertext:encrypted.toString("base64")});
await mkdir(dirname(OUTPUT),{recursive:true});
await writeFile(OUTPUT+".tmp",output+"\n",{mode:0o600});
await rename(OUTPUT+".tmp",OUTPUT);
console.log("Encrypted analytics snapshot ready. No plaintext persisted.");


