"use strict";
window.NinjaReport = {
  render(report) {
    const el=id=>document.getElementById(id);
    const format=d=>new Intl.DateTimeFormat("pl-PL",{
      day:"numeric",month:"short",hour:"2-digit",minute:"2-digit",timeZone:"Europe/Warsaw"
    }).format(new Date(d));
    window.DailyQuests?.render(report?.market||null);
    if(!report) {
      el("ninja-report-text").textContent="Pierwszy raport pojawi się po synchronizacji danych.";
      el("ninja-report-interpretation").textContent="Na podstawie wejść nie da się ustalić, kto odwiedzał portfolio.";
      return;
    }
    const time=Date.parse(report.generatedAt),stale=!Number.isFinite(time)||Date.now()-time>2*3600000;
    el("ninja-report-title").closest("section").classList.toggle("stale",stale);
    el("ninja-report-time").textContent=Number.isFinite(time)
      ?(stale?"Ostatni raport · ":"Aktualizacja · ")+format(time)
      :"Brak daty raportu";
    el("ninja-report-text").textContent=report.text;
    el("ninja-report-interpretation").textContent=report.interpretation
      ||"Nie ma podstaw, żeby przypisać wejścia do konkretnej firmy.";
    el("ninja-window").textContent=report.hourEnd
      ?"Ostatnia pełna godzina do "+format(report.hourEnd)+" · 24h w tle"
      :report.windowEnd?"Dane do "+format(report.windowEnd)+" · ostatnie 24h":"Planowo co godzinę";
    const market=report.market;
    el("ninja-market-status").textContent=market?.status==="ready"
      ?"RocketJobs · oferty sprawdzono "+format(market.checkedAt)
      :market?.status==="no_matches"
        ?"RocketJobs · brak potwierdzonych ofert"
        :"RocketJobs · nie udało się dziś pobrać ofert";
  }
};
