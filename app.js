/* No dependencies, no build, and no network services. */
(() => {
  'use strict';
  const slides = [...document.querySelectorAll('main > .slide')];
  const select = document.querySelector('#slide-select');
  const prev = document.querySelector('#prev');
  const next = document.querySelector('#next');
  const progress = document.querySelector('.progress span');
  const viewer = document.querySelector('#viewer');
  const content = document.querySelector('.viewer-content');
  const scroller = document.querySelector('.viewer-scroll');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let current = 1, zoom = 1, scheduled = false;

  function go(number, updateHash = true) {
    number = Math.max(1, Math.min(slides.length, Number(number)));
    current = number;
    slides[number - 1].scrollIntoView({behavior: reduceMotion.matches ? 'instant' : 'smooth', block:'start'});
    if (updateHash) history.replaceState(null, '', '#slajd-' + number);
  }
  function update() {
    scheduled = false;
    const position = Math.min(innerHeight * .33, 350);
    let closest = Infinity;
    slides.forEach((slide, i) => {
      const rect = slide.getBoundingClientRect();
      const distance = position >= rect.top && position <= rect.bottom ? 0 : Math.min(Math.abs(rect.top-position), Math.abs(rect.bottom-position));
      if (distance < closest) { closest = distance; current = i + 1; }
    });
    select.value = String(current);
    prev.disabled = current === 1; next.disabled = current === slides.length;
    progress.style.transform = `scaleX(${current / slides.length})`;
  }
  addEventListener('scroll', () => { if (!scheduled) { scheduled = true; requestAnimationFrame(update); } }, {passive:true});
  addEventListener('resize', update);
  prev.addEventListener('click', () => go(current - 1));
  next.addEventListener('click', () => go(current + 1));
  select.addEventListener('change', () => go(select.value));
  document.querySelector('.contact').addEventListener('click', event => {event.preventDefault();go(26);});
  addEventListener('keydown', event => {
    if (viewer.open || /INPUT|SELECT|TEXTAREA|VIDEO|BUTTON|A/.test(event.target.tagName) || event.ctrlKey || event.metaKey || event.altKey) return;
    const destination = {ArrowRight:current+1,ArrowLeft:current-1,PageDown:current+1,PageUp:current-1,Home:1,End:slides.length}[event.key];
    if (destination) {event.preventDefault();go(destination);}
  });
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      if (entry.target !== slides[0] && !reduceMotion.matches) entry.target.classList.add('reveal');
      observer.unobserve(entry.target);
    }), {threshold:.08});
    slides.forEach(slide => observer.observe(slide));
    const pause = new IntersectionObserver(entries => entries.forEach(entry => {
      if (!entry.isIntersecting) entry.target.querySelectorAll('video').forEach(video => video.pause());
    }), {threshold:0});
    slides.forEach(slide => pause.observe(slide));
  }

  function setupImages(root) {
    root.querySelectorAll('img[data-fallback]').forEach(img => {
      const fallback = () => {
        if (!img.dataset.fallback) return;
        const src = img.dataset.fallback;
        delete img.dataset.fallback;
        img.src = src;
      };
      img.addEventListener('error', fallback, {once:true});
      if (img.complete && !img.naturalWidth) fallback();
    });
  }
  function setupMedia(root) {
    root.querySelectorAll('.media').forEach(media => {
      const video = media.querySelector('video');
      const play = media.querySelector('.play');
      const error = media.querySelector('.video-error');
      video.controls = true;
      const pauseOthers = () => document.querySelectorAll('video').forEach(other => {
        if (other !== video) other.pause();
      });
      play.addEventListener('click', () => {
        pauseOthers();
        error.hidden = true;
        if (video.error) video.load();
        media.classList.add('loading');
        video.play().catch(reason => {
          media.classList.remove('playing', 'loading');
          if (reason.name !== 'AbortError') error.hidden = false;
        });
      });
      video.addEventListener('play', () => {pauseOthers(); media.classList.add('playing'); error.hidden = true;});
      video.addEventListener('playing', () => media.classList.remove('loading'));
      video.addEventListener('pause', () => media.classList.remove('loading'));
      video.addEventListener('error', () => {media.classList.remove('playing', 'loading'); error.hidden = false;});
      video.addEventListener('ended', () => media.classList.remove('playing', 'loading'));
    });
  }
  setupImages(document.querySelector('main'));
  setupMedia(document.querySelector('main'));

  function applyZoom() {
    const base = Math.min(scroller.clientWidth, scroller.clientHeight * 16/9);
    content.style.width = `${base * zoom}px`;
    document.querySelector('#zoom-level').textContent = `${Math.round(zoom*100)}%`;
    document.querySelector('#zoom-out').disabled = zoom <= 1;
    document.querySelector('#zoom-in').disabled = zoom >= 4;
  }
  document.querySelector('#zoom').addEventListener('click', () => {
    document.querySelectorAll('video').forEach(video => video.pause());
    content.replaceChildren(slides[current-1].querySelector('.canvas').cloneNode(true));
    content.querySelectorAll('.media').forEach(media => media.classList.remove('playing'));
    content.querySelector('.slide-image').loading = 'eager';
    setupImages(content);
    setupMedia(content);
    viewer.showModal();document.body.classList.add('modal-open');zoom = innerWidth < 700 ? 2 : 1;
    applyZoom();scroller.scrollTo(0,0);
    document.querySelector('#close-viewer').focus();
  });
  document.querySelector('#close-viewer').addEventListener('click', () => viewer.close());
  viewer.addEventListener('close', () => {content.querySelectorAll('video').forEach(v=>v.pause());content.replaceChildren();document.body.classList.remove('modal-open');});
  document.querySelector('#zoom-in').addEventListener('click', () => {zoom = Math.min(4,zoom+.5);applyZoom();});
  document.querySelector('#zoom-out').addEventListener('click', () => {zoom = Math.max(1,zoom-.5);applyZoom();});
  addEventListener('resize', () => {if(viewer.open) applyZoom();});
  const initial = location.hash.match(/^#slajd-(\d+)$/);
  if(initial) requestAnimationFrame(() => slides[Math.max(0,Math.min(25,Number(initial[1])-1))].scrollIntoView());
  update();
})();
