const fs = require('fs');

async function testTabs() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  const tabs = all.filter(t => t.type === 'page' && t.url && t.url.includes('claude.ai'));

  console.log(`Ditemukan ${tabs.length} tab.`);

  for (let i = 0; i < tabs.length; i++) {
    const tab = tabs[i];
    // Bring tab to front
    const ws = new WebSocket(tab.webSocketDebuggerUrl);
    await new Promise((resolve) => {
      ws.onopen = () => {
        ws.send(JSON.stringify({ id: 1, method: 'Page.bringToFront' }));
        setTimeout(() => { ws.close(); resolve(); }, 1000);
      };
      ws.onerror = () => resolve();
    });

    await new Promise(r => setTimeout(r, 1500));

    // Inspect
    const inspectCode = `(() => {
      const pm = document.querySelector('div.ProseMirror, [contenteditable="true"]');
      const bodyText = document.body.innerText || '';
      const limitKeys = ['out of free messages', 'telah mencapai batas pesan'];
      const isLimited = limitKeys.some(k => bodyText.toLowerCase().includes(k));
      return {
        id: '${tab.id}',
        title: document.title,
        canType: !!pm,
        isLimited: isLimited,
        bodyLen: bodyText.length
      };
    })()`;

    const ws2 = new WebSocket(tab.webSocketDebuggerUrl);
    const result = await new Promise((resolve) => {
      ws2.onopen = () => {
        ws2.send(JSON.stringify({
          id: 2,
          method: 'Runtime.evaluate',
          params: { returnByValue: true, expression: inspectCode }
        }));
      };
      ws2.onmessage = (e) => {
        const d = JSON.parse(e.data);
        ws2.close();
        resolve(d.result?.result?.value);
      };
      ws2.onerror = () => resolve({ error: 'ws error' });
    });

    console.log(`Tab #${i+1} [${tab.id.slice(0,8)}]: canType=${result?.canType}, isLimited=${result?.isLimited}, title=${result?.title}`);
  }
}

testTabs().catch(console.error);
