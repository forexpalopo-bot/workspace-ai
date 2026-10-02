const fs = require('fs');

async function main() {
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    const claudeTarget = targets.find(t => t.url && t.url.includes('claude.ai'));
    if (!claudeTarget) return;

    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    ws.onopen = () => {
        console.log('Navigating to chat b87a9d83-732b-424b-80ff-d27c8fc2ecc3...');
        ws.send(JSON.stringify({
            id: 1,
            method: 'Page.navigate',
            params: { url: 'https://claude.ai/chat/b87a9d83-732b-424b-80ff-d27c8fc2ecc3' }
        }));
    };
    
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            console.log('Navigated, waiting 4s for content to render...');
            setTimeout(() => {
                ws.send(JSON.stringify({
                    id: 2,
                    method: 'Runtime.evaluate',
                    params: {
                        expression: `(() => {
                            const msgs = Array.from(document.querySelectorAll('.font-user-message, .font-claude-message, [data-testid="user-message"], [data-message-author-role], .prose'));
                            return {
                                url: window.location.href,
                                title: document.title,
                                messageCount: msgs.length,
                                messages: msgs.map(m => ({
                                    role: m.getAttribute('data-message-author-role') || (m.className.includes('user') ? 'user' : 'claude'),
                                    text: m.innerText.trim()
                                }))
                            };
                        })()`,
                        returnByValue: true
                    }
                }));
            }, 4000);
        } else if (data.id === 2) {
            const val = data.result?.result?.value;
            console.log('RESULT: URL =', val?.url, 'Title =', val?.title, 'Message count =', val?.messageCount);
            if (val?.messages?.length > 0) {
                fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_page_content.json', JSON.stringify(val.messages, null, 2), 'utf-8');
                console.log('Saved messages to research/claude_page_content.json');
            }
            ws.close();
            process.exit(0);
        }
    };
}

main().catch(console.error);
