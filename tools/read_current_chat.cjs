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
                expression: `(() => {
                    const stopBtn = document.querySelector('button[aria-label*="Stop"], button[data-testid*="stop"]');
                    const allMsgs = Array.from(document.querySelectorAll('[data-is-streaming], [data-message-author-role], .prose, .font-claude-message'));
                    
                    // Also look for specific Claude response elements
                    const assistantContainers = Array.from(document.querySelectorAll('[data-message-author-role="assistant"]'));
                    
                    return {
                        url: window.location.href,
                        title: document.title,
                        isStreaming: !!stopBtn,
                        containersFound: assistantContainers.length,
                        assistantText: assistantContainers.map(c => c.innerText.trim()),
                        bodyTextSnippet: document.body.innerText.substring(document.body.innerText.length - 2000)
                    };
                })()`,
                returnByValue: true
            }
        }));
    };
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            const val = data.result?.result?.value;
            console.log('STATUS:', JSON.stringify({
                url: val?.url,
                title: val?.title,
                isStreaming: val?.isStreaming,
                containersFound: val?.containersFound
            }, null, 2));
            
            if (val?.assistantText?.length > 0) {
                console.log('--- ASSISTANT TEXT ---');
                val.assistantText.forEach((t, i) => {
                    console.log(`[Assistant #${i} Length: ${t.length}]:`);
                    console.log(t.substring(0, 300) + '...');
                });
                fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_response_v94.txt', val.assistantText.join('\n\n---\n\n'), 'utf-8');
                console.log('Saved to research/claude_response_v94.txt');
            } else {
                console.log('--- BODY SNIPPET ---');
                console.log(val?.bodyTextSnippet);
            }
            ws.close();
            process.exit(0);
        }
    };
}
main().catch(console.error);
