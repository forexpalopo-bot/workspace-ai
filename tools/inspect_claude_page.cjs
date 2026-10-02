const fs = require('fs');

async function main() {
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    const claudeTarget = targets.find(t => t.url && t.url.includes('claude.ai'));
    if (!claudeTarget) {
        console.log('No Claude target found');
        return;
    }
    
    console.log('Connecting to Claude page:', claudeTarget.title, claudeTarget.url);
    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    
    ws.onopen = () => {
        ws.send(JSON.stringify({
            id: 1,
            method: 'Runtime.evaluate',
            params: {
                expression: `(() => {
                    const editor = document.querySelector('.ProseMirror, textarea, [contenteditable="true"]');
                    const recentChats = Array.from(document.querySelectorAll('a[href*="/chat/"]')).map(a => ({
                        title: a.innerText.trim(),
                        href: a.href
                    }));
                    const modelBtn = document.querySelector('button[aria-haspopup="menu"]');
                    return {
                        url: window.location.href,
                        title: document.title,
                        hasEditor: !!editor,
                        editorSelector: editor ? editor.className : null,
                        recentChatsCount: recentChats.length,
                        recentChats: recentChats.slice(0, 5),
                        modelButton: modelBtn ? modelBtn.innerText.trim() : null
                    };
                })()`,
                returnByValue: true
            }
        }));
    };
    
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            console.log('CLAUDE PAGE INSPECTION:');
            console.log(JSON.stringify(data.result?.result?.value, null, 2));
            ws.close();
            process.exit(0);
        }
    };
}

main().catch(console.error);
