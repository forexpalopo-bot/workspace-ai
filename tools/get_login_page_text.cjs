const fs = require('fs');

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
                expression: `document.body.innerText`,
                returnByValue: true
            }
        }));
    };
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            console.log('PAGE TEXT:\n', data.result?.result?.value);
            ws.close();
            process.exit(0);
        }
    };
}
main().catch(console.error);
