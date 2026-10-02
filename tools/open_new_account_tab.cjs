/**
 * Membuka tab login Claude baru di profil browser ChromeDebug yang sama,
 * menggunakan BrowserContext terisolasi sehingga bisa login akun yang berbeda.
 * Menerima argumen jumlah tab, misal: node open_new_account_tab.cjs 2
 */
const fs = require('fs');

async function createOneTab(browserWs, tabIndex, totalTabs) {
  return new Promise((resolve, reject) => {
    let contextId = null;

    const handler = (evt) => {
      const msg = JSON.parse(evt.data);
      if (!msg.id) return;

      if (msg.error) {
        browserWs.removeEventListener('message', handler);
        return reject(new Error(msg.error.message));
      }

      if (msg.id === 100 + tabIndex * 10 + 1) {
        contextId = msg.result?.browserContextId;
        browserWs.send(JSON.stringify({
          id: 100 + tabIndex * 10 + 2,
          method: 'Target.createTarget',
          params: {
            url: 'https://claude.ai/login',
            browserContextId: contextId,
            newWindow: true
          }
        }));
      } else if (msg.id === 100 + tabIndex * 10 + 2) {
        const targetId = msg.result?.targetId;
        browserWs.send(JSON.stringify({
          id: 100 + tabIndex * 10 + 3,
          method: 'Target.activateTarget',
          params: { targetId }
        }));
      } else if (msg.id === 100 + tabIndex * 10 + 3) {
        browserWs.removeEventListener('message', handler);
        console.log(`[OK] Tab baru #${tabIndex + 1}/${totalTabs} berhasil dibuka & diaktifkan ke layar!`);
        resolve();
      }
    };

    browserWs.addEventListener('message', handler);
    browserWs.send(JSON.stringify({
      id: 100 + tabIndex * 10 + 1,
      method: 'Target.createBrowserContext'
    }));
  });
}

async function main() {
  const countArg = parseInt(process.argv[2], 10);
  const count = isNaN(countArg) || countArg < 1 ? 1 : countArg;

  console.log(`Menghubungi ChromeDebug di port 9222... (Akan membuka ${count} tab baru)`);
  let versionData;
  try {
    const versionRes = await fetch('http://127.0.0.1:9222/json/version');
    versionData = await versionRes.json();
  } catch (e) {
    console.error('ERROR: ChromeDebug port 9222 tidak aktif! Pastikan ChromeDebug sudah berjalan.');
    process.exit(1);
  }

  const browserWs = new WebSocket(versionData.webSocketDebuggerUrl);

  browserWs.onopen = async () => {
    try {
      for (let i = 0; i < count; i++) {
        await createOneTab(browserWs, i, count);
        // jeda kecil antar pembukaan tab
        if (i < count - 1) await new Promise(r => setTimeout(r, 600));
      }
      console.log(`\n>>> SUKSES: ${count} tab login Claude baru siap digunakan di ChromeDebug! <<<`);
      console.log('Silakan login dengan akun-akun Claude Anda yang berbeda.\n');
    } catch(err) {
      console.error('Gagal membuka tab:', err.message);
    } finally {
      browserWs.close();
      process.exit(0);
    }
  };
}

main().catch(console.error);
