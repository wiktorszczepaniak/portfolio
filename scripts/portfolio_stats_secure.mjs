/**
 * GitHub Actions only. Pulls aggregate data with a secret API token, then
 * encrypts the snapshot before writing anything to the public repository.
 * Never print or persist the token or the plaintext data.
 */
import {pbkdf2Sync,hkdfSync,randomBytes,createCipheriv} from "node:crypto";
import {mkdir,writeFile,rename} from "node:fs/promises";
import {dirname} from "node:path";

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
  const a=await get("/stats/total",q),b=await get("/stats/total",old);
  const pageResponse=await get("/stats/hits",{...q,limit:100});
  const pages=(Array.isArray(pageResponse.hits)?pageResponse.hits:[])
    .filter(p=>!p?.event)
    .map(p=>({path:String(p?.path||"/").slice(0,150),title:String(p?.title||"").slice(0,150),count:number(p?.count)}));
  const toprefs=await optionalStats("toprefs",q);
  const browsers=await optionalStats("browsers",q);
  const locationResponse=await get("/stats/locations",{...q,limit:100});
  const locations=toList(locationResponse);
  const regions=await (async()=>{
    // A country must first appear in the summary for its region breakdown to exist.
    const poland=(Array.isArray(locationResponse.stats)?locationResponse.stats:[])
      .find(item=>String(item?.id||"").toUpperCase()==="PL" || /^(Poland|Polska)$/i.test(String(item?.name||"")));
    if(!poland)return [];
    const countryId=String(poland.id||"PL");
    if(!/^[a-zA-Z0-9_-]{1,24}$/.test(countryId))return [];
    try{
      const subregions=await get("/stats/locations/"+encodeURIComponent(countryId),{...q,limit:100});
      return toList(subregions).filter(item=>item.count>0 && !/^(Poland|Polska|PL)$/i.test(item.name));
    }catch(error){
      console.log("Region breakdown unavailable for PL:",String(error.message));
      return [];
    }
  })();
  const systems=await optionalStats("systems",q);
  const sizes=await optionalStats("sizes",q);
  const campaigns=await optionalStats("campaigns",q);
  return {
    total:Math.max(0,number(a.total)-number(a.total_events)),
    previous:Math.max(0,number(b.total)-number(b.total_events)),
    daily:daySeries(a.stats,first,utcDay),
    pages,toprefs,browsers,locations,regions,systems,sizes,campaigns
  };
}
const now=new Date();
now.setUTCMinutes(0,0,0); // GoatCounter recommends hour-aligned query windows.
let plRegionCollection=null;
try{
  const response=await get("/sites");
  const site=(Array.isArray(response.sites)?response.sites:[])
    .find(item=>item?.code==="wiktor-portfolio");
  const regions=site?.settings?.collect_regions;
  if(Array.isArray(regions))plRegionCollection=regions.some(code=>String(code).toUpperCase()==="PL");
}catch(error){
  console.log("Region collection configuration could not be verified:",String(error.message));
}
console.log("Regional data collection for PL:",plRegionCollection===null?"unknown":plRegionCollection?"enabled":"disabled");
const snapshot={schema:2,status:"ready",updated_at:now.toISOString(),
  note:"Aggregates only; values are GoatCounter counts, not verified unique individuals.",
  plRegionCollection,
  periods:{}};
for(const days of PERIODS){
  snapshot.periods[String(days)]=await makePeriod(days,now);
  console.log("Collected period",days,"days");
}
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
