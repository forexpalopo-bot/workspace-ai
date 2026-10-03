---
name: claude-coordinator
description: >-
  Mengatur koordinasi dan komunikasi AI-to-AI otomatis antara Antigravity dan Claude.ai di Chrome Debug (CDP Port 9222).
  Gunakan skill ini setiap kali berinteraksi atau bertukar analisis dengan Claude di browser: mengelola multi-tab auto-failover
  lintas akun Claude, mencegah pengiriman pesan berkali-kali (Strict Single-Shot Send), menangani file/payload besar secara
  otomatis (meringkas laporan HTML MT4 3MB menjadi metrik ringkas agar tidak error 'file besar terbaca'), membersihkan seluruh
  attachment card/pill, dan menerapkan mandat reset ke percakapan baru (https://claude.ai/new) sebelum dan sesudah komunikasi.
---

# Claude Multi-Tab Coordinator Skill

Skill ini menyediakan panduan operasional, protokol keandalan, dan otomasi 100% untuk komunikasi AI-to-AI antara Antigravity dan Claude.ai melalui Chrome DevTools Protocol (CDP port 9222).

---

## 1. Prinsip Utama & Mandat Wajib (SOP)

1. **Mandat Reset Percakapan Baru (`https://claude.ai/new`)**:
   - **Sebelum Komunikasi Dimulai**:
     - Tab wajib dipastikan berada di `https://claude.ai/new`.
     - Seluruh modal sambutan/promosi ("Nanti saja", "Dismiss", "Tutup") ditutup otomatis.
     - Seluruh kartu lampiran (*attachment pills* / *pasted text card*) lama dihapus bersih.
     - Editor ProseMirror dikosongkan (`<p></p>`).
   - **Setelah Komunikasi Berakhir**:
     - Segera setelah respons Claude diekstrak dan disimpan ke disk, tab **wajib langsung dinavigasikan kembali ke `https://claude.ai/new`** dan dibersihkan. Tab tidak boleh dibiarkan tertinggal di URL `/chat/<uuid>`.

2. **Pencegahan Error "File Besar Terbaca" (*Large Payload Auto-Condensation*)**:
   - Jangan pernah menyuntikkan file mentah berukuran megabyte (seperti laporan HTML MT4 3 MB yang memuat ribuan baris tabel). Tindakan ini membekukan engine browser dan memicu error Claude Web (*"file too large"* atau membekukan tombol kirim).
   - Sistem wajib melakukan auto-summarization: mengekstrak 16 indikator performa utama menjadi tabel Markdown ringkas (~600 karakter) sebelum diketik ke browser.
   - Jika teks panjang (> 14.000 karakter), lakukan kondensasi bagian tengah dan pertahankan bagian ringkasan serta pertanyaan analisis.

3. **Pencegahan Spamming Pesan Berkali-kali (*Strict Single-Shot Send*)**:
   - Hindari pemicu klik ganda dan jangan menembakkan tombol Enter secara terburu-buru.
   - Tunggu hingga tombol kirim berstatus aktif (`disabled === false`) hingga 10 detik.
   - Kirimkan **satu kali klik tunggal** (*Single-Shot Native CDP Mouse Click* pada koordinat tombol kirim).
   - Berikan jeda verifikasi minimal 3,5 detik. Tombol Enter hanya digunakan sebagai *fallback* darurat jika input masih utuh di editor dan tidak ada tanda streaming.

4. **Pembersihan Bersih Saat Gagal (*Auto-Purge on Failure*)**:
   - Jika akun mengalami limit kuota atau timeout pengiriman, tab akun tersebut langsung dibersihkan seketika ke `https://claude.ai/new` agar tidak ada draf/lampiran tersisa, lalu alihkan secara mulus (*failover*) ke akun berikutnya.

---

## 2. Struktur Perintah & CLI

Koordinator utama berada pada:
`tools/claude_multitab_coordinator.cjs`

### A. Memeriksa Status Seluruh Akun & Kuota Token
```powershell
node tools/claude_multitab_coordinator.cjs --status
```
*Output menampilkan ID tab, nama profil akun, status login, kemampuan mengetik, dan status limit kuota token.*

### B. Mengirim Pertanyaan Langsung
```powershell
node tools/claude_multitab_coordinator.cjs --prompt "Teks pertanyaan atau analisis..." --output research/claude_response.txt
```

### C. Mengirim File Laporan / Analisis (Auto-Summarized)
```powershell
node tools/claude_multitab_coordinator.cjs --file path/to/laporan.htm --output research/claude_analysis.txt
```
*Jika file berupa HTML backtest MT4, script otomatis meringkasnya menjadi tabel metrik 600 byte.*

---

## 3. Integrasi Programatik dalam Node.js

```javascript
const {
  coordinate,
  sendPromptToTab,
  prepareFreshChat,
  cleanPromptPayload,
  getClaudeTabs
} = require('./tools/claude_multitab_coordinator.cjs');

// Contoh eksekusi koordinasi otomatis dengan failover 100%
async function runResearchTask() {
  const prompt = "Lakukan audit statistik atas drawdown v94...";
  const outputPath = "research/claude_verdict.txt";

  const result = await coordinate(prompt, outputPath);
  if (result.success) {
    console.log(`Berhasil dijawab oleh akun: ${result.accountUsed}`);
    console.log(`Jawaban disimpan di: ${outputPath}`);
  } else {
    console.error(`Gagal: ${result.reason}`);
  }
}
```

---

## 4. Penanganan Kartu Lampiran (*Attachment Pills*) di DOM

Jika kartu lampiran Claude Web muncul, hapus dengan menargetkan selektor berikut:
```javascript
const removeAttachmentBtns = Array.from(document.querySelectorAll(
  'button[data-cds-attachment-remove], button[aria-label*="Remove"], button[aria-label*="Hapus"], button[aria-label*="Delete"], button[data-testid*="remove"]'
));
removeAttachmentBtns.forEach(b => { try { b.click(); } catch(e){} });
```
Jika kartu lampiran tetap bertahan karena state internal React, lakukan:
```javascript
// Reload bersih halaman via CDP
await cdpReload(wsUrl, 5000);
```

---

## 5. Menambah Tab Akun Baru Jika Seluruh Kuota Limit

Jika seluruh akun yang ada mencapai batas pesan 5 jam, tambahkan tab baru menggunakan:
```powershell
node tools/open_new_account_tab.cjs
```
Tab baru akan terbuka di profil browser ChromeDebug yang sama dan siap untuk login akun Google/Claude berikutnya.
