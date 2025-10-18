(function () {
  function parseQuery(url) {
    const out = {}; const i = url.indexOf('?'); if (i < 0) return out;
    for (const p of url.slice(i + 1).split('&')) {
      const [k, v] = p.split('=');
      out[decodeURIComponent(k)] = decodeURIComponent(v || '');
    }
    return out;
  }
  const Cap = window.Capacitor || {};
  const App = Cap.Plugins && Cap.Plugins.App;
  const Browser = Cap.Plugins && Cap.Plugins.Browser;
  if (!App) { console.warn('[callback] App plugin missing'); return; }

  App.addListener('appUrlOpen', async ({ url }) => {
    console.log('[callback] appUrlOpen:', url);
    try { if (Browser && Browser.close) { await Browser.close(); } } catch {}
    const q = parseQuery(url);
    if (q.code) {
      console.log('Auth code:', q.code);
      alert('Signed in ✅ (code received)');
      // TODO: POST q.code to your backend to exchange for tokens.
    } else {
      alert('Returned without code.');
    }
  });
})();
