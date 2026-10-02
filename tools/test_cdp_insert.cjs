async function main() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  // Gunakan tab ihwan atau acoku (Tab 4 atau 5)
  const t = all.find(x => x.id.startsWith('118342B3') || x.id.startsWith('11301708'));
  console.log('Testing native CDP on:', t.title, t.url);
  const ws = new WebSocket(t.webSocketDebuggerUrl);

  ws.onopen = () => {
    // 1. Focus editor
    ws.send(JSON.stringify({
      id: 1,
      method: 'Runtime.evaluate',
      params: {
        returnByValue: true,
        expression: `(() => {
          const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
          if (editor) { editor.focus(); return true; }
          return false;
        })()`
      }
    }));
  };

  ws.onmessage = (e) => {
    const d = JSON.parse(e.data);
    if (d.id === 1) {
      console.log('Focused editor:', d.result?.result?.value);
      // 2. Native CDP Insert Text!
      ws.send(JSON.stringify({
        id: 2,
        method: 'Input.insertText',
        params: { text: 'Halo Claude, tes integrasi CDP.' }
      }));
    } else if (d.id === 2) {
      console.log('Inserted text via CDP.');
      setTimeout(() => {
        // 3. Check send button
        ws.send(JSON.stringify({
          id: 3,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `(() => {
              const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Kirim"], button[aria-label*="Send"]');
              const editor = document.querySelector('.ProseMirror');
              return {
                editorText: editor ? editor.innerText : '',
                sendDisabled: sendBtn ? sendBtn.disabled : 'not found'
              };
            })()`
          }
        }));
      }, 500);
    } else if (d.id === 3) {
      console.log('RESULT:', d.result?.result?.value);
      ws.close();
    }
  };
}
main().catch(console.error);
