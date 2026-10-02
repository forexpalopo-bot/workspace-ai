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
            method: 'Page.captureScreenshot',
            params: { format: 'png' }
        }));
    };
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            const buf = Buffer.from(data.result.data, 'base64');
            fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\chrome_debug_screen.png', buf);
            console.log('Saved screenshot to research/chrome_debug_screen.png');
            ws.close();
            process.exit(0);
        }
    };
}
main().catch(console.error);
