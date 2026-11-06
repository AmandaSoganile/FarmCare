import secrets

from fastapi.responses import HTMLResponse


def recovery_page(purpose):
    """Fragments keep one-use tokens out of HTTP access logs and referrers.

    Explicit submission also avoids email scanners consuming verification links.
    """
    nonce = secrets.token_urlsafe(24)
    reset = purpose == "reset"
    title = "Reset your password" if reset else "Confirm your email"
    endpoint = "/v1/auth/reset-password" if reset else "/v1/auth/verify-email"
    fields = ('<label>New password<input id="password" type="password" minlength="8" maxlength="128" autocomplete="new-password" required></label>'
              '<label>Confirm password<input id="confirm" type="password" minlength="8" maxlength="128" autocomplete="new-password" required></label>') if reset else ""
    html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>FarmCare — TITLE</title><style>
body{font:17px system-ui;background:#f3f7f3;color:#183321;margin:0;padding:24px}main{max-width:420px;margin:10vh auto;background:white;padding:28px;border-radius:20px}
label,input{display:block}input{box-sizing:border-box;width:100%;padding:12px;margin:8px 0 20px;border:1px solid #adb8ad;border-radius:8px;font:inherit}
button{padding:12px 20px;background:#226a3b;color:white;border:0;border-radius:8px;font:inherit}button:disabled{opacity:.6}#message{line-height:1.5}
</style><main><p>FarmCare</p><h1>TITLE</h1><form>FIELDS<button type="submit">TITLE</button></form><p id="message" role="status" aria-live="polite"></p></main>
<script nonce="NONCE">
const token=new URLSearchParams(location.hash.slice(1)).get('token');
history.replaceState(null,'',location.pathname);
const form=document.querySelector('form'), message=document.querySelector('#message'), button=document.querySelector('button');
if(!token){message.textContent='This link is incomplete. Request a new email from FarmCare.';button.disabled=true;}
form.addEventListener('submit',async event=>{
 event.preventDefault();
 const password=document.querySelector('#password');
 if(password && password.value!==document.querySelector('#confirm').value){message.textContent='Passwords do not match.';return;}
 button.disabled=true;
 try{
  const body={token}; if(password)body.password=password.value;
  const response=await fetch('ENDPOINT',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const data=await response.json();
  if(!response.ok)throw new Error(data.error?.message || 'Please try again.');
  message.textContent=data.message;form.remove();
 }catch(error){message.textContent=error.message || 'Could not connect. Please try again.';button.disabled=false;}
});
</script></html>'''
    html = html.replace("TITLE", title).replace("FIELDS", fields).replace("NONCE", nonce).replace("ENDPOINT", endpoint)
    return HTMLResponse(html, headers={
        "Content-Security-Policy": f"default-src 'none'; script-src 'nonce-{nonce}'; style-src 'unsafe-inline'; connect-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'none'",
        "Referrer-Policy": "no-referrer", "Cache-Control": "no-store"})
