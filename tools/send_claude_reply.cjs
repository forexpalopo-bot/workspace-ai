const { spawn } = require('child_process');
const fs = require('fs');

const replyText = fs.readFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\reply_to_claude.txt', 'utf-8');

const activePortContent = fs.readFileSync('C:\\Users\\DELL\\AppData\\Local\\Google\\Chrome\\User Data\\DevToolsActivePort', 'utf-8').trim().split(/\r?\n/);
const port = activePortContent[0];
const wsPath = activePortContent[1];
const wsEndpoint = `ws://127.0.0.1:${port}${wsPath}`;

const mcpScript = 'C:\\Users\\DELL\\AppData\\Roaming\\npm\\node_modules\\chrome-devtools-mcp\\build\\src\\bin\\chrome-devtools-mcp.js';
const proc = spawn('node', [mcpScript, `--wsEndpoint=${wsEndpoint}`, '--no-usage-statistics'], {
    stdio: ['pipe', 'pipe', 'pipe']
});

let buffer = '';

proc.stdout.on('data', (data) => {
    buffer += data.toString();
    const lines = buffer.split('\n');
    buffer = lines.pop();
    for (const line of lines) {
        if (!line.trim()) continue;
        try {
            const msg = JSON.parse(line.trim());
            handleMessage(msg);
        } catch (e) {}
    }
});

let reqId = 1;
function sendRequest(method, params = {}) {
    const id = reqId++;
    const msg = { jsonrpc: '2.0', id, method, params };
    proc.stdin.write(JSON.stringify(msg) + '\n');
    return id;
}

function sendNotification(method, params = {}) {
    const msg = { jsonrpc: '2.0', method, params };
    proc.stdin.write(JSON.stringify(msg) + '\n');
}

let initId = sendRequest('initialize', {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'claude-replier', version: '1.0' }
});

let toolsListId, typeScriptId, sendClickId;

function handleMessage(msg) {
    if (msg.id === initId) {
        sendNotification('notifications/initialized');
        toolsListId = sendRequest('tools/list');
    } else if (msg.id === toolsListId) {
        console.log('Inserting text into ProseMirror...');
        typeScriptId = sendRequest('tools/call', {
            name: 'evaluate_script',
            arguments: {
                pageId: 1,
                function: `(text) => {
                    const editor = document.querySelector('.ProseMirror');
                    if (!editor) return { success: false, error: 'Editor not found' };
                    editor.focus();
                    
                    // Paste or insert text
                    // TipTap handles input via DataTransfer or execCommand
                    const dataTransfer = new DataTransfer();
                    dataTransfer.setData('text/plain', text);
                    const pasteEvent = new ClipboardEvent('paste', {
                        clipboardData: dataTransfer,
                        bubbles: true,
                        cancelable: true
                    });
                    editor.dispatchEvent(pasteEvent);
                    
                    // Fallback if paste did not fill text
                    if (!editor.innerText.trim()) {
                        document.execCommand('insertText', false, text);
                    }
                    
                    const sendBtn = document.querySelector('button[data-testid="chat-input-send"]');
                    return {
                        success: true,
                        editorLength: editor.innerText.length,
                        sendBtnDisabled: sendBtn ? sendBtn.disabled : null
                    };
                }`,
                args: [replyText]
            }
        });
    } else if (msg.id === typeScriptId) {
        console.log('TYPE RESULT:', JSON.stringify(msg.result, null, 2));
        
        // Wait 1 second then click send button
        setTimeout(() => {
            console.log('Clicking send button...');
            sendClickId = sendRequest('tools/call', {
                name: 'evaluate_script',
                arguments: {
                    pageId: 1,
                    function: `() => {
                        const sendBtn = document.querySelector('button[data-testid="chat-input-send"]');
                        if (!sendBtn) return { success: false, error: 'Send button not found' };
                        if (sendBtn.disabled) return { success: false, error: 'Send button is disabled' };
                        sendBtn.click();
                        return { success: true, clicked: true };
                    }`
                }
            });
        }, 1200);
    } else if (msg.id === sendClickId) {
        console.log('SEND CLICK RESULT:', JSON.stringify(msg.result, null, 2));
        setTimeout(() => proc.kill(), 2000);
    }
}

setTimeout(() => proc.kill(), 20000);
