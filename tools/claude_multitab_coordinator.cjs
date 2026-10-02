/**
 * Multi-Tab Auto-Failover Coordinator for Claude.ai in ChromeDebug
 * Menangani pengiriman prompt ke Claude dan otomatis beralih ke tab akun lain jika akun saat ini limit kuota token AI.
 */
const fs = require('fs');
const path = require('path');

const PORT = 9222;

async function getClaudeTabs() {
  try {
    const res = await fetch(`http://127.0.0.1:${PORT}/json/list`);
    const all = await res.json();
    return all.filter(t => t.type === 'page' && t.url && t.url.includes('claude.ai'));
  } catch (e) {
    throw new Error(`Tidak dapat terhubung ke ChromeDebug di port ${PORT}: ${e.message}`);
  }
}

function cdpEval(wsUrl, expression) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve({ error: 'CDP timeout' });
    }, 8000);

    ws.onopen = () => {
      ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: {
          returnByValue: true,
          expression: expression
        }
      }));
    };

    ws.onmessage = (evt) => {
      clearTimeout(timer);
      try {
        const msg = JSON.parse(evt.data);
        ws.close();
        if (msg.error) return resolve({ error: msg.error.message });
        if (msg.result && msg.result.exceptionDetails) {
          const detail = msg.result.exceptionDetails;
          return resolve({ error: detail.exception?.description || detail.text || 'Exception in script' });
        }
        resolve(msg.result?.result?.value);
      } catch (err) {
        resolve({ error: err.message });
      }
    };

    ws.onerror = (err) => {
      clearTimeout(timer);
      resolve({ error: err.message });
    };
  });
}

function cdpNavigate(wsUrl, url) {
  return new Promise((resolve) => {
    const ws = new WebSocket(wsUrl);
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve(false);
    }, 10000);

    ws.onopen = () => {
      ws.send(JSON.stringify({
        id: 2,
        method: 'Page.navigate',
        params: { url: url }
      }));
    };

    ws.onmessage = () => {
      clearTimeout(timer);
      try { ws.close(); } catch(e){}
      resolve(true);
    };

    ws.onerror = () => {
      clearTimeout(timer);
      resolve(false);
    };
  });
}

function cdpNativeInsert(wsUrl, text) {
  return new Promise((resolve) => {
    const ws = new WebSocket(wsUrl);
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve(false);
    }, 15000);

    ws.onopen = () => {
      // 1. Focus editor and dismiss modals
      ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: {
          returnByValue: true,
          expression: `(() => {
            const modals = Array.from(document.querySelectorAll('button')).filter(b => 
              b.innerText.includes('Nanti saja') || b.innerText.includes('Dismiss') || b.getAttribute('aria-label') === 'Tutup'
            );
            modals.forEach(m => { try { m.click(); } catch(e){} });
            const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
            if (editor) {
              editor.focus();
              editor.innerHTML = '<p></p>';
              return true;
            }
            return false;
          })()`
        }
      }));
    };

    ws.onmessage = (evt) => {
      const msg = JSON.parse(evt.data);
      if (msg.id === 1) {
        // 2. Insert text via native CDP
        ws.send(JSON.stringify({
          id: 2,
          method: 'Input.insertText',
          params: { text: text }
        }));
      } else if (msg.id === 2) {
        clearTimeout(timer);
        try { ws.close(); } catch(e){}
        resolve(true);
      }
    };

    ws.onerror = () => {
      clearTimeout(timer);
      resolve(false);
    };
  });
}

async function inspectTabStatus(tab) {
  const code = `
    (() => {
      try {
        const bodyText = document.body.innerText || '';
        const btns = Array.from(document.querySelectorAll('button'));
        const pm = document.querySelector('div.ProseMirror, [contenteditable="true"]');
        const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');
        const stopBtn = document.querySelector('button[aria-label*="Stop"], button[data-testid*="stop"]');

        const isLoginPage = location.pathname.startsWith('/login') || bodyText.includes('Continue with Google');

        // Deteksi limit kuota (Bilingual: English & Indonesian)
        const limitKeys = [
          'out of free messages',
          'message limit until',
          'limit reached until',
          'resets at',
          'usage limit reached',
          '5-hour message limit',
          'hit your',
          'telah mencapai batas pesan',
          'upgrade untuk terus mengobrol',
          'upgrade to keep chatting',
          'batas pesan claude',
          'kembali pada pukul',
          'coba lagi pada pukul',
          'mencapai batas'
        ];
        const isLimited = limitKeys.some(k => bodyText.toLowerCase().includes(k));
        let limitMsg = null;
        if (isLimited) {
          const lines = bodyText.split(String.fromCharCode(10));
          limitMsg = lines.find(l => limitKeys.some(k => l.toLowerCase().includes(k))) || 'Token AI Limit';
        }

        // Cari identitas akun
        let accountName = 'Unknown';
        const userBtn = btns.find(b => b.innerText && (b.innerText.includes('·') || b.innerText.includes('Free') || b.innerText.includes('Pro')));
        if (userBtn) {
          accountName = userBtn.innerText.split(String.fromCharCode(10)).join(' ').trim();
        }

        return {
          id: '${tab.id}',
          title: document.title,
          url: location.href,
          accountName: accountName,
          isLoggedIn: !isLoginPage,
          canType: !!pm,
          isLimited: isLimited,
          limitMessage: limitMsg,
          isStreaming: !!stopBtn,
          sendBtnDisabled: sendBtn ? sendBtn.disabled : null
        };
      } catch(e) {
        return { error: e.message };
      }
    })()
  `;

  return await cdpEval(tab.webSocketDebuggerUrl, code);
}

async function sendPromptToTab(tab, promptText) {
  console.log(`[PENGIRIMAN] Mengirim prompt ke tab [${tab.id.slice(0, 8)}] (${tab.accountName || 'Claude'})...`);

  // Bawa tab ke depan
  try {
    const ws = new WebSocket(tab.webSocketDebuggerUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({ id: 99, method: 'Page.bringToFront' }));
      setTimeout(() => { try { ws.close(); } catch(e){} }, 500);
    };
  } catch(e){}

  // Pengetikan native CDP ke ProseMirror
  const inserted = await cdpNativeInsert(tab.webSocketDebuggerUrl, promptText);
  if (!inserted) {
    return { success: false, reason: 'insert_failed', error: 'Gagal memasukkan teks via CDP' };
  }

  // Jeda 1.2 detik lalu klik tombol send
  await new Promise(r => setTimeout(r, 1200));

  const clickCode = `
    (() => {
      try {
        const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');
        if (!sendBtn) return { success: false, error: 'Tombol send tidak ditemukan' };
        if (sendBtn.disabled) return { success: false, error: 'Tombol send disabled (mungkin kuota habis)' };
        sendBtn.click();
        return { success: true };
      } catch(e) {
        return { success: false, error: e.message };
      }
    })()
  `;

  const clickResult = await cdpEval(tab.webSocketDebuggerUrl, clickCode);
  if (!clickResult?.success) {
    return { success: false, reason: 'click_failed', error: clickResult?.error };
  }

  console.log(`[PENGIRIMAN] Tombol kirim berhasil diklik. Menunggu respons Claude...`);

  // Tunggu hingga Claude mulai menghasilkan respons atau limit muncul
  const startWait = Date.now();
  let started = false;
  while (Date.now() - startWait < 20000) {
    await new Promise(r => setTimeout(r, 1500));
    const st = await inspectTabStatus(tab);
    if (st.isLimited) {
      return { success: false, reason: 'rate_limited', limitMessage: st.limitMessage };
    }
    if (st.isStreaming) {
      started = true;
      break;
    }
    const checkAssistantCode = `
      (() => {
        const assts = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message');
        return assts.length > 0 && assts[assts.length - 1].innerText.trim().length > 10;
      })()
    `;
    const checkRes = await cdpEval(tab.webSocketDebuggerUrl, checkAssistantCode);
    if (checkRes === true) {
      started = true;
      break;
    }
  }

  if (!started) {
    return { success: false, reason: 'stream_never_started', error: 'Claude tidak mulai merespons setelah tombol kirim diklik' };
  }

  // Pantau streaming hingga selesai (maksimal 5 menit)
  const startTime = Date.now();
  const maxWaitMs = 5 * 60 * 1000;

  while (Date.now() - startTime < maxWaitMs) {
    await new Promise(r => setTimeout(r, 2000));
    const status = await inspectTabStatus(tab);

    if (status.isLimited) {
      return { success: false, reason: 'rate_limited', limitMessage: status.limitMessage };
    }

    if (!status.isStreaming) {
      // Beri jeda 2 detik untuk memastikan DOM stabil
      await new Promise(r => setTimeout(r, 2000));
      break;
    }
    process.stdout.write('.');
  }
  console.log('\n[PENGIRIMAN] Claude selesai merespons.');

  // Ekstrak teks respons terbaru dari bubble assistant
  const extractCode = `
    (() => {
      try {
        const assts = document.querySelectorAll('div[data-message-author-role="assistant"], div.font-claude-message');
        if (assts.length > 0) {
          return { fullText: assts[assts.length - 1].innerText };
        }
        const main = document.querySelector('main') || document.body;
        return { fullText: main.innerText };
      } catch(e) {
        return { error: e.message };
      }
    })()
  `;

  const extractResult = await cdpEval(tab.webSocketDebuggerUrl, extractCode);
  const text = extractResult?.fullText || '';
  if (text.length < 20) {
    return { success: false, reason: 'empty_response', error: 'Respons Claude kosong atau terlalu pendek' };
  }
  return {
    success: true,
    fullText: text
  };
}

async function saveAccountCookiesIfNew(tab, status) {
  if (!status.isLoggedIn || !status.accountName || status.accountName === 'Unknown') return;
  const accountsFile = 'C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_accounts.json';
  let db = { accounts: [] };
  if (fs.existsSync(accountsFile)) {
    try { db = JSON.parse(fs.readFileSync(accountsFile, 'utf-8')); } catch(e){}
  }
  const existing = db.accounts.find(a => a.name === status.accountName);
  if (!existing || !existing.cookies || existing.cookies.length === 0) {
    try {
      await new Promise((resolve) => {
        const ws = new WebSocket(tab.webSocketDebuggerUrl);
        const to = setTimeout(() => { try{ws.close();}catch(e){} resolve(); }, 3000);
        ws.onopen = () => {
          ws.send(JSON.stringify({ id: 999, method: 'Network.getCookies', params: { urls: ['https://claude.ai'] } }));
        };
        ws.onmessage = (evt) => {
          clearTimeout(to);
          const msg = JSON.parse(evt.data);
          if (msg.id === 999 && msg.result?.cookies) {
            const accData = {
              id: 'account_' + (db.accounts.length + 1),
              name: status.accountName,
              url: status.url,
              targetId: tab.id,
              cookies: msg.result.cookies.map(c => ({
                name: c.name,
                value: c.value,
                domain: c.domain,
                path: c.path,
                expires: c.expires,
                httpOnly: c.httpOnly,
                secure: c.secure,
                sameSite: c.sameSite
              }))
            };
            const idx = db.accounts.findIndex(a => a.name === status.accountName);
            if (idx >= 0) db.accounts[idx] = accData;
            else db.accounts.push(accData);
            fs.writeFileSync(accountsFile, JSON.stringify(db, null, 2));
            console.log(`[COOKIE AUTO-SYNC] Cookie sesi untuk akun "${status.accountName}" berhasil disimpan ke claude_accounts.json!`);
            ws.close();
            resolve();
          }
        };
        ws.onerror = () => { clearTimeout(to); resolve(); };
      });
    } catch(e){}
  }
}

async function coordinate(promptText, outputPath) {
  console.log('================================================================');
  console.log('       KOORDINATOR MULTI-TAB CLAUDE (100% AUTO FAILOVER)        ');
  console.log('================================================================');

  const tabs = await getClaudeTabs();
  console.log(`Ditemukan ${tabs.length} tab Claude di ChromeDebug.`);

  // Sesuai SOP User: Gunakan link https://claude.ai/new sebagai awal tindakan
  // untuk memastikan kondisi token terbaru dan refresh akun yang tokennya telah kembali setelah beberapa jam.
  console.log('\n[REFRESH TOKEN & PERCAKAPAN BARU] Membuka https://claude.ai/new pada seluruh tab...');
  for (const tab of tabs) {
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
  }
  await new Promise(r => setTimeout(r, 2500));

  const accountStatuses = [];
  for (const tab of tabs) {
    // Bring tab to front so Chrome does not throttle rendering
    try {
      const ws = new WebSocket(tab.webSocketDebuggerUrl);
      await new Promise((resolve) => {
        ws.onopen = () => {
          ws.send(JSON.stringify({ id: 1, method: 'Page.bringToFront' }));
          setTimeout(() => { try{ws.close();}catch(e){} resolve(); }, 800);
        };
        ws.onerror = () => resolve();
      });
    } catch(e){}
    await new Promise(r => setTimeout(r, 1000));

    const status = await inspectTabStatus(tab);
    status.webSocketDebuggerUrl = tab.webSocketDebuggerUrl;
    accountStatuses.push(status);
    await saveAccountCookiesIfNew(tab, status);
  }

  console.log('\n--- STATUS AKUN PADA TAB TERBUKA ---');
  accountStatuses.forEach((st, idx) => {
    console.log(`[Tab #${idx + 1}] ID: ${st.id.slice(0, 8)} | Akun: ${st.accountName} | LoggedIn: ${st.isLoggedIn} | CanType: ${st.canType} | Limited: ${st.isLimited}`);
    if (st.isLimited) console.log(`         Peringatan: ${st.limitMessage}`);
  });
  console.log('------------------------------------\n');

  // Cari akun yang siap digunakan
  const readyAccounts = accountStatuses.filter(st => st.isLoggedIn && st.canType && !st.isLimited);

  // Prioritaskan tab yang sudah memiliki obrolan aktif (/chat/) agar riwayat konteks tersambung
  readyAccounts.sort((a, b) => {
    const aChat = a.url && a.url.includes('/chat/') ? 1 : 0;
    const bChat = b.url && b.url.includes('/chat/') ? 1 : 0;
    return bChat - aChat;
  });

  if (readyAccounts.length === 0) {
    console.error('[PERINGATAN KRITIS] Tidak ada akun Claude yang memiliki kuota token aktif!');
    const loginTab = accountStatuses.find(st => !st.isLoggedIn);
    if (loginTab) {
      console.log(`Terdapat tab login yang terbuka: [${loginTab.id.slice(0, 8)}] (${loginTab.url}).`);
      console.log('Silakan login akun baru pada tab tersebut menggunakan tools\\open_new_account_tab.cjs.');
    }
    return { success: false, reason: 'all_accounts_exhausted' };
  }

  // Loop failover: coba akun 1, jika limit beralih ke akun 2, dst.
  for (let i = 0; i < readyAccounts.length; i++) {
    const candidate = readyAccounts[i];
    console.log(`\n>>> Mencoba Akun #${i + 1}: ${candidate.accountName} (Tab ${candidate.id.slice(0, 8)}) <<<`);

    const result = await sendPromptToTab(candidate, promptText);
    if (result.success) {
      console.log(`\n[SUKSES] Respons berhasil diperoleh dari ${candidate.accountName}!`);
      if (outputPath) {
        fs.writeFileSync(outputPath, result.fullText, 'utf-8');
        console.log(`Respons disimpan ke: ${outputPath}`);
      }
      return { success: true, accountUsed: candidate.accountName, fullText: result.fullText };
    } else {
      console.warn(`\n[FAILOVER AKTIF] Akun ${candidate.accountName} gagal: ${result.reason || result.error}`);
      if (result.reason === 'rate_limited') {
        console.warn(`Pesan limit: ${result.limitMessage}`);
        console.log(`Mengalihkan koordinasi secara otomatis ke akun berikutnya...`);
      }
    }
  }

  console.error('[SELESAI DENGAN GAGAL] Semua kandidat akun yang dicoba mengalami limit kuota.');
  return { success: false, reason: 'all_candidates_failed' };
}

// CLI Execution
async function runCLI() {
  const args = process.argv.slice(2);
  let promptText = '';
  let outputPath = 'research/claude_response_latest.txt';

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--prompt' && args[i + 1]) {
      promptText = args[i + 1];
      i++;
    } else if (args[i] === '--file' && args[i + 1]) {
      promptText = fs.readFileSync(args[i + 1], 'utf-8');
      i++;
    } else if (args[i] === '--output' && args[i + 1]) {
      outputPath = args[i + 1];
      i++;
    } else if (args[i] === '--status') {
      const tabs = await getClaudeTabs();
      console.log(`[REFRESH TOKEN] Mengecek ${tabs.length} tab via https://claude.ai/new...`);
      for (const tab of tabs) {
        await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
      }
      await new Promise(r => setTimeout(r, 2500));
      for (const tab of tabs) {
        const st = await inspectTabStatus(tab);
        console.log(`[Tab ${st.id.slice(0, 8)}] Akun: ${st.accountName} | LoggedIn: ${st.isLoggedIn} | CanType: ${st.canType} | Limited: ${st.isLimited}`);
        if (st.isLimited) console.log(`   Peringatan: ${st.limitMessage}`);
      }
      return;
    }
  }

  if (!promptText) {
    console.log('Penggunaan:');
    console.log('  node tools/claude_multitab_coordinator.cjs --status');
    console.log('  node tools/claude_multitab_coordinator.cjs --prompt "pertanyaan" [--output file.txt]');
    console.log('  node tools/claude_multitab_coordinator.cjs --file file_prompt.txt [--output file.txt]');
    return;
  }

  await coordinate(promptText, outputPath);
}

if (require.main === module) {
  runCLI().catch(console.error);
}

module.exports = { coordinate, inspectTabStatus, getClaudeTabs };
