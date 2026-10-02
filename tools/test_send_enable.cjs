async function main() {
  const res = await fetch('http://127.0.0.1:9222/json/list');
  const all = await res.json();
  const t = all.find(x => x.id.startsWith('F3FB42DC'));
  const ws = new WebSocket(t.webSocketDebuggerUrl);

  ws.onopen = () => {
    ws.send(JSON.stringify({
      id: 1,
      method: 'Runtime.evaluate',
      params: {
        returnByValue: true,
        expression: `(() => {
          const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
          editor.focus();
          
          // Masukkan 1 spasi atau karakter
          document.execCommand('insertText', false, ' ');
          editor.dispatchEvent(new Event('input', { bubbles: true }));
          
          const sendBtn = document.querySelector('button[data-testid="chat-input-send"]');
          return {
            editorText: editor.innerText.slice(0, 100),
            sendBtnDisabled: sendBtn ? sendBtn.disabled : 'not found'
          };
        })()`
      }
    }));
  };

  ws.onmessage = (e) => {
    console.log('HASIL:', JSON.parse(e.data).result?.result?.value);
    ws.close();
  };
}
main().catch(console.error);
