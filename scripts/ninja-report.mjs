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
    try{const html=(await page(source)).replace(/\\\//g,"/");for(const m of html.matchAll(/\/oferta-pracy\/[a-zA-Z0-9_%.-]+/g)){
      if(/social|content|copywriter|creative|kreatywn|community/i.test(m[0])&&!/junior|paid-social|performance|intern/i.test(m[0]))candidates.add("https://rocketjobs.pl"+m[0]);
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
function plural(n,singular,paucal,pluralForm){
  const d=Math.abs(n)%10,teens=Math.abs(n)%100;
  return n===1?singular:(d>=2&&d<=4&&!(teens>=12&&teens<=14))?paucal:pluralForm;
}
function summarizeHits(raw) {
  if (!raw || !Array.isArray(raw.hits) || raw.more) return null;
  const hits=raw.hits;
  const events=hits.filter(x=>x.event);
  const sum=re=>events.filter(x=>re.test(String(x.path))).reduce((n,x)=>n+num(x.count),0);
  return {
    views:hits.filter(x=>!x.event).reduce((n,x)=>n+num(x.count),0),
    contact:sum(/^portfolio-contact-(pl|en)$/),
    end:sum(/^portfolio-end-(pl|en)$/),
    video:sum(/^portfolio-video-(pl|en)-/),
    cases:sum(/^portfolio-case-/),
    categories:[['social-media','Social Media','social'],
      ['content-video','Content Video','video'],
      ['brand-hero','Brand Hero','creative'],
      ['big-idea-kampanie','Big Idea i Kampanie','creative'],
      ['moderacja','Moderacja','social']
    ].map(([slug,label,tag])=>({
      label,tag,count:sum(new RegExp('^portfolio-case-'+slug+'-(pl|en)$'))
    })).sort((a,b)=>b.count-a.count)
  };
}
export function buildReport(raw,market,now,lastHour=null){
  const daily=summarizeHits(raw);
  const hourly=summarizeHits(lastHour);
  const jobs=Array.isArray(market?.jobs)?market.jobs:[];
  if (!daily) return {
    status:'unavailable',generatedAt:new Date().toISOString(),
    windowStart:new Date(now.getTime()-86400000).toISOString(),windowEnd:now.toISOString(),
    text:'Zwiadowca nie dostał pełnych danych za ostatnią dobę. Nie podaje zmyślonych wyników. Spróbuje ponownie za godzinę.',
    interpretation:'Brak podstaw do wskazania firmy lub ogłoszenia na podstawie samych danych o odwiedzinach.',
    market:{...market,jobs:jobs.slice(0,3)}
  };
  const zero=daily.views+daily.contact+daily.video+daily.end+daily.cases===0;
  let text='';
  if(hourly){
    const hourAction=hourly.contact+hourly.video+hourly.cases+hourly.end;
    text=hourly.views===0&&hourAction===0
      ? 'Ostatnia pełna godzina była spokojna: nie odnotowano odsłon ani śledzonych akcji.'
      : 'Ostatnia pełna godzina: '+hourly.views+' '+plural(hourly.views,'odsłona','odsłony','odsłon')+', '+hourly.video+' '+plural(hourly.video,'odtworzenie','odtworzenia','odtworzeń')+' filmów, '+hourly.cases+' '+plural(hourly.cases,'wybór','wybory','wyborów')+' Case Studies i '+hourly.contact+' '+plural(hourly.contact,'kliknięcie','kliknięcia','kliknięć')+' Kontakt.';
    if(hourly.end>0)text+=' Do końca portfolio dotarto '+hourly.end+' '+plural(hourly.end,'raz','razy','razy')+'.';
  }else{
    text='Ostatnia godzina: brak pełnych danych, nie oznacza to braku odwiedzin.';
  }
  if(zero){
    text+=' W całej ostatniej dobie także nie odnotowano odsłon ani śledzonych akcji.';
  }else{
    text+=' W ostatnich 24h: '+daily.views+' '+plural(daily.views,'odsłona','odsłony','odsłon')+', '+daily.end+' '+plural(daily.end,'dotarcie','dotarcia','dotarć')+' do końca, '+daily.video+' '+plural(daily.video,'uruchomienie','uruchomienia','uruchomień')+' filmów i '+daily.contact+' '+plural(daily.contact,'kliknięcie','kliknięcia','kliknięć')+' Kontakt.';
    if(daily.categories[0].count>0)text+=' Najchętniej wybierano '+daily.categories[0].label+' ('+daily.categories[0].count+' '+plural(daily.categories[0].count,'kliknięcie','kliknięcia','kliknięć')+').';
  }
  const top=daily.categories[0],hasSignal=top.count>0;
  const rankedJobs=jobs.map(job=>({
    ...job,match:hasSignal&&Array.isArray(job.tags)&&job.tags.includes(top.tag)
  })).sort((a,b)=>Number(b.match)-Number(a.match)).slice(0,3);
  const matchingJob=rankedJobs.some(job=>job.match);
  let interpretation;
  if(!daily.views&&!hourly?.views){
    interpretation='Brak nowych sygnałów rekrutacyjnych. Powiązanie jakiejkolwiek oferty z osobą odwiedzającą portfolio byłoby zgadywaniem.';
  }else if(matchingJob){
    interpretation='Hipoteza zwiadowcy: zainteresowanie sekcją '+top.label+' tematycznie pasuje do zweryfikowanych ofert poniżej. Nie wiadomo, czy odwiedzał Cię rekruter ani z jakiej firmy.';
  }else if(jobs.length){
    interpretation='Trop z rynku: poniższe dostępne w chwili sprawdzania ogłoszenia pasują do profilu social media / copywriting / kreacja. Brak dowodu, że którakolwiek firma odwiedziła portfolio.';
  }else{
    interpretation='Nie znalazłem teraz ofert, które udało się potwierdzić w źródle. Same wejścia nie pozwalają określić pracodawcy ani rekrutacji.';
  }
  return {
    status:'ready',generatedAt:new Date().toISOString(),
    windowStart:new Date(now.getTime()-86400000).toISOString(),windowEnd:now.toISOString(),
    hourStart:new Date(now.getTime()-3600000).toISOString(),
    hourEnd:now.toISOString(),
    hourlyAvailable:!!hourly,text,interpretation,
    market:{...market,jobs:rankedJobs}
  };
}
