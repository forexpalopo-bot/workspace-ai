const fs = require('fs');

async function main() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  const tabs = all.filter(t => t.type === 'page' && t.url && t.url.includes('claude.ai'));
  
  for (const t of tabs) {
    if (t.url.includes('/chat/')) {
      console.log(`\n=== Membaca Chat di Tab [${t.id.slice(0, 8)}] (${t.title}) ===`);
      const text = await new Promise((resolve) => {
        const ws = new WebSocket(t.webSocketDebuggerUrl);
        const timer = setTimeout(() => { ws.close(); resolve('Timeout'); }, 5000);
        ws.onopen = () => {
          ws.send(JSON.stringify({
            id: 1,
            method: 'Runtime.evaluate',
            params: {
              returnByValue: true,
              expression: `(() => {
                const assistants = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message');
                if (assistants.length > 0) {
                  return assistants[assistants.length - 1].innerText;
                }
                const pms = document.querySelectorAll('.font-user-message');
                return 'Hanya ada user messages, belum ada balasan assistant.';
              })()`
            }
          }));
        };
        ws.onmessage = (e) => {
          clearTimeout(timer);
          const data = JSON.parse(e.data);
          ws.close();
          resolve(data.result?.result?.value || 'Error reading');
        };
      });
      console.log('Panjang teks:', text.length);
      console.log(text.slice(0, 1500));
      fs.writeFileSync('research/claude_briefing_response_full.txt', text, 'utf-8');
    }
  }
}

main().catch(console.error);
