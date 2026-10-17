"use strict";
(() => {
  // Tuned for a small portfolio rather than high-traffic websites.
  const tiers = [
    {name:"Uczeń",min:0},{name:"Genin",min:8},{name:"Chūnin",min:20},
    {name:"Jōnin",min:40},{name:"Kage",min:75}
  ];
  const count = value => Number.isFinite(Number(value)) ? Math.max(0,Math.floor(Number(value))) : 0;
  const weights = {video:2,end:4,contact:6};
  function calculate(report,period="30") {
    let analyticsXp=count(report?.total);
    for (const event of Array.isArray(report?.events)?report.events:[]) {
      const path=String(event.path||"");
      const weight=/^portfolio-contact-(pl|en)$/.test(path)?weights.contact
        :/^portfolio-end-(pl|en)$/.test(path)?weights.end
        :/^portfolio-video-(pl|en)-[a-z0-9_-]{1,45}$/i.test(path)?weights.video:0;
      analyticsXp+=count(event.count)*weight;
    }
    // Daily missions live on THIS device only and cannot be farmed by toggling.
    const missionXp=typeof window.DailyQuests?.getXp==="function"
      ?count(window.DailyQuests.getXp(period)):0;
    const score=analyticsXp+missionXp;
    const tierIndex=tiers.reduce((best,tier,index)=>score>=tier.min?index:best,0);
    const tier=tiers[tierIndex],next=tiers[tierIndex+1];
    const progress=next?Math.min(100,Math.floor(100*(score-tier.min)/(next.min-tier.min))):100;
    return {score,analyticsXp,missionXp,tier,next,progress};
  }
  function render(report,period) {
    const result=calculate(report,period),format=new Intl.NumberFormat("pl-PL");
    const set=(id,value)=>{const node=document.getElementById(id);if(node)node.textContent=value;};
    set("shinobi-score",format.format(result.score));
    set("shinobi-rank",result.tier.name);
    set("side-rank-name",result.tier.name);
    set("score-period",period==="365"?"12 MIESIĘCY":period+" DNI");
    set("rank-next",result.next?"Następna: "+result.next.name:"Najwyższa ranga");
    const source="Statystyki: "+format.format(result.analyticsXp)+" · Misje: +"+format.format(result.missionXp)+" EXP";
    set("rank-hint",result.next?source+" · Do "+result.next.name+": "+format.format(result.next.min-result.score)+" EXP.":source+" · Kage osiągnięty.");
    const bar=document.getElementById("rank-fill");
    if(bar)bar.style.width=result.progress+"%";
    const element=document.getElementById("rank-progress");
    if(element){
      element.setAttribute("aria-valuenow",String(result.progress));
      element.setAttribute("aria-valuetext",result.next?result.progress+"% do rangi "+result.next.name:"Najwyższa ranga osiągnięta");
    }
  }
  window.ShinobiScore={calculate,render};
})();
