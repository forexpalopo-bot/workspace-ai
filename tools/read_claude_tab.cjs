const { spawn } = require('child_process');
const fs = require('fs');

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
    clientInfo: { name: 'claude-reader', version: '1.0' }
});

let toolsListId, scriptId;

function handleMessage(msg) {
    if (msg.id === initId) {
        sendNotification('notifications/initialized');
        toolsListId = sendRequest('tools/list');
    } else if (msg.id === toolsListId) {
        // Read text of the conversation in the page using evaluate_script
        scriptId = sendRequest('tools/call', {
            name: 'evaluate_script',
            arguments: {
                pageId: 1,
                function: `() => {
                    const messages = Array.from(document.querySelectorAll('.font-user-message, .font-claude-message, [data-testid="user-message"], [data-message-author-role], .prose'));
                    if (messages.length > 0) {
                        return messages.map(m => ({
                            role: m.getAttribute('data-message-author-role') || (m.className.includes('user') ? 'user' : 'claude'),
                            text: m.innerText.trim()
                        }));
                    }
                    // Fallback to body innerText
                    return [{ role: 'page', text: document.body.innerText }];
                }`
            }
        });
    } else if (msg.id === scriptId) {
        console.log('--- CONVERSATION IN CLAUDE BROWSER ---');
        const res = msg.result;
        fs.writeFileSync('C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_page_content.json', JSON.stringify(res, null, 2), 'utf-8');
        console.log('Saved to research/claude_page_content.json');
        setTimeout(() => proc.kill(), 1000);
    }
}

setTimeout(() => {
    console.log('Timeout');
    proc.kill();
}, 20000);
