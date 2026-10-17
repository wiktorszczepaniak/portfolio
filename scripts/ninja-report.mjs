/** Public job pages only. No analytics or API credential is sent to job boards. */
export const marketSources = [
  'https://rocketjobs.pl/oferty-pracy/wszystkie-lokalizacje/marketing/social-media',
  'https://rocketjobs.pl/oferty-pracy/wszystkie-lokalizacje/marketing/content-copywriting'
];
const num=v=>Number.isFinite(Number(v))?Math.max(0,Math.floor(Number(v))):0;
const clean=v=>String(v||'').replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&nbsp;/g,' ').replace(/\s+/g,' ').trim();
export function jobSchema(html){
  for(const match of html.matchAll(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)){
    let root;try{root=JSON.parse(match[1])}catch{continue}
    const queue=Array.isArray(root)?[...root]:[root];
    while(queue.length){const item=queue.shift();if(!item||typeof item!=='object')continue;
      if([item['@type']].flat().includes('JobPosting'))return item;
      if(Array.isArray(item['@graph']))queue.push(...item['@graph']);
    }
  }
  return null;
}
async function page(url){
  const parsed=new URL(url);
  if(parsed.protocol!=='https:'||parsed.hostname!=='rocketjobs.pl')throw Error('Unexpected job source');
  const response=await fetch(url,{headers:{'User-Agent':'PortfolioInsights/1.0 (public job summaries; hourly)','Accept':'text/html'},signal:AbortSignal.timeout(15000),redirect:'error'});
  if(!response.ok)throw Error('Job source HTTP '+response.status);
  const text=await response.text();if(text.length>12000000)throw Error('Job source too large');return text;
}
export function parseOffer(html,url,now){
  const j=jobSchema(html);if(!j)return null;
  const title=clean(j.title).slice(0,160),company=clean(j.hiringOrganization?.name).slice(0,110);
  if(!title||!company||!/social|content|copywriter|creative|kreatywn|community|moderac/i.test(title)||/junior|staż|intern|paid social|performance|media buyer/i.test(title))return null;
  const expiry=Date.parse(j.validThrough);
  if(Number.isFinite(expiry)&&expiry<=now.getTime())return null;
  if(/oferta (jest )?(nieaktualna|wygasła)|ogłoszenie (jest )?nieaktualne/i.test(html.replace(/<script[\s\S]*?<\/script>/gi,'')))return null;
  const cities=[j.jobLocation].flat().filter(Boolean).map(x=>clean(x.address?.addressLocality)).filter(Boolean);
  const remote=/TELECOMMUTE/i.test(String(j.jobLocationType||''));
  if(!remote&&cities.length&&cities.every(x=>/warszawa|warsaw/i.test(x)))return null;
  const tags=[];if(/social|community|moderac/i.test(title))tags.push('social');if(/content|video|wideo/i.test(title))tags.push('video');if(/copy|creative|kreatywn/i.test(title))tags.push('creative');
  return {title,company,url,location:remote?'Zdalnie':cities.join(', ').slice(0,100)||'Sprawdź lokalizację w ofercie',tags,verifiedAt:now.toISOString(),validThrough:Number.isFinite(expiry)?new Date(expiry).toISOString():null};
}
export async function collectMarket(now=new Date()){
  const candidates=new Set(),errors=[];
  for(const source of marketSources){
    try{const html=await page(source);for(const m of html.matchAll(/href=["'](\/oferta-pracy\/[^"'?#]+)["']/g)){
      if(/social|content|copywriter|creative|kreatywn|community/i.test(m[1])&&!/junior|paid-social|performance|intern/i.test(m[1]))candidates.add('https://rocketjobs.pl'+m[1]);
    }}catch(error){errors.push(String(error.message));}
  }
  const jobs=[];
  const urls=[...candidates].sort((a,b)=>Number(/warszawa/.test(a))-Number(/warszawa/.test(b))).slice(0,10);
  for(const url of urls){
    try{const offer=parseOffer(await page(url),url,now);if(offer&&!jobs.some(j=>j.company===offer.company&&j.title===offer.title))jobs.push(offer);}catch(error){errors.push(String(error.message));}
    if(jobs.length>=4)break;
  }
  console.log('::notice title=Ninja market check::candidates='+candidates.size+'; verified_offers='+jobs.length+'; fetch_errors='+errors.length+(errors.length?'; first_error='+errors[0]:''));
  return {checkedAt:now.toISOString(),status:jobs.length?'ready':errors.length?'unavailable':'no_matches',sources:marketSources,jobs};
}
export function buildReport(raw,market,now){
  if(!raw||!Array.isArray(raw.hits)||raw.more)return {status:'unavailable',generatedAt:new Date().toISOString(),text:'Zwiadowca nie dostał pełnego raportu aktywności. Spróbuje ponownie przy kolejnej synchronizacji.',market};
  const hits=raw.hits,views=hits.filter(x=>!x.event).reduce((n,x)=>n+num(x.count),0);
  const events=hits.filter(x=>x.event),sum=re=>events.filter(x=>re.test(String(x.path))).reduce((n,x)=>n+num(x.count),0);
  const contact=sum(/^portfolio-contact-(pl|en)$/),end=sum(/^portfolio-end-(pl|en)$/),video=sum(/^portfolio-video-(pl|en)-/);
  const categories=[['social-media','Social Media','social'],['content-video','Content Video','video'],['brand-hero','Brand Hero','creative'],['big-idea-kampanie','Big Idea i Kampanie','creative'],['moderacja','Moderacja','social']].map(([slug,label,tag])=>({label,tag,count:sum(new RegExp('^portfolio-case-'+slug+'-(pl|en)$'))})).sort((a,b)=>b.count-a.count);
  const top=categories[0];const evidence=top.count>0;
  let text=views===0&&contact+end+video+top.count===0?'Spokojny patrol: w ostatnich 24 godzinach nie zarejestrowano wejść ani śledzonych akcji.':`Zwiadowca melduje: ${views} zliczeń wejść, ${end} dotarć do końca, ${video} uruchomień filmów i ${contact} kliknięć Kontakt w ostatnich 24 godzinach.`;
  if(evidence)text+=` Najczęściej wybierana sekcja: ${top.label} (${top.count} kliknięć).`;
  else if(views>0)text+=' Brakuje kliknięć kategorii, żeby wskazać kierunek zainteresowania.';
  if(contact>0)text+=' Kontakt przyciągnął uwagę; samo kliknięcie nie potwierdza wysłania wiadomości.';
  const matches=(market.jobs||[]).map(j=>({...j,match:evidence&&j.tags.includes(top.tag)})).sort((a,b)=>Number(b.match)-Number(a.match)).slice(0,2);
  const matched=matches.some(j=>j.match);
  const interpretation=matched?`Trop tematyczny: ${top.label} pasuje do poniższych rekrutacji. To porównanie zakresu pracy, nie rozpoznanie firmy odwiedzającej portfolio.`:'Brak podstaw do przypisania wizyty do konkretnej oferty. Poniżej propozycje z rynku pasujące do Twojego profilu social / content / kreacja.';
  return {status:'ready',generatedAt:new Date().toISOString(),windowStart:new Date(now.getTime()-86400000).toISOString(),windowEnd:now.toISOString(),text,interpretation,market:{...market,jobs:matches}};
}
