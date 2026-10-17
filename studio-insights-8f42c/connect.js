"use strict";
/*
 * Decrypts an AES-GCM report published by GitHub Actions.
 * The GoatCounter API is NEVER called from the browser.
 * Only a one-way derived decryption key is stored, not the API token.
 */
(() => {
 const $ = id => document.getElementById(id);
 const STORAGE_KEY = "portfolio_intelligence_decryption_key_v2";
 const MASTER_SALT = "wiktor-portfolio-intelligence-master-v1";
 const INFO = "wiktor-portfolio-stats-payload-2026";
 const encoder = new TextEncoder();
 const decoder = new TextDecoder();
 let envelope = null, snapshot = null, pending = null, loading = null;

 // Clear any raw API credential left by the deprecated direct-fetch integration.
 localStorage.removeItem("portfolio_intelligence_readonly_token_v1");
 sessionStorage.removeItem("portfolio_intelligence_readonly_token_v1");

 function from64(value) {
   const bytes=atob(value),output=new Uint8Array(bytes.length);
   for(let i=0;i<bytes.length;i++)output[i]=bytes.charCodeAt(i);
   return output;
 }
 function to64(bytes) {
   let result="";
   for(const byte of bytes)result+=String.fromCharCode(byte);
   return btoa(result);
 }
 async function deriveFromToken(token) {
   const secret=await crypto.subtle.importKey("raw",encoder.encode(token),"PBKDF2",false,["deriveBits"]);
   return new Uint8Array(await crypto.subtle.deriveBits(
     {name:"PBKDF2",salt:encoder.encode(MASTER_SALT),iterations:220000,hash:"SHA-256"},secret,256
   ));
 }
 async function decrypt(master) {
   if(!envelope||envelope.version!==1)throw Error("Raport ma nieobsługiwany format.");
   const source=await crypto.subtle.importKey("raw",master,"HKDF",false,["deriveKey"]);
   const key=await crypto.subtle.deriveKey(
     {name:"HKDF",salt:from64(envelope.salt),info:encoder.encode(INFO),hash:"SHA-256"},
     source,{name:"AES-GCM",length:256},false,["decrypt"]
   );
   const clear=await crypto.subtle.decrypt(
     {name:"AES-GCM",iv:from64(envelope.iv)},key,from64(envelope.ciphertext)
   );
   const result=JSON.parse(decoder.decode(clear));
   if(result.schema!==2||result.status!=="ready"||!result.periods)throw Error("Zaszyfrowane dane są nieprawidłowe.");
   return result;
 }
 async function fetchEnvelope(force=false) {
   if(envelope&&!force)return envelope;
   const url="./data.enc.json?t="+Date.now();
   const response=await fetch(url,{cache:"no-store",credentials:"same-origin"});
   if(response.status===404)throw Error("Panel czeka na pierwszy raport. Dodaj GOATCOUNTER_TOKEN do GitHub → portfolio → Settings → Secrets and variables → Actions i uruchom workflow Update encrypted portfolio dashboard.");
   if(!response.ok)throw Error("Nie udało się pobrać raportu z GitHuba (HTTP "+response.status+").");
   const raw=await response.json();
   if(!raw||raw.version!==1||!raw.ciphertext)throw Error("Nie znaleziono poprawnie zaszyfrowanego raportu.");
   envelope=raw;return raw;
 }
 function showModal(message="") {
   $("connect-overlay").hidden=false;
   if(pending)return pending;
   $("connect-error").hidden=!message;
   $("connect-error").textContent=message;
   $("goat-token").value="";
   $("goat-token").focus();
   pending=new Promise(resolve=>{
     window.__resolveReportToken = resolve;
   });
   return pending;
 }
 function closeModal() {
   $("connect-overlay").hidden=true;
   $("goat-token").value="";
   if(window.__resolveReportToken)window.__resolveReportToken();
   window.__resolveReportToken=null;
   pending=null;
 }
 $("connect-form").addEventListener("submit",async e=>{
   e.preventDefault();
   const candidate=$("goat-token").value.trim();
   const button=$("connect-button");
   if(!candidate)return;
   button.disabled=true;button.textContent="Odszyfrowuję statystyki...";
   $("connect-error").hidden=true;
   try{
     await fetchEnvelope();
     const master=await deriveFromToken(candidate);
     const data=await decrypt(master);
     const encoded=to64(master);
     if($("remember-key").checked){
       localStorage.setItem(STORAGE_KEY,encoded);
       sessionStorage.removeItem(STORAGE_KEY);
     } else {
       sessionStorage.setItem(STORAGE_KEY,encoded);
       localStorage.removeItem(STORAGE_KEY);
     }
     snapshot=data;
     closeModal();
   } catch(error) {
     $("connect-error").hidden=false;
     $("connect-error").textContent=String(error?.message||"Nie udało się odszyfrować raportu. Sprawdź token.");
   }finally{button.disabled=false;button.textContent="Połącz i pokaż dashboard ↗"}
 });
 $("manage-key").addEventListener("click",async()=>{
   localStorage.removeItem(STORAGE_KEY);sessionStorage.removeItem(STORAGE_KEY);snapshot=null;
   try{await fetchEnvelope();await showModal();$("refresh").click()}catch(err){
     const status=$("status");status.textContent=String(err.message||err);status.closest(".status-row").classList.add("error")
   }
 });
 async function doLoad(){
   await fetchEnvelope();
   if(snapshot)return snapshot;
   let master=localStorage.getItem(STORAGE_KEY)||sessionStorage.getItem(STORAGE_KEY);
   if(master){
     try{snapshot=await decrypt(from64(master));return snapshot}
     catch {
       localStorage.removeItem(STORAGE_KEY);sessionStorage.removeItem(STORAGE_KEY);
     }
   }
   await showModal("Wprowadź token GoatCounter, aby odszyfrować prywatny raport.");
   if(!snapshot)throw Error("Brak klucza do odszyfrowania statystyk.");
   return snapshot;
 }
 window.GoatData={
   async load(){
     if(loading)return loading;
     loading=doLoad();
     try{return await loading}finally{loading=null}
   },
   async invalidate(){
     snapshot=null;envelope=null;
   }
 };
})();

