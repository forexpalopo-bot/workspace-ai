# Prompt Antigravity — Forward Test Akun Demo (EA E2 Final)

```text
Siapkan dan pantau forward test EA BioOnePro E2 Final di akun DEMO. Jangan pernah memakai akun real.

1. Di C:\Penelitian_EA\BioOnePro\repo: git checkout claude/cek-xb7zbt && git pull
   Salin ea\BioOnePro_E2_Final.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi (0 error dan 0 warning wajib).

2. Pakai akun DEMO IC Markets dengan balance sekitar $3000 (minta saya membuatnya bila belum ada).
   Buka chart XAUUSD M1, pasang EA BioOnePro_E2_Final dengan input default (jangan ubah apa pun), centang
   "Allow live trading", dan aktifkan tombol AutoTrading. Biarkan MT4 menyala terus (VPS lebih baik).
   Catat di research\forward\LOG.md: tanggal mulai, nomor akun demo, balance awal, rata-rata spread XAUUSD yang terlihat,
   dan apakah komisi akun Raw benar sekitar $7/lot.

3. Setiap Sabtu:
   - Di MT4 tab Account History, klik kanan > All History > Save as Detailed Report, lalu simpan sebagai
     research\forward\minggu-<NN>.htm.
   - Tambahkan 1 baris ke research\forward\LOG.md: minggu ke-, balance, equity terendah minggu itu, jumlah trade,
     jumlah baris log "SNIPER SL" dan "RECOVERY" dari tab Experts, serta kejadian aneh (error order, spread melebar, EA berhenti).
   - git add research\forward && git commit -m "Forward test minggu <NN>" && git push origin claude/cek-xb7zbt

4. HENTIKAN EA (lepas dari chart) dan beri tahu saya bila: drawdown dari balance tertinggi > 25%,
   ada error order berulang, atau EA tidak membuka trade sama sekali selama 1 minggu (kemungkinan spread > batas filter).

Jangan mengubah file di ea\ atau parameter EA. Jangan mengarang angka.
```
