async function checkTab(wsUrl) {
  return new Promise((resolve) => {
    const ws = new WebSocket(wsUrl);
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve({ error: 'timeout' });
    }, 5000);

    ws.onopen = () => {
      const code = `
        (() => {
          try {
            const pm = document.querySelector('div.ProseMirror, [contenteditable="true"]');
            const btns = Array.from(document.querySelectorAll('button'));
            
            // Periksa apakah ada pesan limit token / kuota
            const bodyText = document.body.innerText || '';
            const isLimitMsg = [
              'out of free messages',
              'message limit until',
              'limit reached',
              'resets at',
              'usage limit reached'
            ].some(k => bodyText.toLowerCase().includes(k));

            // Cari nama akun aktif
            let accountName = 'Unknown';
            const userBtn = btns.find(b => b.innerText && (b.innerText.includes('·') || b.innerText.includes('Free') || b.innerText.includes('Pro')));
            if (userBtn) {
              accountName = userBtn.innerText.split('\\n').join(' ').trim();
            }

            const isLogin = location.pathname.startsWith('/login') || bodyText.includes('Continue with Google');

            return {
              url: location.href,
              title: document.title,
              account: accountName,
              canType: !!pm,
              isLimited: isLimitMsg,
              isLoggedIn: !isLogin
            };
          } catch(err) {
            return { error: err.message };
          }
        })()
      `;

      ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: {
          returnByValue: true,
          expression: code
        }
      }));
    };

    ws.onmessage = (evt) => {
      clearTimeout(timer);
      try {
        const msg = JSON.parse(evt.data);
        if (msg.id === 1) {
          ws.close();
          if (msg.result && msg.result.result && msg.result.result.value) {
            resolve(msg.result.result.value);
          } else {
            resolve({ error: JSON.stringify(msg) });
          }
        }
      } catch(e) {
        resolve({ error: e.message });
      }
    };

    ws.onerror = (err) => {
      clearTimeout(timer);
      resolve({ error: err.message });
    };
  });
}

async function main() {
  const ports = [9222, 9223, 9224];
  for (const port of ports) {
    console.log(`\n=== Memeriksa Port Debug ${port} ===`);
    try {
      const res = await fetch(`http://localhost:${port}/json/list`);
      const tabs = (await res.json()).filter(t => t.type === 'page');
      console.log(`Ditemukan ${tabs.length} tab pada port ${port}:`);
      for (const tab of tabs) {
        if (tab.url.includes('claude.ai')) {
          const info = await checkTab(tab.webSocketDebuggerUrl);
          console.log(`Tab [${tab.id.slice(0, 8)}] "${tab.title}":`);
          console.log(`   URL: ${info.url}`);
          console.log(`   Akun: ${info.account}`);
          console.log(`   Status: LoggedIn=${info.isLoggedIn}, CanType=${info.canType}, Limited=${info.isLimited}`);
        } else {
          console.log(`Tab [${tab.id.slice(0, 8)}] (non-Claude): ${tab.url}`);
        }
      }
    } catch (e) {
      console.log(`Port ${port} tidak aktif (${e.message}).`);
    }
  }
}

main();
