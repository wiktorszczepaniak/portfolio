/* Anonymous portfolio engagement counters. No IDs, cookies, fingerprints, or slide-by-slide tracking. */
(() => {
  'use strict';
  if (location.hostname !== 'wiktorszczepaniak.github.io' ||
      !/^\/portfolio\/(?:index\.html|en\.html)?$/.test(location.pathname)) return;
  const language = document.documentElement.lang === 'en' ? 'en' : 'pl';
  const slides = Array.from(document.querySelectorAll('main > .slide'));
  const delivered = new Set();
  const waiting = [];
  let ready = false;

  function excluded() {
    try { return !!localStorage.getItem('skipgc'); }
    catch { return true; }
  }
  function send(path, title) {
    if (excluded() || delivered.has(path)) return;
    delivered.add(path); // Once per event and page load, including zoomed/cloned videos.
    const payload = {path, title, event: true};
    if (typeof window.goatcounter?.count === 'function') {
      try {window.goatcounter.count(payload);}
      catch {/* Telemetry must never interfere with portfolio navigation. */}
    } else if (waiting.length < 60) {
      waiting.push(payload);
    }
  }
  function flush() {
    if (typeof window.goatcounter?.count !== 'function') return;
    ready = true;
    if (excluded()) { waiting.length = 0; return; }
    for (const item of waiting.splice(0)) {
      try {window.goatcounter.count(item);}
      catch {/* Ignore blocked telemetry. */}
    }
  }
  window.addEventListener('portfolio-gc-ready', flush, {once: true});
  // The library may have loaded before our deferred script.
  flush();
  if (!ready) {
    let attempts = 0;
    const check = setInterval(() => {
      flush();
      if (ready || ++attempts >= 15) {
        clearInterval(check);
        waiting.length = 0;
      }
    }, 400);
  }

  // Distinguish deliberate viewing from navigating directly to the last slide.
  if (slides.length >= 5 && 'IntersectionObserver' in window) {
    const seen = new Set();
    const required = Math.ceil(slides.length * 0.7);
    const observer = new IntersectionObserver(entries => {
      for (const entry of entries) {
        const index = slides.indexOf(entry.target);
        if (index < 0) continue;
        if (entry.isIntersecting && entry.intersectionRatio >= .12) seen.add(index);
      }
      const last = slides.at(-1);
      const rect = last.getBoundingClientRect();
      const visible = Math.max(0,Math.min(rect.bottom,innerHeight)-Math.max(rect.top,0));
      const portion = visible / Math.max(1,Math.min(rect.height,innerHeight));
      if (seen.size >= required && portion >= .5) {
        send('portfolio-end-' + language, 'Reached last slide after browsing 70% (' + language.toUpperCase() + ')');
        observer.disconnect();
      }
    }, {threshold: [0, .12, .5]});
    for (const slide of slides) observer.observe(slide);
  }

  // Tracks only switching to the OTHER language; the existing pageview remains separate.
  document.querySelectorAll('.language-switch [data-language]').forEach(link => {
    link.addEventListener('click', () => {
      const target = link.dataset.language;
      if (!['pl','en'].includes(target) || target === language) return;
      send('portfolio-lang-' + language + '-' + target,
        'Language switch ' + language.toUpperCase() + ' -> ' + target.toUpperCase());
    });
  });

  // A playable clip is identified by its static filename, not by a visitor or device.
  // Capture "playing" from HTMLVideoElement so native controls and zoomed copies work.
  document.addEventListener('playing', event => {
    const video = event.target;
    if (!(video instanceof HTMLVideoElement) ||
        !video.closest('main, #viewer')) return;
    const src = video.currentSrc || video.getAttribute('src') ||
      video.querySelector('source')?.getAttribute('src') || '';
    const basename = src.split('?')[0].split('/').pop() || '';
    const id = basename.replace(/\.[^.]+$/, '').replace(/[^a-zA-Z0-9_-]/g, '').slice(0,42);
    if (!id) return;
    const title = (video.getAttribute('aria-label') || 'Portfolio film').slice(0,100);
    send('portfolio-video-' + language + '-' + id, title);
  }, true);
})();
