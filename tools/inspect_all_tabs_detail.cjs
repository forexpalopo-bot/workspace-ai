const fs = require('fs');

async function main() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  const tabs = all.filter(t => t.type === 'page' && t.url && t.url.includes('claude.ai'));
  
  for (let i = 0; i < tabs.length; i++) {
    const t = tabs[i];
    const info = await new Promise((resolve) => {
      const ws = new WebSocket(t.webSocketDebuggerUrl);
      const timer = setTimeout(() => { ws.close(); resolve({ error: 'timeout' }); }, 4000);
      ws.onopen = () => {
        ws.send(JSON.stringify({
          id: 1,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `(() => {
              const body = document.body.innerText || '';
              const sendBtn = document.querySelector('button[aria-label*="Send"], button[data-testid*="send"], button[aria-label*="Kirim"]');
              const stopBtn = document.querySelector('button[aria-label*="Stop"], button[data-testid*="stop"]');
              const limit = body.includes('out of free messages') || body.includes('message limit');
              const assistantMsgs = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message');
              return {
                title: document.title,
                url: window.location.href,
                hasSendBtn: !!sendBtn,
                sendDisabled: sendBtn ? sendBtn.disabled : null,
                isGenerating: !!stopBtn,
                isLimited: limit,
                bodySnippet: body.slice(0, 300),
                assistantCount: assistantMsgs.length,
                lastAssistant: assistantMsgs.length > 0 ? assistantMsgs[assistantMsgs.length - 1].innerText.slice(0, 300) : ''
              };
            })()`
          }
        }));
      };
      ws.onmessage = (e) => {
        clearTimeout(timer);
        const data = JSON.parse(e.data);
        ws.close();
        resolve(data.result?.result?.value || { error: 'no value' });
      };
      ws.onerror = (e) => {
        clearTimeout(timer);
        resolve({ error: 'ws error' });
      };
    });
    console.log(`\n[Tab #${i+1}] ID: ${t.id.slice(0,8)} | URL: ${info.url}`);
    console.log(`  Title: ${info.title}`);
    console.log(`  isLimited: ${info.isLimited} | isGenerating: ${info.isGenerating} | assistantCount: ${info.assistantCount}`);
    if (info.assistantCount > 0) {
      console.log(`  lastAssistant snippet: ${info.lastAssistant.slice(0, 150)}...`);
    } else {
      console.log(`  body snippet: ${info.bodySnippet.replace(/\\n/g, ' ').slice(0, 150)}...`);
    }
  }
}

main().catch(console.error);
