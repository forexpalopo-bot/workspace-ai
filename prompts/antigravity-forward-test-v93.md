# Prompt Antigravity — Forward Test Demo v93 (A: VH1 vs B: SL intrabar = v91 P2)

```text
Forward test EA BioOnePro v93 di akun DEMO. JANGAN PERNAH memakai akun real.
Forward test lama (E2_Final, jam server) DIHENTIKAN dan diganti dengan ini.

0. Pertanyaan dulu (jawab di research\NOTES.md bagian "Jawaban Antigravity putaran 24", maksimal 8 baris):
   Laporan VQ3_P2, VH1_P2, dan V2_P2 punya 521 trade yang SAMA PERSIS, padahal V2 tidak memakai konfirmasi SL.
   Lihat log tester run VQ3_P2 untuk 3 penutupan rugi besar 2025 (2025.05.01 01:06, 2025.06.24 00:03, 2025.06.27 13:04):
   pesan apa yang menutupnya ("SNIPER SL", "SNIPER TREND STOP", "BATAS RUGI", "WEEKEND", lainnya)? Kutip barisnya apa adanya.
   Jika log sudah tidak ada, jalankan ulang VQ3 periode P2 (model 1 cukup) lalu cari barisnya.

1. Di C:\Penelitian_EA\BioOnePro\repo: git checkout claude/cek-xb7zbt && git pull
   Salin ea\BioOnePro_v93_NewsTime.mq4 ke <folder data>\MQL4\Experts\ lalu kompilasi (0 error dan 0 warning wajib).

2. Siapkan DUA akun DEMO IC Markets Raw, masing-masing balance $3000 (minta saya membuatnya bila belum ada):
   - Akun A: chart XAUUSD M1, EA v93, Load preset research\presets\BioOnePro_v93_VH1.set
   - Akun B: chart XAUUSD M1, EA v93, Load preset research\presets\BioOnePro_v93_SLIntrabar_P2.set
   Pastikan Rule_Time_Mode = 1 di keduanya (jam aturan otomatis GMT). Centang "Allow live trading", aktifkan AutoTrading.
   MT4 menyala terus (VPS lebih baik). Dua akun bisa memakai dua folder instalasi MT4 terpisah.

3. Catat di research\forward\LOG_v93.md: tanggal mulai, nomor akun A/B, balance awal, selisih jam server terhadap GMT
   (Market Watch vs jam GMT), rata-rata spread XAUUSD, komisi per lot.

4. Setiap Sabtu, untuk akun A dan B:
   - Account History > All History > Save as Detailed Report -> research\forward\A-minggu-<NN>.htm dan B-minggu-<NN>.htm
   - 1 baris per akun di LOG_v93.md: minggu, balance, equity terendah, jumlah trade, jumlah "SNIPER SL", jumlah "WEEKEND",
     kejadian aneh (error order, spread melebar, EA berhenti).
   - git add research\forward && git commit -m "Forward test v93 minggu <NN>" && git push origin claude/cek-xb7zbt

5. HENTIKAN EA di akun terkait dan beri tahu saya bila: drawdown dari balance tertinggi > 30%, error order berulang,
   atau tidak ada trade selama 1 minggu penuh.

Jangan mengubah file di ea\ atau parameter preset. Jangan mengarang angka.
```
