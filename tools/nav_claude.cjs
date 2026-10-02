const fs = require('fs');

async function main() {
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    const claudeTarget = targets.find(t => t.url && (t.url.includes('claude.ai') || t.title.includes('Claude')));
    if (!claudeTarget) {
        console.log('No Claude target found');
        return;
    }
    
    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    ws.onopen = () => {
        // Send Page.navigate
        ws.send(JSON.stringify({
            id: 1,
            method: 'Page.navigate',
            params: { url: 'https://claude.ai/chat/b87a9d83-732b-424b-80ff-d27c8fc2ecc3' }
        }));
    };
    
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        console.log('RECV:', JSON.stringify(data));
        setTimeout(() => {
            ws.close();
            process.exit(0);
        }, 3000);
    };
}
main().catch(console.error);
