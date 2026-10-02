const fs = require('fs');

const promptText = fs.readFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\master_briefing_for_claude.md', 'utf-8');

async function main() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  const tabs = all.filter(t => t.type === 'page' && t.url && t.url.includes('claude.ai'));

  // Ambil tab pertama yang ready dan tidak limited
  let targetTab = null;
  for (const t of tabs) {
    const ws = new WebSocket(t.webSocketDebuggerUrl);
    const body = await new Promise((resolve) => {
      const tm = setTimeout(() => { ws.close(); resolve(''); }, 3000);
      ws.onopen = () => {
        ws.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { returnByValue: true, expression: 'document.body.innerText' } }));
      };
      ws.onmessage = (e) => {
        clearTimeout(tm);
        const data = JSON.parse(e.data);
        ws.close();
        resolve(data.result?.result?.value || '');
      };
    });
    if (!body.includes('out of free messages') && !body.includes('message limit until') && !body.includes('limit reached')) {
      targetTab = t;
      break;
    }
  }

  if (!targetTab) {
    console.error('Tidak ada tab Claude yang siap!');
    return;
  }

  console.log(`Menggunakan tab [${targetTab.id.slice(0, 8)}] (${targetTab.title})...`);

  // Kirim script untuk membersihkan modal, mengetik prompt, dan submit
  const ws = new WebSocket(targetTab.webSocketDebuggerUrl);
  ws.onopen = () => {
    ws.send(JSON.stringify({
      id: 10,
      method: 'Runtime.evaluate',
      params: {
        returnByValue: true,
        expression: `((text) => {
          // 1. Tutup modal/promo jika ada
          const closeBtns = Array.from(document.querySelectorAll('button')).filter(b => 
            b.innerText.includes('Nanti saja') || 
            b.innerText.includes('Dismiss') || 
            b.getAttribute('aria-label') === 'Tutup' ||
            b.getAttribute('aria-label') === 'Close'
          );
          closeBtns.forEach(b => { try { b.click(); } catch(e){} });

          // 2. Bersihkan editor
          const editor = document.querySelector('div.ProseMirror, [contenteditable="true"]');
          if (!editor) return { success: false, error: 'Editor tidak ditemukan' };
          editor.focus();
          editor.innerHTML = '<p></p>';

          // 3. Paste prompt bersih
          const dt = new DataTransfer();
          dt.setData('text/plain', text);
          const pasteEvent = new ClipboardEvent('paste', {
            clipboardData: dt,
            bubbles: true,
            cancelable: true
          });
          editor.dispatchEvent(pasteEvent);

          return { success: true };
        })(${JSON.stringify(promptText)})`
      }
    }));
  };

  ws.onmessage = (e) => {
    const data = JSON.parse(e.data);
    if (data.id === 10) {
      console.log('Paste result:', data.result?.result?.value);
      console.log('Menunggu 1.5 detik sebelum submit...');
      setTimeout(() => {
        ws.send(JSON.stringify({
          id: 20,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `(() => {
              const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Kirim"], button[aria-label*="Send"]');
              if (!sendBtn) return { success: false, error: 'Tombol send tidak ada' };
              if (sendBtn.disabled) return { success: false, error: 'Tombol send disabled' };
              sendBtn.click();
              return { success: true };
            })()`
          }
        }));
      }, 1500);
    } else if (data.id === 20) {
      console.log('Click result:', data.result?.result?.value);
      console.log('Prompt terkirim! Memantau streaming respons Claude...');

      let checkInterval = setInterval(() => {
        ws.send(JSON.stringify({
          id: 30,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `(() => {
              const stopBtn = document.querySelector('button[aria-label*="Stop"], button[data-testid*="stop"]');
              const assts = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message');
              const body = document.body.innerText || '';
              const isLimited = body.includes('out of free messages') || body.includes('message limit');
              const lastText = assts.length > 0 ? assts[assts.length - 1].innerText : '';
              return {
                isGenerating: !!stopBtn,
                asstCount: assts.length,
                textLength: lastText.length,
                lastSnippet: lastText.slice(-200),
                isLimited
              };
            })()`
          }
        }));
      }, 3000);

      let prevLen = 0;
      let stableCount = 0;

      ws.onmessage = (evt) => {
        const d = JSON.parse(evt.data);
        if (d.id === 30) {
          const val = d.result?.result?.value;
          if (!val) return;
          if (val.isLimited) {
            clearInterval(checkInterval);
            console.log('\n[LIMIT] Akun limit kuota.');
            ws.close();
            return;
          }
          process.stdout.write(`\r[Streaming] Panjang: ${val.textLength} chars | Generating: ${val.isGenerating}`);
          if (val.textLength > 100 && !val.isGenerating) {
            stableCount++;
            if (stableCount >= 2) {
              clearInterval(checkInterval);
              console.log('\n[SELESAI] Claude selesai merespons!');
              
              // Ambil teks lengkap
              ws.send(JSON.stringify({
                id: 40,
                method: 'Runtime.evaluate',
                params: {
                  returnByValue: true,
                  expression: `(() => {
                    const assts = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message');
                    return assts.length > 0 ? assts[assts.length - 1].innerText : document.body.innerText;
                  })()`
                }
              }));
            }
          } else {
            stableCount = 0;
          }
        } else if (d.id === 40) {
          const text = d.result?.result?.value;
          fs.writeFileSync('research/claude_briefing_response_full.txt', text, 'utf-8');
          console.log(`Teks disimpan (${text.length} chars) ke: research/claude_briefing_response_full.txt`);
          ws.close();
        }
      };
    }
  };
}

main().catch(console.error);
