const { getClaudeTabs } = require('./claude_multitab_coordinator.cjs');

async function test() {
  const tabs = await getClaudeTabs();
  const t = tabs[0];
  console.log('Inspecting tab:', t.title, t.url);
  const ws = new WebSocket(t.webSocketDebuggerUrl);
  ws.onopen = () => {
    ws.send(JSON.stringify({
      id: 1,
      method: 'Runtime.evaluate',
      params: {
        returnByValue: true,
        expression: `(() => {
          const btns = Array.from(document.querySelectorAll('button'));
          const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
          return {
            editorFound: !!editor,
            editorText: editor ? editor.innerText.slice(0, 100) : '',
            buttons: btns.map(b => ({
              label: b.getAttribute('aria-label'),
              testId: b.getAttribute('data-testid'),
              text: b.innerText,
              disabled: b.disabled
            })).filter(b => b.testId || b.label || (b.text && b.text.length < 25))
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
test().catch(console.error);
