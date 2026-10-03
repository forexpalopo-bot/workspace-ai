/**
 * Multi-Tab Auto-Failover Coordinator for Claude.ai in ChromeDebug
 * Menangani pengiriman prompt ke Claude dan otomatis beralih ke tab akun lain jika akun saat ini limit kuota token AI.
 * Sesuai SOP User: Selalu utamakan kembali ke percakapan baru (https://claude.ai/new) SEBELUM memulai dan SETELAH mengakhiri komunikasi.
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

function cdpEval(wsUrl, expression, timeoutMs = 10000) {
  return new Promise((resolve) => {
    let ws;
    try {
      ws = new WebSocket(wsUrl);
    } catch(e) {
      return resolve({ error: e.message });
    }
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve({ error: 'CDP timeout' });
    }, timeoutMs);

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

function cdpNavigate(wsUrl, url, timeoutMs = 12000) {
  return new Promise((resolve) => {
    let ws;
    try {
      ws = new WebSocket(wsUrl);
    } catch(e) {
      return resolve(false);
    }
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve(false);
    }, timeoutMs);

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

/**
 * Menyiapkan tab agar 100% siap di percakapan baru (https://claude.ai/new)
 * Membersihkan modal/pop-up dan mengosongkan editor ProseMirror.
 */
async function prepareFreshChat(wsUrl, maxWaitMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    const code = `
      (() => {
        try {
          // Tutup segala macam modal/banner selamat datang/promo
          const closeSelectors = [
            'button[aria-label="Tutup"]',
            'button[aria-label="Close"]',
            'button[data-testid="modal-close-button"]'
          ];
          closeSelectors.forEach(sel => {
            document.querySelectorAll(sel).forEach(b => { try { b.click(); } catch(e){} });
          });

          const buttons = Array.from(document.querySelectorAll('button'));
          const dismissBtns = buttons.filter(b => {
            const txt = (b.innerText || '').toLowerCase();
            return txt.includes('nanti saja') || txt.includes('dismiss') || 
                   txt.includes('lewati') || txt.includes('got it') || 
                   txt.includes('mengerti') || txt === 'close';
          });
          dismissBtns.forEach(b => { try { b.click(); } catch(e){} });

          // Cari elemen editor ProseMirror
          const editor = document.querySelector('div.ProseMirror, [contenteditable="true"]');
          if (!editor) {
            return { ready: false, step: 'waiting_for_editor', url: location.href };
          }

          // Bersihkan isi editor dari draft lama jika ada
          editor.focus();
          if (editor.innerText.trim().length > 0) {
            document.execCommand('selectAll', false, null);
            document.execCommand('delete', false, null);
            editor.innerHTML = '<p></p>';
            editor.dispatchEvent(new Event('input', { bubbles: true }));
          }

          const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');

          return {
            ready: true,
            url: location.href,
            hasEditor: true,
            hasSendBtn: !!sendBtn,
            editorTextLen: editor.innerText.trim().length
          };
        } catch(e) {
          return { ready: false, error: e.message };
        }
      })()
    `;

    const res = await cdpEval(wsUrl, code, 4000);
    if (res && res.ready) {
      return true;
    }
    await new Promise(r => setTimeout(r, 1000));
  }
  return false;
}

/**
 * Memasukkan prompt ke dalam editor ProseMirror via native CDP
 */
function cdpNativeInsert(wsUrl, text) {
  return new Promise((resolve) => {
    let ws;
    try {
      ws = new WebSocket(wsUrl);
    } catch(e) {
      return resolve(false);
    }
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve(false);
    }, 15000);

    ws.onopen = () => {
      // 1. Fokus editor & bersihkan
      ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: {
          returnByValue: true,
          expression: `(() => {
            const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
            if (editor) {
              editor.focus();
              document.execCommand('selectAll', false, null);
              document.execCommand('delete', false, null);
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
        // 3. Dispatch synthetic input event agar React & ProseMirror sinkron
        ws.send(JSON.stringify({
          id: 3,
          method: 'Runtime.evaluate',
          params: {
            returnByValue: true,
            expression: `(() => {
              const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
              if (editor) {
                editor.dispatchEvent(new Event('input', { bubbles: true }));
                editor.dispatchEvent(new Event('change', { bubbles: true }));
                return editor.innerText.length;
              }
              return 0;
            })()`
          }
        }));
      } else if (msg.id === 3) {
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

/**
 * Pemicu pengiriman handal:
 * 1. Native CDP Mouse Click pada koordinat tombol kirim
 * 2. Synthetic DOM click
 * 3. Fallback: Native CDP Enter Key event jika streaming belum mulai
 */
async function triggerSend(wsUrl) {
  // 1. Dapatkan koordinat tombol kirim
  const coordCode = `
    (() => {
      const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');
      if (!sendBtn) return { found: false, error: 'Tombol send tidak ditemukan' };
      if (sendBtn.disabled) return { found: true, disabled: true, error: 'Tombol send disabled' };
      const r = sendBtn.getBoundingClientRect();
      return {
        found: true,
        disabled: false,
        x: r.x + r.width / 2,
        y: r.y + r.height / 2
      };
    })()
  `;

  const coordRes = await cdpEval(wsUrl, coordCode, 5000);
  if (!coordRes || !coordRes.found) {
    return { success: false, error: coordRes?.error || 'Tombol send tidak ditemukan' };
  }
  if (coordRes.disabled) {
    return { success: false, error: 'Tombol send disabled (kuota habis atau input belum terdeteksi)' };
  }

  // 2. Native CDP Mouse Click di koordinat tombol kirim
  await new Promise((resolve) => {
    const ws = new WebSocket(wsUrl);
    const to = setTimeout(() => { try { ws.close(); } catch(e){} resolve(); }, 3000);
    ws.onopen = () => {
      ws.send(JSON.stringify({
        id: 11,
        method: 'Input.dispatchMouseEvent',
        params: { type: 'mousePressed', x: coordRes.x, y: coordRes.y, button: 'left', clickCount: 1 }
      }));
      ws.send(JSON.stringify({
        id: 12,
        method: 'Input.dispatchMouseEvent',
        params: { type: 'mouseReleased', x: coordRes.x, y: coordRes.y, button: 'left', clickCount: 1 }
      }));
    };
    ws.onmessage = (e) => {
      const d = JSON.parse(e.data);
      if (d.id === 12) {
        clearTimeout(to);
        try { ws.close(); } catch(e){}
        resolve();
      }
    };
    ws.onerror = () => { clearTimeout(to); resolve(); };
  });

  // 3. Synthetic DOM click sebagai pendukung
  const clickDomCode = `
    (() => {
      const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');
      if (sendBtn && !sendBtn.disabled) {
        sendBtn.click();
        return true;
      }
      return false;
    })()
  `;
  await cdpEval(wsUrl, clickDomCode, 3000);

  // 4. Jeda 1.2 detik dan periksa apakah streaming sudah mulai
  await new Promise(r => setTimeout(r, 1200));

  const checkStartedCode = `
    (() => {
      const stopBtn = document.querySelector('button[aria-label*="Stop"], button[data-testid*="stop"]');
      const assts = document.querySelectorAll('div.font-claude-response, div.font-claude-message, div[data-message-author-role="assistant"]');
      return !!stopBtn || assts.length > 0 || location.pathname.includes('/chat/');
    })()
  `;
  const started = await cdpEval(wsUrl, checkStartedCode, 3000);

  // 5. Fallback ke CDP Enter Key jika belum terpicu
  if (!started) {
    console.log('[PENGIRIMAN] Pemicu klik belum terdeteksi aktif, mengirim native Enter key via CDP...');
    await new Promise((resolve) => {
      const ws = new WebSocket(wsUrl);
      const to = setTimeout(() => { try { ws.close(); } catch(e){} resolve(); }, 3000);
      ws.onopen = () => {
        ws.send(JSON.stringify({
          id: 21,
          method: 'Input.dispatchKeyEvent',
          params: { type: 'rawKeyDown', windowsVirtualKeyCode: 13, unmodifiedText: '\r', text: '\r', key: 'Enter', code: 'Enter' }
        }));
        ws.send(JSON.stringify({
          id: 22,
          method: 'Input.dispatchKeyEvent',
          params: { type: 'keyUp', windowsVirtualKeyCode: 13, unmodifiedText: '\r', text: '\r', key: 'Enter', code: 'Enter' }
        }));
      };
      ws.onmessage = (e) => {
        const d = JSON.parse(e.data);
        if (d.id === 22) {
          clearTimeout(to);
          try { ws.close(); } catch(e){}
          resolve();
        }
      };
      ws.onerror = () => { clearTimeout(to); resolve(); };
    });
  }

  return { success: true };
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

/**
 * Mengirim prompt ke tab tertentu dengan protokol:
 * 1. Reset ke https://claude.ai/new SEBELUM mulai
 * 2. Ketik & Trigger Send
 * 3. Monitor respons
 * 4. Ekstrak jawaban
 * 5. Reset kembali ke https://claude.ai/new SETELAH selesai (Mandat User)
 */
async function sendPromptToTab(tab, promptText) {
  console.log(`[PENGIRIMAN] Menyiapkan tab [${tab.id.slice(0, 8)}] (${tab.accountName || 'Claude'})...`);

  // Bawa tab ke depan agar rendering aktif 100%
  try {
    const ws = new WebSocket(tab.webSocketDebuggerUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({ id: 99, method: 'Page.bringToFront' }));
      setTimeout(() => { try { ws.close(); } catch(e){} }, 500);
    };
  } catch(e){}

  // SOP LANGKAH 1: Utamakan kembali ke percakapan baru SEBELUM memulai
  console.log(`[PERCAKAPAN BARU] Memastikan tab berada di https://claude.ai/new yang bersih...`);
  await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
  const isFresh = await prepareFreshChat(tab.webSocketDebuggerUrl, 15000);
  if (!isFresh) {
    console.warn(`[PERINGATAN] Tab belum siap sempurna di https://claude.ai/new, mencoba reload...`);
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
    await new Promise(r => setTimeout(r, 2000));
    await prepareFreshChat(tab.webSocketDebuggerUrl, 10000);
  }

  // Cek apakah akun tiba-tiba limit pada halaman /new
  const preCheck = await inspectTabStatus(tab);
  if (preCheck.isLimited) {
    return { success: false, reason: 'rate_limited', limitMessage: preCheck.limitMessage };
  }

  // Pengetikan native CDP ke ProseMirror
  console.log(`[PENGETIKAN] Memasukkan teks prompt (${promptText.length} karakter) via CDP...`);
  const inserted = await cdpNativeInsert(tab.webSocketDebuggerUrl, promptText);
  if (!inserted) {
    return { success: false, reason: 'insert_failed', error: 'Gagal memasukkan teks via CDP' };
  }

  // Jeda mikro agar editor memvalidasi input
  await new Promise(r => setTimeout(r, 800));

  // Pemicu pengiriman pesan yang handal
  const sendRes = await triggerSend(tab.webSocketDebuggerUrl);
  if (!sendRes.success) {
    return { success: false, reason: 'send_trigger_failed', error: sendRes.error };
  }

  console.log(`[PENGIRIMAN] Tombol kirim terpicu. Menunggu Claude mulai merespons...`);

  // Tunggu hingga Claude mulai menghasilkan respons atau limit muncul
  const startWait = Date.now();
  let started = false;
  while (Date.now() - startWait < 25000) {
    await new Promise(r => setTimeout(r, 1500));
    const st = await inspectTabStatus(tab);
    if (st.isLimited) {
      // Reset tab ke /new sebelum beralih
      await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
      return { success: false, reason: 'rate_limited', limitMessage: st.limitMessage };
    }
    if (st.isStreaming) {
      started = true;
      break;
    }
    const checkAssistantCode = `
      (() => {
        const assts = document.querySelectorAll('div.font-claude-response, div.font-claude-message, div[data-message-author-role="assistant"]');
        return assts.length > 0;
      })()
    `;
    const checkRes = await cdpEval(tab.webSocketDebuggerUrl, checkAssistantCode, 3000);
    if (checkRes === true) {
      started = true;
      break;
    }
  }

  if (!started) {
    // Reset kembali ke /new agar bersih
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
    return { success: false, reason: 'stream_never_started', error: 'Claude tidak mulai merespons setelah tombol kirim diklik' };
  }

  // Pantau streaming hingga selesai (maksimal 10 menit untuk model deep thinking)
  console.log(`[STREAMING] Claude sedang menyusun jawaban:`);
  const startTime = Date.now();
  const maxWaitMs = 10 * 60 * 1000;

  while (Date.now() - startTime < maxWaitMs) {
    await new Promise(r => setTimeout(r, 2000));
    const status = await inspectTabStatus(tab);

    if (status.isLimited) {
      await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
      return { success: false, reason: 'rate_limited', limitMessage: status.limitMessage };
    }

    if (!status.isStreaming) {
      // Jeda 2 detik untuk memastikan rendering markdown selesai sempurna
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
        const responses = Array.from(document.querySelectorAll('.font-claude-response, div[data-message-author-role="assistant"], div.font-claude-message'));
        if (responses.length > 0) {
          const lastResp = responses[responses.length - 1];
          const md = lastResp.querySelector('.standard-markdown, .progressive-markdown, .prose');
          if (md && md.innerText.trim().length > 10) {
            return { fullText: md.innerText.trim() };
          }
          return { fullText: lastResp.innerText.trim() };
        }
        const main = document.querySelector('main') || document.body;
        return { fullText: main.innerText.trim() };
      } catch(e) {
        return { error: e.message };
      }
    })()
  `;

  const extractResult = await cdpEval(tab.webSocketDebuggerUrl, extractCode, 5000);
  const text = extractResult?.fullText || '';
  if (text.length < 20) {
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
    return { success: false, reason: 'empty_response', error: 'Respons Claude kosong atau terlalu pendek' };
  }

  // SOP LANGKAH MANDAT USER: Selalu kembali ke percakapan baru SETELAH mengakhiri komunikasi
  console.log(`[RESET PERCAKAPAN BARU] Mengembalikan tab [${tab.id.slice(0, 8)}] (${tab.accountName}) ke https://claude.ai/new setelah komunikasi selesai...`);
  await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
  await prepareFreshChat(tab.webSocketDebuggerUrl, 8000);
  console.log(`[RESET SELESAI] Tab kembali bersih dan siap untuk percakapan berikutnya.`);

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
  await new Promise(r => setTimeout(r, 2000));

  const accountStatuses = [];
  for (const tab of tabs) {
    // Bring tab to front
    try {
      const ws = new WebSocket(tab.webSocketDebuggerUrl);
      await new Promise((resolve) => {
        ws.onopen = () => {
          ws.send(JSON.stringify({ id: 1, method: 'Page.bringToFront' }));
          setTimeout(() => { try{ws.close();}catch(e){} resolve(); }, 600);
        };
        ws.onerror = () => resolve();
      });
    } catch(e){}

    await prepareFreshChat(tab.webSocketDebuggerUrl, 6000);
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

  // Cari akun yang siap digunakan (Logged in, bisa mengetik, dan tidak limited)
  const readyAccounts = accountStatuses.filter(st => st.isLoggedIn && st.canType && !st.isLimited);

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
      await new Promise(r => setTimeout(r, 2000));
      for (const tab of tabs) {
        await prepareFreshChat(tab.webSocketDebuggerUrl, 5000);
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

module.exports = { coordinate, inspectTabStatus, getClaudeTabs, prepareFreshChat, sendPromptToTab };
