# Log Forward Test BioOnePro v93 (Dua Akun DEMO)

Forward test lama (E2_Final, jam server) telah dihentikan dan digantikan secara resmi oleh forward test v93 ini.

---

## 1. Informasi Akun & Lingkungan

### Akun A (Preset VH1 — Konfirmasi Bar Close H4)
- **Status**: Menunggu pembuatan/input akun dari user
- **Tanggal Mulai**: 2026-10-02
- **Broker / Server**: IC Markets (SC) / ICMarketsSC-Demo01 (Raw Trading Ltd)
- **Nomor Akun Demo A**: *(diisi nomor akun)*
- **Tipe Akun**: Raw Spread (Demo)
- **Balance Awal**: $3,000.00
- **Pair / Timeframe**: XAUUSD, M1
- **EA**: `BioOnePro_v93_NewsTime.ex4`
- **Preset**: `research/presets/BioOnePro_v93_VH1.set`
  - `Rule_Time_Mode`: 1 (Jam aturan otomatis GMT)
  - `Sniper_SL_Confirm_TF`: 240 (H4 close confirmation)
  - `Sniper_SL_Hard_Mult`: 1.30 (Batas keras 1.3x)
  - `Use_News_File`: 0 (Filter berita OFF)
- **Selisih Jam Server thd GMT**: GMT+3 (musim panas EDT) / GMT+2 (musim dingin EST)
- **Rata-rata Spread XAUUSD**: ~10–15 points ($0.10–$0.15)
- **Komisi per Lot**: ~$7.00 per lot round turn

### Akun B (Preset SLIntrabar_P2 — Setara v91 P2 Intrabar)
- **Status**: Menunggu pembuatan/input akun dari user
- **Tanggal Mulai**: 2026-10-02
- **Broker / Server**: IC Markets (SC) / ICMarketsSC-Demo01 (Raw Trading Ltd)
- **Nomor Akun Demo B**: *(diisi nomor akun)*
- **Tipe Akun**: Raw Spread (Demo)
- **Balance Awal**: $3,000.00
- **Pair / Timeframe**: XAUUSD, M1
- **EA**: `BioOnePro_v93_NewsTime.ex4`
- **Preset**: `research/presets/BioOnePro_v93_SLIntrabar_P2.set`
  - `Rule_Time_Mode`: 1 (Jam aturan otomatis GMT)
  - `Sniper_SL_Confirm_TF`: 0 (SL Intrabar murni)
  - `Sniper_SL_Hard_Mult`: 1.30
  - `Use_News_File`: 0 (Filter berita OFF)
- **Selisih Jam Server thd GMT**: GMT+3 (musim panas EDT) / GMT+2 (musim dingin EST)
- **Rata-rata Spread XAUUSD**: ~10–15 points ($0.10–$0.15)
- **Komisi per Lot**: ~$7.00 per lot round turn

---

## 2. Aturan Penghentian EA (Circuit Breaker)
Hentikan EA di akun terkait dan laporkan bila:
1. **Drawdown**: Drawdown dari balance tertinggi > 30%.
2. **Error Order**: Error order berulang di tab Experts / Journal.
3. **Inaktivitas**: Tidak ada trade selama 1 minggu penuh.

---

## 3. Catatan Pemantauan Mingguan (Setiap Sabtu)
Laporan detail mingguan disimpan sebagai:
- Akun A: `research/forward/A-minggu-<NN>.htm`
- Akun B: `research/forward/B-minggu-<NN>.htm`

| Minggu | Akun | Balance ($) | Equity Terendah ($) | Trades | SNIPER SL | WEEKEND | Kejadian Aneh / Catatan | Status |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|:---:|
| M-01 | A (VH1) | | | | | | Setup awal | Aktif |
| M-01 | B (P2)  | | | | | | Setup awal | Aktif |
