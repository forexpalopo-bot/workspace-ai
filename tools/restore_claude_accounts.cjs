/**
 * Memulihkan semua sesi tab akun Claude yang tersimpan di research/claude_accounts.json
 * Membuka tab untuk setiap akun dan menginjeksikan sessionKey agar tidak perlu login ulang.
 */
const fs = require('fs');

const ACCOUNTS_FILE = 'C:\\Penelitian_EA\\BioOnePro\\repo\\research\\claude_accounts.json';
const PORT = 9222;

async function main() {
  if (!fs.existsSync(ACCOUNTS_FILE)) {
    console.log('Belum ada file data akun di', ACCOUNTS_FILE);
    return;
  }

  let db;
  try {
    db = JSON.parse(fs.readFileSync(ACCOUNTS_FILE, 'utf-8'));
  } catch(e) {
    console.error('Format database akun rusak:', e.message);
    return;
  }

  const accounts = db.accounts || [];
  console.log(`Ditemukan ${accounts.length} akun tersimpan.`);

  let versionData;
  try {
    const res = await fetch(`http://127.0.0.1:${PORT}/json/version`);
    versionData = await res.json();
  } catch (e) {
    console.error(`ChromeDebug port ${PORT} belum aktif.`);
    return;
  }

  const browserWs = new WebSocket(versionData.webSocketDebuggerUrl);

  browserWs.onopen = async () => {
    console.log('Menghubungkan ke browser untuk sinkronisasi tab akun...');
    
    // Periksa tab yang sudah ada
    const listRes = await fetch(`http://127.0.0.1:${PORT}/json/list`);
    const openPages = (await listRes.json()).filter(p => p.type === 'page' && p.url && p.url.includes('claude.ai'));

    for (let i = 0; i < accounts.length; i++) {
      const acc = accounts[i];
      console.log(`\nMenyiapkan tab untuk [${acc.name}] (${acc.id})...`);

      // Akun 1 biasanya menggunakan sesi default (sudah aktif di jendela utama)
      if (i === 0) {
        console.log(`-> Akun 1 (${acc.name}) menggunakan profil default.`);
        continue;
      }

      // Untuk akun 2 dst, buat BrowserContext baru
      await new Promise((resolve) => {
        let reqId = 1;
        const msgHandler = async (evt) => {
          const msg = JSON.parse(evt.data);
          if (!msg.id) return;

          if (msg.id === 1) {
            const contextId = msg.result?.browserContextId;
            browserWs.send(JSON.stringify({
              id: 2,
              method: 'Target.createTarget',
              params: {
                url: 'https://claude.ai',
                browserContextId: contextId,
                newWindow: true
              }
            }));
          } else if (msg.id === 2) {
            const targetId = msg.result?.targetId;
            console.log(`-> Tab dibuat untuk ${acc.name} (Target: ${targetId.slice(0, 8)})`);

            // Dapatkan target ws URL
            setTimeout(async () => {
              try {
                const curList = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
                const curTarget = curList.find(t => t.id === targetId);
                if (curTarget && acc.cookies) {
                  // Injeksi cookies
                  const tabWs = new WebSocket(curTarget.webSocketDebuggerUrl);
                  tabWs.onopen = () => {
                    tabWs.send(JSON.stringify({
                      id: 10,
                      method: 'Network.setCookies',
                      params: { cookies: acc.cookies }
                    }));
                  };
                  tabWs.onmessage = (e) => {
                    const m = JSON.parse(e.data);
                    if (m.id === 10) {
                      console.log(`-> Cookie sesi untuk ${acc.name} berhasil diinjeksikan!`);
                      // Reload tab
                      tabWs.send(JSON.stringify({ id: 11, method: 'Page.reload' }));
                    } else if (m.id === 11) {
                      tabWs.close();
                      browserWs.removeEventListener('message', msgHandler);
                      resolve();
                    }
                  };
                } else {
                  browserWs.removeEventListener('message', msgHandler);
                  resolve();
                }
              } catch(err) {
                browserWs.removeEventListener('message', msgHandler);
                resolve();
              }
            }, 1000);
          }
        };

        browserWs.addEventListener('message', msgHandler);
        browserWs.send(JSON.stringify({ id: 1, method: 'Target.createBrowserContext' }));
      });
    }

    browserWs.close();
    console.log('\nSeluruh sesi akun berhasil dipersiapkan.');
    process.exit(0);
  };
}

main().catch(console.error);
