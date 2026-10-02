async function main() {
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    const claudeTarget = targets.find(t => t.url && t.url.includes('claude.ai'));
    if (!claudeTarget) return;

    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    ws.onopen = () => {
        ws.send(JSON.stringify({
            id: 1,
            method: 'Runtime.evaluate',
            params: {
                expression: `(() => {
                    const btns = Array.from(document.querySelectorAll('button'));
                    const modelMenuBtn = btns.find(b => b.getAttribute('data-testid') === 'model-selector-dropdown' || b.innerText.includes('Sonnet') || b.innerText.includes('Opus') || b.innerText.includes('Haiku') || b.getAttribute('aria-label')?.includes('model'));
                    return {
                        modelMenuFound: !!modelMenuBtn,
                        modelMenuText: modelMenuBtn ? modelMenuBtn.innerText.trim() : null,
                        allButtons: btns.map(b => ({ text: b.innerText.trim(), testId: b.getAttribute('data-testid'), aria: b.getAttribute('aria-label') })).filter(b => b.text || b.testId || b.aria)
                    };
                })()`,
                returnByValue: true
            }
        }));
    };
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            console.log(JSON.stringify(data.result?.result?.value, null, 2));
            ws.close();
            process.exit(0);
        }
    };
}
main().catch(console.error);
