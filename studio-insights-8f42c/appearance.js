"use strict";
(() => {
  const toggle = document.getElementById("focus-mode");
  const key = "ws_studio_focus";
  try { toggle.checked = localStorage.getItem(key) === "on"; } catch {}
  const apply = () => {
    document.body.classList.toggle("focus-mode", toggle.checked);
    try { localStorage.setItem(key, toggle.checked ? "on" : "off"); } catch {}
  };
  toggle.addEventListener("change", apply);
  apply();
  document.getElementById("preview-layout").addEventListener("click", () => {
    document.getElementById("connect-overlay").hidden = true;
    document.getElementById("status").textContent = "Podgląd wyglądu · dane pozostają zaszyfrowane. Kliknij Klucz API, aby je połączyć.";
    document.getElementById("sync-text").textContent = "Podgląd bez danych";
    document.getElementById("focus-mode").focus();
  });
})();
