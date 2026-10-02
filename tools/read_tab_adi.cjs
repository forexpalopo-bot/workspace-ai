const fs = require('fs');

async function check() {
  const ts = await (await fetch('http://127.0.0.1:9222/json/list')).json();
  const t = ts.find(x => x.id.toLowerCase().startsWith('f3fb42dc'));
  if (!t) return console.log('Tab not found');
  const ws = new WebSocket(t.webSocketDebuggerUrl);
  ws.onopen = () => {
    ws.send(JSON.stringify({
      id: 1,
      method: 'Runtime.evaluate',
      params: {
        returnByValue: true,
        expression: `(() => {
          const bodyText = document.body.innerText;
          const assistants = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message, .font-claude-message');
          const msgs = Array.from(assistants).map(a => a.innerText);
          const stopBtn = document.querySelector('button[aria-label="Stop response"], button[aria-label="Hentikan respons"]');
          return {
            url: window.location.href,
            bodyLength: bodyText.length,
            isGenerating: !!stopBtn,
            assistantCount: assistants.length,
            lastAssistant: msgs[msgs.length - 1] || 'none',
            bodySnippet: bodyText.slice(-1000)
          };
        })()`
      }
    }));
  };
  ws.onmessage = (e) => {
    const data = JSON.parse(e.data);
    console.log(JSON.stringify(data.result?.result?.value, null, 2));
    ws.close();
  };
}
check().catch(console.error);
