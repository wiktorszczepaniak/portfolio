"use strict";
(() => {
  const tiers = [{name:"Uczeń",min:0},{name:"Genin",min:5},{name:"Chūnin",min:15},{name:"Jōnin",min:30},{name:"Kage",min:60}];
  const count = value => Number.isFinite(Number(value)) ? Math.max(0,Math.floor(Number(value))) : 0;
  function calculate(report) {
    let score = count(report.total);
    for (const event of Array.isArray(report.events) ? report.events : []) {
      const path = String(event.path || "");
      const weight = /^portfolio-contact-(pl|en)$/.test(path) ? 10 : /^portfolio-end-(pl|en)$/.test(path) ? 5 : /^portfolio-video-(pl|en)-[a-z0-9_-]{1,45}$/i.test(path) ? 3 : 0;
      score += count(event.count) * weight;
    }
    const tierIndex = tiers.reduce((best,tier,index) => score >= tier.min ? index : best,0);
    const tier = tiers[tierIndex], next = tiers[tierIndex+1];
    const progress = next ? Math.floor(100*(score-tier.min)/(next.min-tier.min)) : 100;
    return {score,tier,next,progress};
  }
  function render(report,period) {
    const result = calculate(report), format = new Intl.NumberFormat("pl-PL");
    const set = (id,text) => { document.getElementById(id).textContent = text; };
    set("shinobi-score",format.format(result.score));
    set("shinobi-rank",result.tier.name);
    set("side-rank-name",result.tier.name);
    set("score-period",period === "365" ? "12 MIESIĘCY" : period + " DNI");
    set("rank-next",result.next ? "Następna: " + result.next.name : "Najwyższa ranga");
    set("rank-hint",result.next ? "Jeszcze " + format.format(result.next.min-result.score) + " pkt do kolejnej rangi." : "Próg 60 pkt osiągnięty. Wynik rośnie dalej.");
    document.getElementById("rank-fill").style.width = result.progress + "%";
    document.getElementById("rank-progress").setAttribute("aria-valuenow",String(result.progress));
    document.getElementById("rank-progress").setAttribute("aria-valuetext",result.next ? result.progress + "% do rangi " + result.next.name : "Najwyższa ranga osiągnięta");
  }
  window.ShinobiScore = {calculate,render};
})();

