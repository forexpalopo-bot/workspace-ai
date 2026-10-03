/**
 * Multi-Tab Auto-Failover Coordinator for Claude.ai in ChromeDebug
 * Menangani pengiriman prompt ke Claude dan otomatis beralih ke tab akun lain jika akun saat ini limit kuota token AI.
 * Sesuai SOP User:
 * 1. Selalu utamakan kembali ke percakapan baru (https://claude.ai/new) SEBELUM memulai dan SETELAH mengakhiri komunikasi.
 * 2. Hindari spamming / pengiriman berkali-kali pada 1 akun (Strict Single-Shot Send).
 * 3. Tangani file besar secara otomatis (auto-condense / parse laporan MT4) agar tidak macet / gagal kirim karena file besar terbaca.
 * 4. Bersihkan seluruh attachment pill / card lampiran saat reset.
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

function cdpReload(wsUrl, timeoutMs = 10000) {
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
        id: 3,
        method: 'Page.reload',
        params: { ignoreCache: true }
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
 * Otomatis mendeteksi dan meringkas payload jika berukuran besar atau merupakan file HTML laporan MT4.
 * Mencegah error "file besar terbaca" dan mencegah pembentukan pill lampiran yang membekukan tombol kirim.
 */
function summarizeMt4Html(htmlText) {
  const summaryKeys = {
    'Initial deposit': 'Initial Deposit',
    'Total net profit': 'Total Net Profit',
    'Profit factor': 'Profit Factor',
    'Expected payoff': 'Expected Payoff',
    'Absolute drawdown': 'Absolute Drawdown',
    'Maximal drawdown': 'Maximal Drawdown',
    'Relative drawdown': 'Relative Drawdown',
    'Total trades': 'Total Trades',
    'Short positions (won %)': 'Short Positions Won %',
    'Long positions (won %)': 'Long Positions Won %',
    'Profit trades (% of total)': 'Win Rate (% of total)',
    'Loss trades (% of total)': 'Loss Trades (% of total)',
    'Largest profit trade': 'Largest Profit Trade',
    'Largest loss trade': 'Largest Loss Trade',
    'Average profit trade': 'Average Profit Trade',
    'Average loss trade': 'Average Loss Trade'
  };

  const results = {};
  for (const [key, label] of Object.entries(summaryKeys)) {
    const regex = new RegExp(`>\\s*${key}\\s*<\\/td>\\s*<td[^>]*>\\s*([^<]+)<\\/td>`, 'i');
    const match = htmlText.match(regex);
    if (match) {
      results[label] = match[1].trim();
    }
  }

  let out = '# RINGKASAN STRATEGY TESTER REPORT MT4 (EKSTRAKSI OTOMATIS)\n\n';
  out += '| Metrik Kinerja | Nilai |\n';
  out += '| :--- | :--- |\n';
  for (const [k, v] of Object.entries(results)) {
    out += `| ${k} | ${v} |\n`;
  }

  out += '\n## Permohonan Evaluasi untuk Claude:\n';
  out += 'Berdasarkan hasil backtest kuantitatif di atas, berikan evaluasi mendalam dan rekomendasi perbaikan terarah pada sistem open posisi / manajemen risiko EA BioOnePro agar drawdown dapat ditekan dan profitabilitas meningkat konsisten.\n';

  return out;
}

function cleanPromptPayload(promptText) {
  if (!promptText || typeof promptText !== 'string') return '';

  // 1. Cek apakah ini file HTML backtest Strategy Tester MT4
  if (promptText.includes('<html') && (promptText.includes('Strategy Tester Report') || promptText.includes('Total net profit') || promptText.includes('Initial deposit'))) {
    console.log('[AUTO-RINGKAS] Terdeteksi file HTML Strategy Tester MT4 berukuran besar. Meringkas metrik utama...');
    return summarizeMt4Html(promptText);
  }

  // 2. Jika teks terlalu besar (> 14.000 karakter), kondensasi agar tidak memicu konversi file pill / macet di Claude Web
  if (promptText.length > 14000) {
    console.log(`[AUTO-RINGKAS] Teks prompt terlalu besar (${promptText.length} karakter). Mengoptimalkan ke batas aman agar tidak memicu file lampiran...`);
    const head = promptText.slice(0, 7000);
    const tail = promptText.slice(-5000);
    return head + '\n\n... [Bagian tengah data diringkas otomatis demi efisiensi token & mencegah file card di Claude] ...\n\n' + tail;
  }

  return promptText;
}

/**
 * Menyiapkan tab agar 100% siap di percakapan baru (https://claude.ai/new)
 * Membersihkan modal/pop-up, menghapus SELURUH lampiran file/pasted text card lama,
 * dan mengosongkan editor ProseMirror.
 */
async function prepareFreshChat(wsUrl, maxWaitMs = 15000) {
  const start = Date.now();
  let retryReload = false;

  while (Date.now() - start < maxWaitMs) {
    const code = `
      (() => {
        try {
          // 1. Tutup segala macam modal/banner selamat datang/promo
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

          // 2. HAPUS SEMUA ATTACHMENT / PILL / FILE CARD LAMA (KUNCI PENANGGULANGAN FILE BESAR)
          const removeAttachmentBtns = Array.from(document.querySelectorAll(
            'button[data-cds-attachment-remove], button[aria-label*="Remove"], button[aria-label*="Hapus"], button[aria-label*="Delete"], button[data-testid*="remove"]'
          ));
          removeAttachmentBtns.forEach(b => { try { b.click(); } catch(e){} });

          // 3. Bersihkan editor ProseMirror
          const editor = document.querySelector('div.ProseMirror, [contenteditable="true"]');
          if (editor) {
            editor.focus();
            if (editor.innerText.trim().length > 0) {
              document.execCommand('selectAll', false, null);
              document.execCommand('delete', false, null);
              editor.innerHTML = '<p></p>';
              editor.dispatchEvent(new Event('input', { bubbles: true }));
            }
          }

          // 4. Periksa apakah masih ada pill attachment tersisa
          const pills = Array.from(document.querySelectorAll('[data-cds-attachment], [data-testid="file-thumbnail"], [class*="attachment"]'))
            .filter(x => x.innerText && (x.innerText.includes('.txt') || x.innerText.includes('KB') || x.innerText.includes('Pasted') || x.innerText.includes('pasted')));

          const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');

          return {
            ready: !!editor && pills.length === 0,
            hasEditor: !!editor,
            pillCount: pills.length,
            hasSendBtn: !!sendBtn,
            editorTextLen: editor ? editor.innerText.trim().length : 0
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

    // Jika pill lampiran membandel tidak terhapus setelah 4 detik, lakukan Page.reload
    if (res && res.pillCount > 0 && !retryReload && (Date.now() - start > 4000)) {
      console.log('[RESET] Menemukan file attachment tersisa. Melakukan reload bersih...');
      retryReload = true;
      await cdpReload(wsUrl, 5000);
      await new Promise(r => setTimeout(r, 2000));
      continue;
    }

    await new Promise(r => setTimeout(r, 1000));
  }
  return false;
}

/**
 * Memasukkan prompt ke dalam editor ProseMirror via native CDP
 * Dilengkapi pengecekan kesiapan tombol kirim & deteksi peringatan ukuran file.
 */
function cdpNativeInsert(wsUrl, text) {
  return new Promise((resolve) => {
    let ws;
    try {
      ws = new WebSocket(wsUrl);
    } catch(e) {
      return resolve({ success: false, error: e.message });
    }
    const timer = setTimeout(() => {
      try { ws.close(); } catch(e){}
      resolve({ success: false, error: 'Timeout memasukkan teks via CDP' });
    }, 15000);

    ws.onopen = () => {
      // 1. Fokus editor & bersihkan sekali lagi
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
        resolve({ success: true });
      }
    };

    ws.onerror = () => {
      clearTimeout(timer);
      resolve({ success: false, error: 'WebSocket error saat pengetikan' });
    };
  });
}

/**
 * Pemicu pengiriman STRICT SINGLE-SHOT:
 * Menghindari penembakan beruntun yang menyebabkan pesan terkirim berkali-kali pada 1 akun.
 * 1. Tunggu tombol kirim aktif (disabled === false) hingga 10 detik
 * 2. Eksekusi Native CDP Mouse Click SEKALI SAJA
 * 3. Pantau respon selama 4 detik
 * 4. Fallback ke CDP Enter Key HANYA jika tombol benar-benar tidak terpicu dan teks masih utuh di editor
 */
async function triggerSend(wsUrl) {
  // 1. Tunggu hingga tombol kirim aktif (disabled === false)
  const waitSendStart = Date.now();
  let sendBtnReady = false;
  let btnCoords = null;

  while (Date.now() - waitSendStart < 10000) {
    const checkBtnCode = `
      (() => {
        const sendBtn = document.querySelector('button[data-testid="chat-input-send"], button[aria-label*="Send"], button[aria-label*="Kirim"]');
        const alert = document.querySelector('[role="alert"], .text-danger, [class*="warning"]');
        if (!sendBtn) return { found: false, error: 'Tombol send tidak ditemukan' };
        
        let alertText = null;
        if (alert && (alert.innerText.includes('too large') || alert.innerText.includes('exceeds') || alert.innerText.includes('terlalu besar'))) {
          alertText = alert.innerText;
        }

        const r = sendBtn.getBoundingClientRect();
        return {
          found: true,
          disabled: sendBtn.disabled,
          x: r.x + r.width / 2,
          y: r.y + r.height / 2,
          alert: alertText
        };
      })()
    `;

    const btnInfo = await cdpEval(wsUrl, checkBtnCode, 3000);
    if (btnInfo?.alert) {
      return { success: false, reason: 'file_too_large', error: `Peringatan Claude: ${btnInfo.alert}` };
    }

    if (btnInfo && btnInfo.found && !btnInfo.disabled) {
      sendBtnReady = true;
      btnCoords = btnInfo;
      break;
    }

    await new Promise(r => setTimeout(r, 600));
  }

  if (!sendBtnReady || !btnCoords) {
    return { success: false, reason: 'send_disabled', error: 'Tombol kirim tetap dinonaktifkan oleh Claude (kemungkinan file/teks sedang diproses atau kuota habis)' };
  }

  // 2. Eksekusi Native CDP Mouse Click SEKALI SAJA (Single-Shot)
  console.log(`[PENGIRIMAN] Memicu tombol kirim (Single-Shot CDP Click)...`);
  await new Promise((resolve) => {
    const ws = new WebSocket(wsUrl);
    const to = setTimeout(() => { try { ws.close(); } catch(e){} resolve(); }, 3000);
    ws.onopen = () => {
      ws.send(JSON.stringify({
        id: 11,
        method: 'Input.dispatchMouseEvent',
        params: { type: 'mousePressed', x: btnCoords.x, y: btnCoords.y, button: 'left', clickCount: 1 }
      }));
      ws.send(JSON.stringify({
        id: 12,
        method: 'Input.dispatchMouseEvent',
        params: { type: 'mouseReleased', x: btnCoords.x, y: btnCoords.y, button: 'left', clickCount: 1 }
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

  // 3. Jeda 3.5 detik untuk verifikasi apakah pesan sudah diterima (editor kosong / URL berubah / stopBtn muncul)
  await new Promise(r => setTimeout(r, 3500));

  const checkStartedCode = `
    (() => {
      const stopBtn = document.querySelector('button[aria-label*="Stop"], button[data-testid*="stop"]');
      const assts = document.querySelectorAll('div.font-claude-response, div.font-claude-message, div[data-message-author-role="assistant"]');
      const editor = document.querySelector('.ProseMirror, [contenteditable="true"]');
      const isEditorEmpty = !editor || editor.innerText.trim().length === 0;
      const isChatUrl = location.pathname.includes('/chat/');
      return {
        started: !!stopBtn || assts.length > 0 || isChatUrl || isEditorEmpty,
        editorTextLen: editor ? editor.innerText.trim().length : 0
      };
    })()
  `;
  const sendCheck = await cdpEval(wsUrl, checkStartedCode, 3000);

  // 4. Fallback ke CDP Enter Key HANYA jika editor masih memegang teks asli dan URL belum berpindah
  if (!sendCheck?.started && sendCheck?.editorTextLen > 0) {
    console.log('[PENGIRIMAN] Input masih tersisa di editor, mencoba fallback Enter key sekali...');
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
 * 2. Bersihkan seluruh attachment lampiran lama
 * 3. Sanitasi & kompresi prompt jika file besar
 * 4. Ketik & Trigger Send (Single-Shot)
 * 5. Monitor respons
 * 6. Ekstrak jawaban
 * 7. Reset kembali ke https://claude.ai/new SETELAH selesai (Mandat User)
 */
async function sendPromptToTab(tab, rawPromptText) {
  console.log(`[PENGIRIMAN] Menyiapkan tab [${tab.id.slice(0, 8)}] (${tab.accountName || 'Claude'})...`);

  // Bawa tab ke depan agar rendering aktif 100%
  try {
    const ws = new WebSocket(tab.webSocketDebuggerUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({ id: 99, method: 'Page.bringToFront' }));
      setTimeout(() => { try { ws.close(); } catch(e){} }, 500);
    };
  } catch(e){}

  // SOP LANGKAH 1: Utamakan kembali ke percakapan baru SEBELUM memulai dan bersihkan segala pill
  console.log(`[PERCAKAPAN BARU] Memastikan tab berada di https://claude.ai/new bersih dari draft & lampiran...`);
  await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
  const isFresh = await prepareFreshChat(tab.webSocketDebuggerUrl, 15000);
  if (!isFresh) {
    console.warn(`[PERINGATAN] Tab belum bersih sempurna, melakukan reload tab...`);
    await cdpReload(tab.webSocketDebuggerUrl, 8000);
    await prepareFreshChat(tab.webSocketDebuggerUrl, 10000);
  }

  // Cek apakah akun tiba-tiba limit pada halaman /new
  const preCheck = await inspectTabStatus(tab);
  if (preCheck.isLimited) {
    return { success: false, reason: 'rate_limited', limitMessage: preCheck.limitMessage };
  }

  // SOP LANGKAH 2: Sanitasi prompt payload (mencegah "file besar terbaca")
  const promptText = cleanPromptPayload(rawPromptText);

  // Pengetikan native CDP ke ProseMirror
  console.log(`[PENGETIKAN] Memasukkan teks prompt (${promptText.length} karakter) via CDP...`);
  const insertRes = await cdpNativeInsert(tab.webSocketDebuggerUrl, promptText);
  if (!insertRes.success) {
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
    return { success: false, reason: 'insert_failed', error: insertRes.error };
  }

  // Jeda mikro agar editor memvalidasi input
  await new Promise(r => setTimeout(r, 800));

  // Pemicu pengiriman pesan yang handal (Single-Shot)
  const sendRes = await triggerSend(tab.webSocketDebuggerUrl);
  if (!sendRes.success) {
    console.warn(`[GAGAL KIRIM] ${sendRes.error}. Membersihkan tab untuk mencegah penumpukan pesan...`);
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
    await prepareFreshChat(tab.webSocketDebuggerUrl, 6000);
    return { success: false, reason: sendRes.reason || 'send_trigger_failed', error: sendRes.error };
  }

  console.log(`[PENGIRIMAN] Pesan terkirim secara tertib. Menunggu Claude mulai merespons...`);

  // Tunggu hingga Claude mulai menghasilkan respons atau limit muncul
  const startWait = Date.now();
  let started = false;
  while (Date.now() - startWait < 25000) {
    await new Promise(r => setTimeout(r, 1500));
    const st = await inspectTabStatus(tab);
    if (st.isLimited) {
      // Reset tab ke /new sebelum beralih
      await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
      await prepareFreshChat(tab.webSocketDebuggerUrl, 5000);
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
    console.warn(`[STREAM TIMEOUT] Claude tidak mulai merespons. Mengembalikan tab ke https://claude.ai/new...`);
    await cdpNavigate(tab.webSocketDebuggerUrl, 'https://claude.ai/new');
    await prepareFreshChat(tab.webSocketDebuggerUrl, 5000);
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
      await prepareFreshChat(tab.webSocketDebuggerUrl, 5000);
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
    await prepareFreshChat(tab.webSocketDebuggerUrl, 5000);
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

module.exports = { coordinate, inspectTabStatus, getClaudeTabs, prepareFreshChat, sendPromptToTab, cleanPromptPayload, summarizeMt4Html };
