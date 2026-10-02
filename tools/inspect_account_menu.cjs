(async () => {
  const ws = new WebSocket('ws://localhost:9222/devtools/page/277B4DF55B17B583B0D396ED3D8480C0');
  ws.onopen = () => {
    ws.send(JSON.stringify({
      id: 1,
      method: 'Runtime.evaluate',
      params: {
        returnByValue: true,
        expression: `(() => {
          const btns = Array.from(document.querySelectorAll("button"));
          const idaBtn = btns.find(b => b.innerText.includes("ida"));
          if (idaBtn) { idaBtn.click(); return "Clicked ida"; }
          return "ida button not found";
        })()`
      }
    }));
  };
  ws.onmessage = (evt) => {
    const msg = JSON.parse(evt.data);
    if (msg.id === 1) {
      console.log('Step 1:', msg.result.result.value);
      setTimeout(() => {
        ws.send(JSON.stringify({
          id: 2,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `Array.from(document.querySelectorAll("div, a, button, span"))
              .map(e => e.innerText ? e.innerText.trim() : "")
              .filter(t => ["Log out", "Settings", "Switch", "Add account", "Sign out"].some(k => t.includes(k)))
              .slice(0, 10)`
          }
        }));
      }, 500);
    } else if (msg.id === 2) {
      console.log('Menu items:', msg.result.result.value);
      process.exit(0);
    }
  };
})();
