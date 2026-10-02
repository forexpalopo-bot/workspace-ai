async function test() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  const tabs = all.filter(t => t.type === 'page' && t.url && t.url.includes('claude.ai'));

  for (let i = 0; i < tabs.length; i++) {
    const t = tabs[i];
    const ws = new WebSocket(t.webSocketDebuggerUrl);
    const result = await new Promise((resolve) => {
      const tm = setTimeout(() => { ws.close(); resolve({ error: 'timeout' }); }, 4000);
      ws.onopen = () => {
        ws.send(JSON.stringify({
          id: 1,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `(() => {
              const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
              const sendBtn = document.querySelector('button[data-testid="chat-input-send"]');
              const userBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText && (b.innerText.includes('·') || b.innerText.includes('Free')));
              const modals = Array.from(document.querySelectorAll('div[role="dialog"], [data-state="open"]'));
              return {
                account: userBtn ? userBtn.innerText.replace(/\\n/g, ' ') : 'Unknown',
                editorExists: !!editor,
                editorText: editor ? editor.innerText.trim() : '',
                sendBtnExists: !!sendBtn,
                sendDisabled: sendBtn ? sendBtn.disabled : null,
                modalCount: modals.length,
                modalSnippet: modals.map(m => m.innerText.replace(/\\n/g, ' ').slice(0, 50))
              };
            })()`
          }
        }));
      };
      ws.onmessage = (e) => {
        clearTimeout(tm);
        const d = JSON.parse(e.data);
        ws.close();
        resolve(d.result?.result?.value);
      };
    });
    console.log(`[Tab #${i+1}] ${t.id.slice(0,8)} | Acc: ${result?.account} | SendDisabled: ${result?.sendDisabled} | Modals: ${result?.modalCount}`);
    if (result?.modalSnippet?.length) console.log('   Modals:', result.modalSnippet);
  }
}
test().catch(console.error);
