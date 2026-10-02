# DOKUMEN RESMI PROTOKOL DUA TINGKAT (TWO-TIER FREEZE PROTOCOL) FASE 0
## BIOONEPRO V94 FAIL-CLOSED — DEMO REPLAY FIDELITY

**Tanggal Pengesahan**: 3 Oktober 2026  
**Status**: RESMI DISEGEL & DIBEKUKAN  
**Pihak Pengesah**: Rekan Peneliti AI (Claude Sonnet 5.5 Extra di ChromeDebug) & Peneliti Utama Antigravity (Google DeepMind)  
**Tujuan Pengujian**: Uji Paritas & Fidelitas Eksekusi (Live Demo vs Strategy Tester Replay), BUKAN klaim edge statistik.

---

### Pasal 1 - Paritas P&L: Dekomposisi Bias dan Interval Kepercayaan

**1.1** Unit sampel adalah basket yang tertutup di akun demo live dan memiliki padanan di replay tester pada periode yang sama. Untuk setiap basket $i$, galat bertanda adalah:
$$e_i = \text{P\&L}_{\text{live}} - \text{P\&L}_{\text{replay}}$$
Nilainya dinormalisasi per 0.01 lot (1 oz) dan sudah memuat komisi $7.00/lot round-turn di kedua sisi.

**1.2** Setiap $e_i$ didekomposisi menjadi:
$$e_i = s_i + p_i + x_i + r_i$$
dengan komponen:
- $s_i$ = biaya slippage entry.
- $p_i$ = selisih spread saat pembukaan (live − replay).
- $x_i$ = biaya slippage/keterlambatan eksekusi exit.
- $r_i$ = residu divergensi jalur (mis. selisih bar entry $\le 1$ bar M1 atau urutan tick), dihitung sebagai $r_i = e_i - s_i - p_i - x_i$ sehingga identitas selalu tertutup.

*Catatan*: Selisih komisi live-replay wajib tepat 0.00. Nilai lain dicatat sebagai cacat integritas data, bukan komponen bias.

**1.3** Untuk $e$ dan tiap komponen dilaporkan rata-rata (bias), simpangan baku, dan CI 95% melalui bootstrap persentil level-basket (10,000 resampel, seed dicatat). MAE (rata-rata $|e_i|$) dilaporkan terpisah dan bukan syarat lulus.

**1.4 Syarat Lulus**:
- (a) $|\text{rata-rata } e| \le 25\% \times E_{\text{replay}}$, dengan $E_{\text{replay}}$ = ekspektansi replay per basket per 0.01 lot pada sampel yang sama ($E_{\text{replay}}$ historis baseline $10k = \$0.725\text{/0.01 lot}$, ambang $25\% = \$0.181\text{/0.01 lot}$).
- (b) CI 95% bias eksekusi $(s+p+x)$ seluruhnya berada dalam $\pm 25\% \times E_{\text{replay}}$.

Komponen $r$ dilaporkan beserta CI-nya tetapi bukan syarat lulus. Bila $|\text{rata-rata } r| > |\text{rata-rata } (s+p+x)|$, selisih dinyatakan bersumber dari divergensi jalur dan dinilai melalui paritas alasan exit (Pasal 5.4). Angka dolar yang tercantum di dokumen ini bersifat indikatif, sedangkan yang mengikat adalah rumus $25\% \times E_{\text{replay}}$.

---

### Pasal 2 - Satuan dan Konvensi Ukur

**2.1** Semua toleransi harga dinyatakan dalam \$/oz harga XAUUSD (kuotasi 2 desimal; 1 point = \$0.01/oz, sehingga "spread 20" = \$0.20/oz).

**2.2** Kontrak IC Markets Raw: 1.00 lot = 100 oz, jadi 0.01 lot = 1 oz dan \$1/oz setara \$1 per 0.01 lot. Komisi \$7.00/lot round-turn setara \$0.07 per 0.01 lot. Semua P&L ternormalisasi dilaporkan per 0.01 lot.

**2.3** Slippage diukur per fill (entry dan exit terpisah) sebagai selisih harga fill terhadap harga yang diminta saat order dikirim. Tanda positif berarti merugikan akun. Syarat Tier 1: rata-rata slippage bertanda $< \$0.05\text{/oz}$. Spread terbuka = $\text{ask} - \text{bid}$ pada tick fill entry. Syarat Tier 1: $\le \$0.35\text{/oz}$ pada setiap basket yang dibuka.

**2.4** Seluruh waktu dalam dokumen, log, dan replay memakai **Server Time Broker IC Markets (`Rule_Time_Mode = 0`)**, bukan GMT.

---

### Pasal 3 - Deposit Awal dan Hard Stop

**3.1** Fase 0 berjalan pada akun demo IC Markets Raw dengan deposit awal **\$10,000.00**, parameter:
- `Risk_Base_Pct` = 1.0
- `Risk_Hard_Cap_Pct` = 2.0
- `Max_Basket_Layers` = 1 (L1 Sniper Murni)
- `Rule_Time_Mode` = 0 (Server Time IC Markets)

**3.2** Puncak ekuitas fase (peak) adalah ekuitas tertinggi (saldo + floating) sejak awal fase, dengan nilai awal \$10,000.00. 
$$\text{DD} = \frac{\text{peak} - \text{ekuitas}}{\text{peak}}$$
dievaluasi pada setiap tick. Peak hanya naik dan tidak direset oleh jeda, resume, atau tinjauan.

**3.3 Hard stop terpicu bila DD > 5.5%** (= \$550.00 pada peak awal). Aksi otomatis:
- (a) Seluruh entri baru diblokir seketika.
- (b) Basket terbuka tidak dilikuidasi manual. EA mengelolanya sampai exit normal, dengan kerugian tambahan per basket dibatasi `Risk_Hard_Cap_Pct = 2.0%` saldo.
- (c) Waktu pemicu, ekuitas, peak, dan daftar basket terbuka dicatat.

**3.4** Operasi dilanjutkan hanya setelah tinjauan tertulis bertanggal yang menyimpulkan penyebabnya (kondisi pasar atau cacat eksekusi/parameter). Basket yang tidak dibuka selama masa henti tidak dihitung dalam sampel.

**3.5** DD maksimum historis tester (\$437.48 = 3.82% dari peak \$11,445) adalah episode historis saat lot minimum, bukan batas teoritis maupun ekspektasi DD normal.

---

### Pasal 4 - Jeda Streak

**4.1** Basket rugi adalah basket tertutup dengan P&L bersih $< 0$ setelah komisi. Basket yang ditutup likuidasi Jumat 19:00 dengan hasil rugi dihitung seperti basket lain. Streak dihitung menurut urutan waktu tutup di akun live (server time).

**4.2** Tiga basket rugi beruntun memicu **jeda 24 jam kalender (server time)** sejak penutupan basket ketiga. Selama jeda tidak ada entri baru, sedangkan basket terbuka berjalan normal. Streak direset oleh basket ber-P&L $\ge 0$ dan pada akhir jeda.

**4.3** Sinkronisasi dengan replay: jendela jeda live diteruskan ke replay sebagai input eksogen, sehingga replay tidak membuka entri pada jendela yang sama dan tidak muncul basket tanpa padanan. Sinyal yang tertahan dicatat dengan alasan `STREAK_PAUSE`, dikeluarkan dari penyebut paritas entry-bar dan exit-reason, dan tidak dihitung terhadap syarat $\ge 3$ veto sinyal (Pasal 5.5).

**4.4** Selama jeda wajib dilakukan audit integritas eksekusi (slippage, spread terbuka, komisi, basis waktu, kualitas fill), dan hasilnya dicatat sebelum jeda berakhir. Jeda tidak dapat dipersingkat. Jeda diperpanjang bila audit menemukan cacat.

**4.5** Bila hard stop (Pasal 3) aktif atau terpicu bersamaan, hard stop yang berlaku. Berakhirnya jeda tidak mencabut hard stop.

---

### Pasal 5 - Klausul Operasional

**5.1 Struktur Dua Tingkat**:
- **Tier 1 (Terkunci selama Fase 0)**: Basis server time; likuidasi Jumat pada candle 19:00 server time dengan toleransi 0 menit; kecocokan bar entry $\le 1$ bar M1; slippage $< \$0.05\text{/oz}$; spread terbuka $\le \$0.35\text{/oz}$; paritas alasan exit $\ge 90\%$; komisi \$7.00/lot round-turn dihitung di live dan replay; pencatatan veto/blok; kecukupan sampel (5.5); metrik bias (Pasal 1).
- **Tier 2 (Provisional)**: Hard stop 5.5% (Pasal 3) dan jeda 3 basket/24 jam (Pasal 4).

**5.2** Perubahan Tier 1 setelah segel berarti fase baru dan sampel dimulai dari nol. Tier 2 hanya dapat diubah lewat amendemen tertulis bertanggal yang memuat alasan, dibuat sebelum data periode terdampak ditinjau, dan tidak berlaku surut terhadap pemicu yang sudah terjadi.

**5.3** Setiap entri yang diblokir dicatat dengan alasan: `EMA_SLOPE_VETO`, `RISK_GATE_CAP`, `STREAK_PAUSE`, atau `HARD_STOP`.

**5.4** Paritas alasan exit $\ge 90\%$: untuk $n$ basket, ketidakcocokan maksimal $\lfloor 0.10 \times n \rfloor$, yaitu maksimal 2 dari 25 basket.

**5.5 Kecukupan Sampel**: Sampel dinyatakan cukup bila $\ge 4$ minggu penuh DAN $\ge 25$ basket, termasuk:
- $\ge 3$ kejadian penutupan Jumat 19:00 server, dan
- $\ge 3$ kejadian veto sinyal (hanya `EMA_SLOPE_VETO` dan `RISK_GATE_CAP`).  
Tidak ada pernyataan lulus/gagal sebelum seluruh syarat terpenuhi; pemantauan hard stop tetap berjalan.

---

### Lampiran Integritas Kode & Hash SHA-256
- `ea/BioOnePro_v94_FailClosed.mq4`:
  `SHA-256: d55e3c725c4f27a5b1c40d84cd83e82a8472f4572d32dd399b284412d003f41a`
- `ea/BioOnePro_v94_FailClosed.ex4`:
  `SHA-256: 8698f37adf10395486a06a3e21fe6e876550832f9d361d7f424999eb4e323846`
- `research/presets/BioOnePro_v94_Phase0_Demo.set`:
  `SHA-256: 22a85552eb28fbcbacb549f9256a771fa35fcab9b19167d7b6d1741338c7e4e0`
- `backtests/runs/V94_10K_RISK1PCT_FULL.htm`:
  `SHA-256: 8ff72d9ccfa2beeba9f5c772b2d88dd3ad075e0c36057a152eebde42a9cbaa9d`

