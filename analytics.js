/* Set data-goatcounter-code on this script only after verifying account ownership. */
(()=>{
 'use strict';
 if(location.hostname!=='wiktorszczepaniak.github.io')return;
 const code=document.currentScript?.dataset.goatcounterCode;
 if(!code||!/^[a-z0-9][a-z0-9-]*$/.test(code))return;
 // Official GoatCounter exclusion uses localStorage.skipgc; the provider's
 // count.js handles #toggle-goatcounter. No slide/hash-change tracking is added.
 window.goatcounter={path:()=>location.pathname==='/portfolio/en.html'?'/portfolio/en.html':'/portfolio/',title:location.pathname.endsWith('/en.html')?'Portfolio EN':'Portfolio PL'};
 const s=document.createElement('script');s.async=true;s.src='https://gc.zgo.at/count.js';
 s.dataset.goatcounter='https://'+code+'.goatcounter.com/count';
 s.onerror=()=>{};document.head.appendChild(s);
})();
