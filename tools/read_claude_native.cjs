const fs = require('fs');

async function main() {
    console.log('Connecting to ChromeDebug on port 9222...');
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    
    const claudeTarget = targets.find(t => t.url && (t.url.includes('claude.ai') || t.title.includes('Claude')));
    if (!claudeTarget) {
        console.log('Claude page not found in active targets:');
        targets.forEach(t => console.log(`- [${t.type}] ${t.title} (${t.url})`));
        process.exit(1);
    }
    
    console.log(`Found Claude target: ${claudeTarget.title} (${claudeTarget.url})`);
    if (claudeTarget.url.includes('/login')) {
        console.log('STATUS: Page is currently on login screen. Waiting for user login...');
        return;
    }
    
    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    
    ws.onopen = () => {
        console.log('WebSocket connected. Evaluating DOM for Claude conversation...');
        const expr = `(() => {
            const msgs = Array.from(document.querySelectorAll('.font-user-message, .font-claude-message, [data-testid="user-message"], [data-message-author-role], .prose'));
            if (msgs.length > 0) {
                return msgs.map(m => ({
                    role: m.getAttribute('data-message-author-role') || (m.className.includes('user') ? 'user' : 'claude'),
                    text: m.innerText.trim()
                }));
            }
            return [{ role: 'page', text: document.body.innerText }];
        })()`;
        
        ws.send(JSON.stringify({
            id: 1,
            method: 'Runtime.evaluate',
            params: {
                expression: expr,
                returnByValue: true
            }
        }));
    };
    
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            const result = data.result?.result?.value;
            console.log('Extracted messages count:', Array.isArray(result) ? result.length : 'non-array');
            const outputPath = 'C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_page_content.json';
            fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), 'utf-8');
            console.log(`Saved conversation to ${outputPath}`);
            ws.close();
            process.exit(0);
        }
    };
    
    ws.onerror = (err) => {
        console.error('WebSocket error:', err);
    };
}

main().catch(console.error);
