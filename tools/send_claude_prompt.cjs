const fs = require('fs');

const masterPrompt = fs.readFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\master_prompt_for_claude.txt', 'utf-8');

async function main() {
    console.log('Connecting to ChromeDebug on port 9222...');
    const res = await fetch('http://127.0.0.1:9222/json');
    const targets = await res.json();
    const claudeTarget = targets.find(t => t.url && t.url.includes('claude.ai'));
    if (!claudeTarget) {
        console.error('Claude tab not found!');
        process.exit(1);
    }
    
    console.log('Target found:', claudeTarget.title, claudeTarget.url);
    const ws = new WebSocket(claudeTarget.webSocketDebuggerUrl);
    
    ws.onopen = () => {
        console.log('WebSocket open. Typing prompt into editor...');
        ws.send(JSON.stringify({
            id: 1,
            method: 'Runtime.evaluate',
            params: {
                expression: `((text) => {
                    const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
                    if (!editor) return { success: false, error: 'Editor element not found' };
                    editor.focus();
                    
                    const dt = new DataTransfer();
                    dt.setData('text/plain', text);
                    const pasteEvent = new ClipboardEvent('paste', {
                        clipboardData: dt,
                        bubbles: true,
                        cancelable: true
                    });
                    editor.dispatchEvent(pasteEvent);
                    
                    if (!editor.innerText.trim()) {
                        document.execCommand('insertText', false, text);
                    }
                    
                    const sendBtn = document.querySelector('button[data-testid="chat-input-send"]');
                    return {
                        success: true,
                        textLength: editor.innerText.length,
                        sendBtnFound: !!sendBtn,
                        sendBtnDisabled: sendBtn ? sendBtn.disabled : null
                    };
                })(${JSON.stringify(masterPrompt)})`,
                returnByValue: true
            }
        }));
    };
    
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
            console.log('INPUT RESULT:', JSON.stringify(data.result?.result?.value, null, 2));
            
            console.log('Waiting 1.5s before clicking Send...');
            setTimeout(() => {
                ws.send(JSON.stringify({
                    id: 2,
                    method: 'Runtime.evaluate',
                    params: {
                        expression: `(() => {
                            const sendBtn = document.querySelector('button[data-testid="chat-input-send"]');
                            if (!sendBtn) return { success: false, error: 'Send button not found' };
                            if (sendBtn.disabled) return { success: false, error: 'Send button is disabled' };
                            sendBtn.click();
                            return { success: true, clicked: true };
                        })()`,
                        returnByValue: true
                    }
                }));
            }, 1500);
        } else if (data.id === 2) {
            console.log('CLICK RESULT:', JSON.stringify(data.result?.result?.value, null, 2));
            console.log('Prompt successfully submitted to Claude! Monitoring response...');
            
            // Poll for completion
            let pollCount = 0;
            const pollInterval = setInterval(() => {
                pollCount++;
                ws.send(JSON.stringify({
                    id: 100 + pollCount,
                    method: 'Runtime.evaluate',
                    params: {
                        expression: `(() => {
                            const stopBtn = document.querySelector('button[aria-label="Stop Response"], button[data-testid="stop-button"], button[aria-label*="Stop"]');
                            const isGenerating = !!stopBtn;
                            
                            const msgs = Array.from(document.querySelectorAll('.font-claude-message, [data-message-author-role="assistant"], .prose'));
                            const lastMsg = msgs.length > 0 ? msgs[msgs.length - 1].innerText.trim() : '';
                            
                            return {
                                isGenerating,
                                messageCount: msgs.length,
                                lastMsgLength: lastMsg.length,
                                lastMsgSnippet: lastMsg.substring(0, 150),
                                fullText: lastMsg
                            };
                        })()`,
                        returnByValue: true
                    }
                }));
            }, 4000);
            
            ws.onmessage = (pollEv) => {
                const pdata = JSON.parse(pollEv.data);
                if (pdata.id > 100) {
                    const res = pdata.result?.result?.value;
                    if (res) {
                        console.log(`[Poll #${pdata.id - 100}] Generating: ${res.isGenerating}, Msgs: ${res.messageCount}, Last length: ${res.lastMsgLength}`);
                        if (!res.isGenerating && res.lastMsgLength > 200) {
                            console.log('=== CLAUDE FINISHED GENERATING! ===');
                            clearInterval(pollInterval);
                            fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_response_v94.txt', res.fullText, 'utf-8');
                            console.log('Saved response to research/claude_response_v94.txt');
                            setTimeout(() => {
                                ws.close();
                                process.exit(0);
                            }, 1000);
                        }
                    }
                }
            };
            
            // Safety timeout after 3 minutes
            setTimeout(() => {
                console.log('Maximum polling time reached.');
                clearInterval(pollInterval);
                ws.close();
                process.exit(0);
            }, 180000);
        }
    };
}

main().catch(console.error);
