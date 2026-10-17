"use strict";
window.NinjaReport={render(report){
 const el=id=>document.getElementById(id),format=d=>new Intl.DateTimeFormat('pl-PL',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit',timeZone:'Europe/Warsaw'}).format(new Date(d));
 const jobs=el('ninja-report-jobs');jobs.replaceChildren();
 if(!report){el('ninja-report-text').textContent='Pierwszy raport zwiadowcy pojawi się po kolejnej synchronizacji danych.';return;}
 const time=Date.parse(report.generatedAt),stale=!Number.isFinite(time)||Date.now()-time>2*3600000;
 el('ninja-report-title').closest('section').classList.toggle('stale',stale);
 el('ninja-report-time').textContent=Number.isFinite(time)?(stale?'Starszy raport · ':'Aktualizacja · ')+format(time):'Brak daty raportu';
 el('ninja-report-text').textContent=report.text;
 el('ninja-report-interpretation').textContent=report.interpretation||'Brak pełnych danych do interpretacji aktywności.';
 el('ninja-window').textContent=report.windowEnd?'Dane do '+format(report.windowEnd)+' · okno 24h':'Planowo co godzinę';
 const market=report.market;
 el('ninja-market-status').textContent=market?.status==='ready'?'RocketJobs · sprawdzono '+format(market.checkedAt):market?.status==='no_matches'?'RocketJobs · brak potwierdzonych ofert spełniających filtr':'RocketJobs · nie udało się sprawdzić aktualnych ofert';
 for(const offer of market?.jobs||[]){
  let url;try{url=new URL(offer.url)}catch{continue}if(url.protocol!=='https:'||url.hostname!=='rocketjobs.pl')continue;
  if(offer.validThrough&&Date.parse(offer.validThrough)<=Date.now())continue;
  const link=document.createElement('a');link.className='ninja-job';link.href=url.href;link.target='_blank';link.rel='noopener noreferrer';
  const title=document.createElement('strong');title.textContent=offer.title+' ↗';
  const detail=document.createElement('small');detail.textContent=offer.company+' · '+offer.location+(offer.match?' · trop tematyczny':' · propozycja dla Twojego profilu');link.append(title,detail);jobs.append(link);
 }
}};
