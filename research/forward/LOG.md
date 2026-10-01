# Log Forward Test BioOnePro E2 Final (Akun DEMO)

## 1. Informasi Akun & Lingkungan
- **Tanggal Mulai**: 
- **Broker / Server**: IC Markets (SC) / ICMarketsSC-Demo01 (Raw Trading Ltd)
- **Nomor Akun Demo**: 
- **Tipe Akun**: Raw Spread (Demo)
- **Balance Awal**: $3,000.00
- **Pair / Timeframe**: XAUUSD, M1
- **EA**: BioOnePro_E2_Final.ex4 (Default Settings E2)
- **Rata-rata Spread XAUUSD**: 
- **Komisi Akun Raw**: ~$7.00 per lot round turn

## 2. Aturan Circuit Breaker (Hentikan EA & Lepas dari Chart)
1. **Drawdown**: Drawdown dari balance tertinggi > 25%.
2. **Error Order**: Error order berulang di tab Experts / Journal.
3. **Inaktivitas**: EA tidak membuka trade sama sekali selama 1 minggu (indikasi spread > batas filter atau AutoTrading mati).

## 3. Catatan Pemantauan Mingguan (Setiap Sabtu)
| Minggu | Periode | Balance | Min Equity | Trades | SNIPER SL | RECOVERY | Kejadian Aneh / Catatan | Status |
|---|---|---|---|---|---|---|---|---|
| M-01 | | | | | | | | Berjalan |

*(Laporan detail mingguan disimpan di `research/forward/minggu-<NN>.htm`)*
