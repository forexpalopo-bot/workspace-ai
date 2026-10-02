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
                    
                    // Collect all assistant turns or text blocks
                    // In Claude web, assistant responses are in containers
                    // Let's get the entire text of the chat conversation:
                    const chatRoot = document.querySelector('main') || document.body;
                    return {
                        isStreaming: !!stopBtn,
                        fullText: chatRoot.innerText
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
            console.log('Is Streaming:', val?.isStreaming);
            console.log('Total text length:', val?.fullText?.length);
            
            const fullText = val?.fullText || '';
            fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_chat_full_raw.txt', fullText, 'utf-8');
            console.log('Saved raw chat to research/claude_chat_full_raw.txt');
            
            // Try to split user prompt and assistant response
            // The prompt started with "# KOLABORASI RISET INSTITUSIONAL BIOONEPRO"
            const marker = "Mohon arahan kuantitatif dan formula usulan Anda untuk kita implementasikan ke dalam pengujian v94!";
            const idx = fullText.indexOf(marker);
            if (idx !== -1) {
                const claudeResponse = fullText.substring(idx + marker.length).trim();
                console.log('Claude response length:', claudeResponse.length);
                fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_response_v94.txt', claudeResponse, 'utf-8');
                console.log('Saved clean response to research/claude_response_v94.txt');
            }
            
            ws.close();
            process.exit(0);
        }
    };
}
main().catch(console.error);
