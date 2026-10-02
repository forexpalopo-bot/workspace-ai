const fs = require('fs');

async function main() {
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    const claudeTarget = targets.find(t => t.url && t.url.includes('claude.ai'));
    if (!claudeTarget) return;

    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    ws.onopen = () => {
        // Query Network.getCookies
        ws.send(JSON.stringify({
            id: 1,
            method: 'Network.getCookies',
            params: { urls: ['https://claude.ai'] }
        }));
    };
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            const cookies = data.result?.cookies || [];
            console.log('Cookies for claude.ai count:', cookies.length);
            cookies.forEach(c => console.log(`- ${c.name}: ${c.domain}`));
            ws.close();
            process.exit(0);
        }
    };
}
main().catch(console.error);
