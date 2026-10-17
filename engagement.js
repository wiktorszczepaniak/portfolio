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
  function send(path, title, everyClick = false) {
    if (excluded() || (!everyClick && delivered.has(path))) return;
    if (!everyClick) delivered.add(path); // Video/completion: once per page load. Navigation: every click.
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

  // Category dropdown counts intentional selections, not scrolling through slides.
  // Record every selection (including repeat visits to the same category).
  const caseNames = new Map([
    ['5', 'social-media'],
    ['12', 'content-video'],
    ['15', 'brand-hero'],
    ['18', 'big-idea-kampanie'],
    ['24', 'moderacja']
  ]);
  const caseTitles = new Map([
    ['5', 'Social Media'],
    ['12', 'Content Video'],
    ['15', 'Brand Hero'],
    ['18', 'Big Idea i Kampanie'],
    ['24', 'Moderacja']
  ]);
  const categorySelect = document.querySelector('#slide-select');
  categorySelect?.addEventListener('change', () => {
    const id = categorySelect.value;
    const slug = caseNames.get(id);
    if (!slug) return;
    send('portfolio-case-' + slug + '-' + language,
      'Case Studies: ' + caseTitles.get(id) + ' (' + language.toUpperCase() + ')', true);
  });

  // Contact is a fixed top shortcut; no hit for merely reaching the contact slide.
  document.querySelector('.language-switch .contact-shortcut')?.addEventListener('click', () => {
    send('portfolio-contact-' + language,
      'Top navigation: Contact (' + language.toUpperCase() + ')', true);
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
