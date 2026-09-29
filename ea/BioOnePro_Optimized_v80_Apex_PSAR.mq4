//+------------------------------------------------------------------+
//|                  BioOnePro_Institutional_v5.25.mq4               |
//|               Smart Breakeven Lock, Rollover Guard,              |
//|      Trend-Directional Entry, Pure Recovery Averaging & Risk Guard|
//|                                               Copyright 2025,ih1 |
//|                                              Wawan 085218181004  |
//+------------------------------------------------------------------+
// v78 (5.23) - perubahan dari v77 (5.22):
//  1. Order Hedge Guard (Magic+777) ikut dikelola cut-loss akun, close-all,
//     dan weekend close (sebelumnya bisa tertinggal terbuka).
//  2. Hedge dibuka lewat OPE(): normalisasi lot, cek margin, dan retry.
//  3. Lot averaging hanya dihitung saat jarak grid tercapai (backtest lebih cepat).
//  4. Ukuran pip seragam memakai pt (menghormati Pip_Unit_Override).
//  5. Grid Risk Report: jarak harga yang memicu cut-loss Percent_Loss.
//  6. Opsi Survive_Adverse_Move_Pips dan Max_L1_Lot untuk membatasi lot L1.
//  7. Opsi kunci profit minimum L1 (komisi + buffer) pada trailing.
//  Dengan input baru di nilai default (0), hasil trading identik dengan v77.
// v79 (5.24):
//  8. Partial Pair Close (default off): profit layer terbaru dipakai menutup
//     sebagian/seluruh layer tertua (L1) yang rugi, agar eksposur basket
//     dalam mengecil sebelum mendekati cut-loss Percent_Loss.
//     (Hasil backtest putaran 1: ditolak, relative DD naik ke 61-79%.)
// v80 (5.25):
//  9. PSAR Averaging Gate (default off): layer averaging tidak dibuka saat jarak grid
//     tercapai, tetapi "di-arm" lalu baru dibuka setelah Parabolic SAR berbalik searah
//     basket (harga berhenti jatuh), selama harga masih >= PSAR_Arm_Min_Fraction x step.
// 10. PSAR L1 Filter (default off): L1 hanya searah posisi Parabolic SAR di timeframe pilihan.
#property copyright "Copyright 2025,ih1"
#property link      "@ih1"
#property version   "5.25"
#property description "BioOnePro Institutional Edition v80 - Trend Directional & Pure Recovery Averaging System (Risk Guarded)"

#define HEDGE_MAGIC_OFFSET       777
#define ADAPTIVE_LOT_MAX_FACTOR  1.35

extern string          System_Setting           = "-----------------  BioOnePro Institutional v5.22  ------------------";
extern bool            Trade_Buy                = true;
extern bool            Trade_Sell               = true;
extern bool            Dual_Mode                = true;
extern bool            OFF_EA_Target_Done       = false; // false agar backtest/trading berlanjut
extern bool            Auto_Compounding_Lot             = true; // Opsi auto-compounding lot proporsional
extern double          Lot_Base_Balance_Safe = 400.0; // DITURUNKAN ke 400: Sistem lebih aman, compounding dipercepat!
extern bool            Compound                 = false;
extern double          Ketahanan_pip            = 1000;   // estimasi jarak ketahanan untuk lot compound (pips EA)
extern double          Lot                      = 0.01;
extern double          TP                       = 10000; // TP MAKSIMAL (100 pips): Biarkan Stoch M5 yang mencari pucuk!
extern double          SL                       = 0;
extern bool            Use_TP_InMoney           = false;
extern double          Target_Dollar            = 10; 
extern bool            Use_SL_inPercent         = true;
extern double          Percent_Loss             = 50.0;  // aggregate floating-loss circuit breaker untuk semua order EA (Opsi B: 25%)
extern bool            Use_SL_inMoney           = false;
extern double          Loss_inMoney             = 25;
extern bool            Stop_After_Account_Loss  = false; // false agar backtest/trading berlanjut setelah cut loss

extern string          Plihan_System            = "=================== CONTROL & AVERAGING ===================";
extern bool            Use_Trend_Directional_Entry = true; // REVOLUTIONARY: Ubah entry searah tren H1 untuk mengeliminasi loss besar
extern bool            Use_Breakeven_Lock       = true;  // SMART BE: Kunci profit saat L1 mencapai target tertentu
extern double          Breakeven_Trigger_Pips   = 1500;  // Pemicu geser SL ke BE (1500 pips = $15.0)
extern double          Breakeven_Buffer_Pips    = 300;   // Profit terkunci di atas entry (300 pips = $3.0)
extern bool            Avoid_Rollover_Hours     = true;  // Hindari open L1 baru saat jam rollover New York (spread tinggi)
extern int             Rollover_Start_Hour      = 23;    // Mulai jam rollover
extern int             Rollover_End_Hour        = 0;     // Akhir jam rollover
extern double          Pipstep_Exponent         = 1.30; // PENELITIAN: Diturunkan dari 1.30 ke 1.15 agar jarak layer-layer dalam tidak terlalu melebar, mempercepat pantulan profit L3+
extern bool            Cut_Switch               = false;
extern bool            Averaging_New_Candle     = false; // false = eksekusi averanging instan saat jarak tercapai
extern bool            Use_Martiangle           = true;
extern bool            Use_Avg_Indicator_Filter = false; // Filter indikator L2+ DIMATIKAN (Bahaya Retracement Paradox)
extern int             Avg_Filter_TF            = 5;    // Timeframe M5 untuk akurasi pullback
extern int             Avg_RSI_Period           = 14;
extern double          Avg_RSI_Oversold         = 35.0; // Syarat OP Buy Averaging
extern double          Avg_RSI_Overbought       = 65.0; // Syarat OP Sell Averaging
extern bool            UseTrailingStop          = true;
extern double          TrailingStop             = 400; // Trail diaktifkan pada 40 pips untuk mengunci BEP di 25 pips jika gagal mencapai TP 50 pips.
extern double          Step                     = 150;   // Step 15 pips

// NEW: Adaptive Trailing Stop (Rhythm of the Market)
extern bool            Use_Adaptive_Trailing    = false; // Aktifkan trail berbasis ATR
extern int             Adaptive_Trail_TF        = 1; // Timeframe M1 untuk sensitivitas tertinggi
extern int             Adaptive_Trail_Period    = 14;    // Periode ATR
extern double          Adaptive_Trail_ATR_Mult  = 12.0; // Pengali 12x karena ATR M1 sangat kecil
extern double          Adaptive_Step_ATR_Mult   = 5.0; // Step 5x ATR M1

// NEW: Stochastic M1 Adaptive Trailing (L1 and Basket)
extern bool            Use_Stoch_Trailing_L1    = true; // DIAKTIFKAN: Stoch M5 akan mencari pucuk L1 sejauh mungkin!
extern bool            Use_Stoch_Trailing_Basket = true; // AKTIFKAN untuk Basket agar lolos DD
extern int             Stoch_Trail_TF           = 5; // Gunakan TF M5 agar terhindar dari noise/whipsaw M1
extern int             Stoch_Trail_K            = 21; // M5 + 21 = 105 menit (Golden ratio untuk swing intraday XAU)
extern int             Stoch_Trail_D            = 3;
extern int             Stoch_Trail_Slowing      = 3;
extern int             Stoch_Trail_OB           = 85; // Diperbesar ke 85 agar lebih sabar menahan profit
extern int             Stoch_Trail_OS           = 15; // Diperkecil ke 15 agar lebih sabar menahan profit
extern double          Stoch_Basket_Lock_Dollar = 1.0; // Minimal net profit untuk lock Stoch

extern double          Averaging_Lot_Multiplier = 1.70; // 1.70 adalah rasio emas untuk mempercepat BEP tanpa memberatkan Drawdown.
extern double          Averaging_Lot_Multiplier_L2 = 1.60; // 1.60 L2
extern bool            Use_Adaptive_Lot_Multiplier = true; // NEW HYBRID: Dihidupkan kembali dengan proporsi Reversal Jarak Historis
extern double          Adaptive_Lot_Target_BEP_Fraction = 0.35; // Target jarak BEP (0.35 = 35% dari gap terakhir)
extern bool            Use_Historical_Hour_Filter = false; // KESIMPULAN: Fitur ini terlalu memotong frekuensi L1 (menurunkan profit drastis)
extern double          TP_Averaging             = 15;     // PENELITIAN: Diturunkan dari 20 ke 15. Mempercepat Take Profit tanpa merusak mekanika lot.
extern double          Grid_Pipstep             = 1500; // Dikembalikan ke 1500 persis v36
extern double          TP_Averaging_L4Plus      = 10;     // hanya mode price-TP (Use_Net_Basket_Profit_Close=false)
extern double          Basket_Stop_Below_BEP_Pips = 0.0;  // 0=off; // L2+ stop di bawah/atas BE basket

//==================== NET BASKET PROFIT CLOSE ====================
// Close basket berdasarkan NET profit riil: OrderProfit + Swap + Commission.
// Menutup seluruh keranjang dalam kondisi PROFIT segera setelah terjadi koreksi harga.
extern bool            Use_Net_Basket_Profit_Close       = true;
extern double          Basket_Target_L2_Net = 6.00; // NAIK 50%: Stoch M5 Safety Net mengizinkan target lebih jauh
extern double          Basket_Target_L3_Net = 9.00; // NAIK 50%: Stoch M5 akan cut jika gagal mencapai 9.0
extern double          Basket_Target_L4Plus_Net = 15.00; // PROFIT MAKSIMAL: L4+ bisa panen $15 karena dilindungi Stoch
extern double          Basket_Close_Trigger_Buffer_Dollar= 0.25; // buffer untuk slippage saat close berurutan
extern bool            Use_Cost_Adjusted_Basket_TP       = true; // hanya mode price-TP (Use_Net_Basket_Profit_Close=false)
extern bool            Basket_Profit_Debug               = false;

extern bool            Use_Trailing_Basket               = true; // Mode trail profit basket
extern double          Basket_Trailing_Step_Dollar       = 0.50; // Diperketat menjadi 0.50. Mengunci lebih banyak profit saat basket profit pullback.
double                 highestBuyBasketNet               = -999999;
double                 highestSellBasketNet              = -999999;
bool                   isBuyEscapeArmed                  = false;
bool                   isSellEscapeArmed                 = false;
extern double          Basket_Close_Safety_Reserve_Dollar  = 0.50;
extern double          Basket_Close_Slippage_Reserve_Pips  = 5.0;
extern bool            Stop_Modify_Debug                   = false;

//==================== HYBRID / ADAPTIVE Grid_Pipstep XAUUSD ====================
extern bool            Use_Hybrid_Pipstep                = false;
extern bool            Use_BB_Adaptive_Pipstep           = false;  // NEW: Gunakan BB Bandwidth untuk mengatur Grid_Pipstep adaptif
extern double          BB_Pipstep_Fraction               = 0.40;  // NEW: Grid_Pipstep = 40% dari lebar Bollinger Band
extern bool            Use_L2Plus_BB_Volume_Filter       = false;  // NEW: Kombinasi Volume + BB untuk filter L2+
extern double          L2Plus_Volume_Climax_Factor       = 1.5;   // NEW: Volume harus 1.5x lebih besar dari rata-rata (Volume Climax)
extern double          Minimum_Pipstep                   = 1200;  // minimum absolut saat compress
extern int             Pipstep_ADR_Fast_Days             = 5;     // karakter pergerakan harian terbaru
extern int             Pipstep_ADR_Slow_Days             = 20;    // baseline volatilitas harian
extern double          Pipstep_Adaptive_Max_Factor       = 1.55;  // batas adaptif dari perubahan ADR
extern double          Pipstep_Absolute_Max_Factor       = 1.65;  // batas absolut setelah tekanan range hari berjalan
extern double          Pipstep_Today_Range_Trigger       = 0.70;  // ekspansi tambahan setelah range hari ini >=70% ADR5
extern double          Pipstep_L2_Mult                   = 1.00;
extern double          Pipstep_L3_Mult                   = 1.10; // Semula 1.20
extern double          Pipstep_L4_Mult                   = 1.30; // Semula 1.50
extern double          Pipstep_L5Plus_Mult               = 1.50; // Semula 2.50. Diperkecil agar L5 cepat keluar

extern int             Pipstep_L2_Cap                     = 1500;
extern int             Pipstep_L3_Cap                     = 2200;
extern int             Pipstep_L4_Cap                     = 3000;
extern int             Pipstep_L5Plus_Cap                 = 4000;
extern double          Pipstep_Global_Max                = 3000;
extern double          Min_Hours_Between_L2Plus          = 0.0;   // 0 = Tanpa jeda jam, averaging lancar dibuka saat Grid_Pipstep tercapai
extern double          Min_Hours_L4_to_L5                = 0.0;   // 0 = Tanpa jeda jam
extern bool            Pipstep_Debug                     = false;

//==================== REGIME / RISK GUARD ====================
extern bool            Use_Trend_Regime_Guard             = true;
extern int             Trend_Timeframe                    = PERIOD_H1;
extern int             Trend_Fast_EMA                     = 50; // DEFAULT KEMBALI: 50 (Macro Trend)
extern int             Trend_Slow_EMA                     = 200; // DEFAULT KEMBALI: 200 (Macro Trend)
extern int             Trend_ATR_Period                   = 14;
extern int             Trend_Slope_Bars                   = 3;
extern double          Min_EMA_Spread_ATR           = 0.0; // Sebelumnya Trend_Min_EMA_Spread_ATR. 0.0 = Frekuensi OP Maksimal (Full bersandar pada MACD & ADX)
extern bool            L1_Block_Strong_CounterTrend       = true;
extern bool            Averaging_Block_Strong_CounterTrend= false;  // false = Biarkan averaging memindahkan TP lebih dekat
extern int             Averaging_Block_From_Existing      = 4;     // Opsi B: Blokir mulai layer 2 jika berlawanan tren
extern int             Min_Minutes_Between_Layers         = 3;     // Waktu tunggu dasar untuk L2
extern int             Min_Minutes_Between_L3             = 3;     // KESIMPULAN: Jeda waktu (15-30m) menghancurkan kepadatan Grid
extern int             Min_Minutes_Between_L4Plus         = 120;   // L4+ wajib jeda minimal 2 jam (120 mnt) agar terhindar dari flash crash
extern double          Pipstep_H1_ATR_Fraction            = 0.70; // dynamic floor from H1 ATR
extern double          Pipstep_Adverse_Trend_Mult         = 1.20; 

// Side basket protection (dinonaktifkan agar tidak melakukan cut loss dini saat averaging sedang bekerja)
extern bool            Use_Side_Basket_Loss_Guard         = false; // MATIKAN: Matematika Black Swan v56 sudah cukup kuat. Cut loss manual hanya mengganggu.
extern double          Side_Basket_Max_Loss_Pct           = 40.0; 
extern bool            Use_Anomaly_Emergency_Close        = false; // MATIKAN: Anomaly cut loss 15% terlalu ketat untuk EA Grid. // NEW: Deteksi pergerakan anomali
extern double          Anomaly_Emergency_Loss_Pct         = 15.0; // NEW: Cut lebih awal (15%) jika ada anomali
extern bool            Use_Time_Decay_Risk_Guard          = false; // KESIMPULAN: Time Decay membunuh EA Grid saat sideways. // NEW: Susutkan batas Cut Loss jika ditahan terlalu lama
extern double          Time_Decay_Start_Hours             = 6.0;  // Mulai menyusut setelah 6 jam
extern double          Time_Decay_End_Hours               = 18.0; // Maksimal penyusutan setelah 18 jam
extern double          Time_Decay_Min_Loss_Pct            = 15.0; // Batas cut loss mengecil jadi 15% (dari 40%)
extern int             Side_Basket_Stop_Min_Orders        = 4;
extern double          Side_Basket_Risk_Trigger_Buffer_Pct = 0.50; 

// L4 Hedge Guard (Symmetrical Lock)
extern bool            Use_L4_Hedge_Guard                 = true;  // NEW: Tambahkan posisi berlawanan pada L4
extern int             Hedge_Activation_Layer             = 4;     // Aktif saat Averaging mencapai layer ini
extern double          Hedge_Lot_Ratio                    = 1.0;   // 1.0 = Lot hedge sama dengan lot averaging terakhir
extern double          Hedge_Trailing_Start_Pips          = 30.0;  // Kunci profit hedge jika sudah +30 pips
extern double          Hedge_Trailing_Step_Pips           = 15.0;  // Jarak trail 15 pips

// Escape Guard (Bailout)
extern bool            Use_Escape_Guard                   = true;
extern int             Escape_Min_Layers                  = 4;     // Aktif mulai layer ke-4
extern double          Escape_Activation_Dollar           = -2.0;  // Aktif jika basket nyaris BEP (-$2)
extern double          Escape_CutLoss_Dollar              = -10.0; // Cut loss di -$10 jika harga berbalik melawan kita setelah nyaris BEP

// L3+ Best Position (Candle Confirmation)
extern bool            Use_L3Plus_Candle_Confirm          = true; // Aktifkan untuk hindari Falling Knife!
extern int             L3Plus_Confirm_Min_Layer = 1; // Berlaku mulai dari L2 (Index 1). Akurasi L2+ naik 100%!

// Dynamic risk guard
extern bool            Use_Dynamic_Basket_Risk_Guard       = false; // false = Tidak membekukan averaging
extern double          Dynamic_Risk_L2_Pct                 = 10.0;
extern double          Dynamic_Risk_L3_Pct                 = 10.0;
extern double          Dynamic_Risk_L4Plus_Pct             = 10.0;
extern double          Dynamic_Risk_Adverse_Trend_Mult     = 1.0;
extern double          Dynamic_Risk_Age_Soft_Hours         = 24.0;
extern double          Dynamic_Risk_Age_Hard_Hours         = 48.0;
extern double          Dynamic_Risk_Age_Soft_Mult          = 1.0;
extern double          Dynamic_Risk_Age_Hard_Mult          = 1.0;
extern double          Dynamic_Risk_Min_Pct                = 8.0;
extern double          Dynamic_Risk_Max_Pct                = 15.0;

extern double          Averaging_Freeze_Trigger_Fraction   = 0.99; // Tidak membekukan averaging
extern double          Averaging_Freeze_Age_Hours          = 99.0;
extern double          Averaging_Freeze_Aged_Fraction      = 0.99;

extern bool            Use_Risk_Stop_Cooldown              = false; // false = Re-entry tidak dihambat
extern double          Risk_Stop_Cooldown_Hours            = 0.0;

extern double          Pipstep_Risk_Pressure_Max_Mult      = 1.0;
extern bool            Dynamic_Risk_Debug                  = false;

// Margin protection
extern bool            Use_Averaging_Margin_Guard         = true;
extern double          Min_Projected_Margin_Level_Pct     = 10.0;
extern double          Min_FreeMargin_After_Avg_PctEquity = 5.0;
extern bool            RegimeGuard_Debug                  = false;
extern int             Max_Buy_Layers           = 7; // Max 7 layer
extern int             Max_Sell_Layers          = 7; // Max 7 layer
extern int             Magic                    = 2025;
extern int             Slippage                 = 3;

// Execution / Broker safety
extern int             Trade_Close_Retry_Attempts        = 4;
extern int             Trade_Close_Retry_Delay_MS        = 150;
extern double          Pip_Unit_Override                 = 0.0;
extern bool            Pip_Calibration_Debug             = false;

//==================== v78: RISK VISIBILITY & COST GUARD ====================
extern string          v78_Risk_Setting                  = "=========== v78 RISK & COST GUARD ===========";
extern bool            Print_Grid_Risk_Report            = true;  // Cetak tabel risiko grid ke tab Experts/Journal saat EA start
extern double          Survive_Adverse_Move_Pips         = 0.0;   // 0=off. >0: lot L1 dikecilkan agar grid penuh belum menyentuh Percent_Loss sebelum harga bergerak sejauh ini melawan L1 (XAUUSD 3 digit: 10000 = $100)
extern double          Max_L1_Lot                        = 0.0;   // 0=off. Batas atas lot L1 hasil auto-compounding
extern double          Commission_Per_Lot_RoundTurn      = 0.0;   // USD per 1 lot pulang-pergi (mis. akun Raw ~7.0). 0=abaikan
extern double          Min_L1_Lock_Pips                  = 0.0;   // Profit minimum (pips EA) di atas komisi yang dikunci trailing L1. 0=off

//==================== v79: PARTIAL PAIR CLOSE ====================
// Semua loss besar di backtest v77 adalah L1 yang ditahan di basket 3 layer (hingga -$1,792).
// Saat layer terbaru sudah profit, profitnya dipakai untuk menutup sebagian lot layer tertua yang rugi.
extern string          v79_PairClose_Setting             = "=========== v79 PARTIAL PAIR CLOSE ===========";
extern bool            Use_Partial_Pair_Close            = false; // Aktifkan pair close layer terbaru + layer tertua
extern int             Pair_Close_Min_Layers             = 3;     // Berlaku saat basket punya >= layer ini
extern double          Pair_Close_Min_Net_Dollar         = 1.0;   // Net minimal (x skala lot) yang harus tersisa sebagai profit dari pasangan
extern double          Pair_Close_Min_Basket_DD_Pct      = 0.0;   // Hanya aktif bila rugi basket >= % balance ini. 0 = selalu

//==================== v80: PARABOLIC SAR ====================
// Drawdown terbesar datang dari layer yang dibuka saat harga masih "jatuh bebas".
// Gate ini menunda layer sampai PSAR berbalik, sehingga layer masuk lebih dekat ke titik balik.
extern string          v80_PSAR_Setting                  = "=========== v80 PARABOLIC SAR ===========";
extern double          PSAR_Step                         = 0.02;
extern double          PSAR_Max                          = 0.20;
extern bool            Use_PSAR_Averaging_Gate           = false; // Tunda layer averaging sampai PSAR searah basket
extern int             PSAR_Avg_TF                       = 15;    // Timeframe PSAR untuk gate averaging (menit)
extern double          PSAR_Arm_Min_Fraction             = 0.50;  // Layer yang sudah di-arm tetap boleh dibuka bila jarak >= fraksi step ini
extern bool            Use_PSAR_L1_Filter                = false; // L1 BUY hanya bila SAR di bawah harga, SELL bila SAR di atas
extern int             PSAR_L1_TF                        = 15;    // Timeframe PSAR untuk filter L1 (menit)

extern bool            Use_Dynamic_Spread_Filter         = true;
extern double          Base_Max_Spread_Pips              = 25.0;  // Diperketat: Max spread 25 pips
extern double          Spread_ATR_Allowance_Fraction     = 0.005;
extern double          Absolute_Max_Spread_Pips          = 45.0; 
extern bool            Spread_Filter_Debug               = false;

extern string          Account_Target_Setting  = "================ ACCOUNT-LEVEL TARGETS ================";
extern bool            Use_Target_persen_profit = false;
extern double          Persen_profit            = 5.0;
extern bool            use_daily_target         = false;
extern double          daily_target             = 100.0;
extern bool            Use_Target_Equity_Plus   = false;
extern double          Jumlah_Equity_Plus       = 200.0;
extern bool            Use_Equity_target        = false;
extern double          Target_Equity            = 1000.0;
extern bool            Use_Target_Equity_Minus  = false;
extern double          Jumlah_Equity_Minus      = 0.0;
extern string          com                      = "BioOnePro-ADX-TrendShield-L7";
extern bool            Time_Filter              = true; // Aktifkan untuk menghindari jebakan sesi Asia awal
extern int 	           Jam_Mulai                = 3;    // Mulai OP L1 jam 3 waktu broker (Menghindari tren liar tengah malam)
extern int             Jam_Akhir                = 24;
extern bool            Close_Baskets_Before_Weekend       = true;  // DIKEMBALIKAN: Mencegah GAP mematikan di hari Senin yang merusak kualitas tes
extern int             Friday_Close_Hour                   = 19;    // Dimajukan ke 19:00 (broker Gold sering tutup lebih awal dari Forex)
extern int             Friday_Close_Minute                 = 00;

// Compatibility & Tester
extern bool            Enforce_Account_Whitelist            = false;
extern long            Allowed_Account_1                    = 12690728;
extern long            Allowed_Account_2                    = 50051686;
extern bool            Disable_Timer_In_Tester              = true;
extern bool            Tester_Diagnostic_Log                = true;
extern bool            Auto_Resume_In_Tester                = true;

// Filter L1 Volume Reversal
input bool              Use_L1_Volume_Reversal          = false; // DIMATIKAN: Membunuh frekuensi OP, cooldown searah sudah cukup
input bool              Use_L1_Volume_Staircase         = false; // DIMATIKAN: Terlalu ketat dan membunuh frekuensi OP
input int               L1_Volume_Staircase_TF          = 5;     // NEW: Timeframe untuk Volume Staircase (1, 5, 15, 30, 60)
extern string          noteL1Volume                     = "<<<<==== L1 Volume Reversal ARMED Filter ====>>>>";
extern double          L1_Volume_Min_Growth_Pct         = 0.0;   
extern bool            L1_Volume_Use_Average_Filter     = false; 
extern int             L1_Volume_Avg_Period             = 20;
extern double          L1_Volume_Climax_Multiplier      = 0.0;   
extern int             L1_Volume_Armed_Bars             = 5;     
extern bool             L1_Volume_Require_Price_Confirm  = true; 

extern double           Max_L1_Candle_Size_Pips          = 200.0;  // BLOCKER: Jangan tangkap pisau jatuh jika panjang candle > 200 pips (M1 Gold)

extern int              L1_Stoch_Min_Confirmations       = 1;     
extern int              L1_Stoch_Lower_Level             = 35;    // Diperketat: Hanya Buy saat Stoch <= 35
extern int              L1_Stoch_Upper_Level             = 65;    // Diperketat: Hanya Sell saat Stoch >= 65
extern int              L1_SRBB_Min_Score                = 3;     // Diperketat: Minimal skor SR/BB = 3
extern bool             L1_SRBB_Debug                    = false;
extern bool             L1_Volume_Debug                  = false;
extern bool             L1_Entry_Debug                   = false;

input bool              Use_SR_BB_Entry          = true;
input string            noteSRBB                 = "<<<==== Support Resistance + Bollinger Entry ====>>>";
extern int              SR_Lookback              = 185;      
extern int              SR_SwingDepth            = 2;       
extern int              ATR_Period_SRBB          = 14;
extern double           SR_Zone_ATR_Mult         = 0.20;    
extern int              BB_Period                = 20;
extern double           BB_Deviation             = 2.2;
extern int              BB_Shift                 = 0;
extern int              BB_AppliedPrice          = PRICE_CLOSE;
extern bool             Require_BB_Mid_Slope     = true;
extern double           Min_Room_ATR_Target      = 0.80;    
extern bool             Use_SR_BB_For_Averaging  = false; // false = Averaging murni berbasis jarak harga

input bool     Use_MACD_Filter        = true;
input string   note12_macd            = "<<<==== MACD Trend Filter ====>>>";
extern int     MACD_Fast              = 12;
extern int     MACD_Slow              = 26;
extern int     MACD_Signal            = 9;

input bool     Use_ADX_Filter         = true;
input string   note12_adx             = "<<<==== ADX Trend & Tsunami Filter ====>>>";
extern int     ADX_Period             = 14;
extern double  ADX_Max_Level          = 32.0; 

input bool     Use_MA_Filter          = false;
input string   note12_ma              ="<<<==== Set MA Filter ====>>>";
extern int     MA_Filter_Period       = 100;
extern int     MA_Filter_Method       = MODE_EMA;
extern int     MA_Filter_Timeframe    = PERIOD_H1;

input bool     UsedRSI                =false;
input string   note12                 ="<<<==== Set RSI ====>>>";
extern int     RSI_Period             = 14;
extern int     RSI_Upper_Level        = 70;
extern int     RSI_Lower_Level        = 30;

input bool     UsedStoc               =false;
input string   note13                 ="<<<==== Set Stochastic ====>>>";
extern int     input22               = 24;
extern int     input23               = 6;
extern int     input24               = 6;
extern int     input26               = 70;
extern int     input25               = 30;

input bool     UsedStoci2               =true;
input string   note13i                 ="<<<==== Set Stochastic ====>>>";
extern int     input22i               = 5;
extern int     input23i               = 3;
extern int     input24i               = 2;
extern int     input26i               = 70;
extern int     input25i               = 30;

extern string          News_Filter              = "----------EA otomastis ON/OFF ketika ada NEWS----------";
extern bool            AvoidNews                = false;
extern bool            News_Filter_Fail_Closed  = true;  
extern string          News_Impact              = "3=High; // 2=Medium; 1=Low";
extern int             MinimumImpact            = 3;
extern int             MinsBeforeNews           = 30;
extern int             MinsAfterNews            = 120;
//--------------------------------------------------------------
int           wt, wk, timeprev;
datetime      gRiskStopBuyUntil  = 0;
datetime      gRiskStopSellUntil = 0;
double        gd_356;
double        Buy, lotbuy, lotsbuy, Sell, lotsell, lotssell, SUM, SWAP, profitbuy, profitsell, OP, pt, dg,
              sumbuy, sumsell, bepbuy, bepsell, lowlotbuy, lowlotsell, hisell, lobuy;
int           bar = 0, TimeBUY, TimeSELL;
int           di,po,ti;
int           ticket =0;
double        PipStep_; 
bool          stochbuy,stochsell,stochbuy2,stochsell2;
bool          srbbBuySignal = false, srbbSellSignal = false;
int           sig = 9;
double        targetnya = 0; bool EAstopped = 0; bool targeting = 0;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
double GetBrokerPipSize()
{
    if (Pip_Unit_Override > 0.0)
        return(Pip_Unit_Override);

    double brokerPoint = MarketInfo(Symbol(), MODE_POINT);
    int brokerDigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
    if (brokerPoint <= 0) brokerPoint = Point;

    if (brokerDigits == 3 || brokerDigits == 5)
        return(brokerPoint * 10.0);

    return(brokerPoint);
}

bool ValidateInputs()
{
    bool ok = true;

    if (!Trade_Buy && !Trade_Sell) { Print("INPUT ERROR: Trade_Buy dan Trade_Sell tidak boleh keduanya false."); ok = false; }
    if (Lot <= 0.0) { Print("INPUT ERROR: Lot harus lebih besar dari 0."); ok = false; }
    if (Compound && Ketahanan_pip <= 0.0) { Print("INPUT ERROR: Ketahanan_pip harus lebih besar dari 0 saat Compound aktif."); ok = false; }
    if (TP < 0.0 || SL < 0.0 || TrailingStop < 0.0 || Step < 0.0) { Print("INPUT ERROR: TP, SL, TrailingStop, dan Step tidak boleh negatif."); ok = false; }
    if (Use_TP_InMoney && Target_Dollar <= 0.0) { Print("INPUT ERROR: Target_Dollar harus lebih besar dari 0 saat Use_TP_InMoney aktif."); ok = false; }
    if (Use_Martiangle && Averaging_Lot_Multiplier < 1.0) { Print("INPUT ERROR: Averaging_Lot_Multiplier harus >= 1 saat averaging aktif."); ok = false; }
    if (Use_Martiangle && Averaging_Lot_Multiplier < 1.5) { Print("WARNING: Averaging_Lot_Multiplier di bawah 1.5 sangat berbahaya karena BEP tidak akan turun, berisiko tinggi menyentuh Max Drawdown Basket!"); }
    if (Dual_Mode && Cut_Switch) { Print("INPUT ERROR: Dual_Mode dan Cut_Switch bertentangan; pilih salah satu."); ok = false; }
    if (Max_Buy_Layers < 1 || Max_Sell_Layers < 1) { Print("INPUT ERROR: Max_Buy_Layers dan Max_Sell_Layers minimal 1."); ok = false; }
    if (Grid_Pipstep <= 0.0 || Minimum_Pipstep <= 0.0) { Print("INPUT ERROR: Grid_Pipstep dan Minimum_Pipstep harus lebih besar dari 0."); ok = false; }
    if (Pipstep_Global_Max > 0.0 && Pipstep_Global_Max < Minimum_Pipstep) { Print("INPUT ERROR: Pipstep_Global_Max tidak boleh lebih kecil dari Minimum_Pipstep."); ok = false; }
    if ((Pipstep_L2_Cap > 0.0 && Pipstep_L2_Cap < Minimum_Pipstep) ||
        (Pipstep_L3_Cap > 0.0 && Pipstep_L3_Cap < Minimum_Pipstep) ||
        (Pipstep_L4_Cap > 0.0 && Pipstep_L4_Cap < Minimum_Pipstep) ||
        (Pipstep_L5Plus_Cap > 0.0 && Pipstep_L5Plus_Cap < Minimum_Pipstep)) { Print("INPUT ERROR: setiap Grid_Pipstep level cap harus nol atau >= Minimum_Pipstep."); ok = false; }
    if (Pipstep_Adaptive_Max_Factor < 1.0 || Pipstep_Absolute_Max_Factor < Pipstep_Adaptive_Max_Factor) { Print("INPUT ERROR: factor Grid_Pipstep harus >=1 dan Absolute Max >= Adaptive Max."); ok = false; }
    if (Pipstep_L2_Mult < 1.0 || Pipstep_L3_Mult < 1.0 || Pipstep_L4_Mult < 1.0 || Pipstep_L5Plus_Mult < 1.0) { Print("INPUT ERROR: multiplier Grid_Pipstep per level harus >= 1."); ok = false; }
    if (Time_Filter && (Jam_Mulai < 0 || Jam_Mulai > 23 || Jam_Akhir < 0 || Jam_Akhir > 24)) { Print("INPUT ERROR: Jam_Mulai harus 0..23 dan Jam_Akhir 0..24."); ok = false; }
    if (AvoidNews && (MinimumImpact < 1 || MinimumImpact > 3 || MinsBeforeNews < 0 || MinsAfterNews < 0)) { Print("INPUT ERROR: parameter News Filter tidak valid."); ok = false; }
    if (Close_Baskets_Before_Weekend && (Friday_Close_Hour < 0 || Friday_Close_Hour > 23 || Friday_Close_Minute < 0 || Friday_Close_Minute > 59)) { Print("INPUT ERROR: waktu close Jumat tidak valid."); ok = false; }
    if (Enforce_Account_Whitelist && Allowed_Account_1 <= 0 && Allowed_Account_2 <= 0) { Print("INPUT ERROR: aktifkan whitelist hanya bila minimal satu nomor akun valid."); ok = false; }
    if (Use_Target_persen_profit && (Use_Equity_target || Use_Target_Equity_Plus)) { Print("INPUT ERROR: aktifkan hanya satu target laba/ekuitas akun: persen, equity target, atau equity plus."); ok = false; }
    if (Use_Equity_target && Use_Target_Equity_Plus) { Print("INPUT ERROR: Use_Equity_target dan Use_Target_Equity_Plus tidak boleh aktif bersamaan."); ok = false; }

    return(ok);
}

int OnInit()
{
    if (!ValidateInputs())
        return(INIT_PARAMETERS_INCORRECT);

    bar = 0; TimeBUY = 0; TimeSELL = 0;
    targetnya = 0; EAstopped = false; targeting = false;
    pt = GetBrokerPipSize();
    dg = (Point > 0.0) ? (pt / Point) : 1.0;
    if (dg <= 0.0) dg = 1.0;

    gRiskStopBuyUntil  = 0;
    gRiskStopSellUntil = 0;

    if (IsTesting())
    {
        string keyBuy = GetRiskStopCooldownKey(OP_BUY);
        string keySell = GetRiskStopCooldownKey(OP_SELL);
        if (GlobalVariableCheck(keyBuy))  GlobalVariableDel(keyBuy);
        if (GlobalVariableCheck(keySell)) GlobalVariableDel(keySell);
    }

    if (!(IsTesting() && Disable_Timer_In_Tester))
        EventSetTimer(1);
    if (!IsTesting() || !Disable_Timer_In_Tester)
        Display_Info();

    if (IsTesting() && Tester_Diagnostic_Log)
        Print("TESTER INIT OK | EA=BioOnePro_Institutional_v5.25 (v80) | login=", AccountInfoInteger(ACCOUNT_LOGIN),
              " trendDirectional=", Use_Trend_Directional_Entry,
              " unhinderedAveraging=true",
              " maxLayers=", Max_Buy_Layers);

    if (Print_Grid_Risk_Report)
        PrintGridRiskReport();

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    if (IsTesting() && Tester_Diagnostic_Log)
        Print("TESTER DEINIT | reason=", reason, " (", DeinitReasonText(reason), ")",
              " balance=", DoubleToStr(AccountBalance(), 2),
              " equity=", DoubleToStr(AccountEquity(), 2));
    EventKillTimer();
  
    ObjectDelete("L01"); ObjectDelete("L02"); ObjectDelete("L03"); ObjectDelete("L04");  
    ObjectDelete("L05"); ObjectDelete("L06"); ObjectDelete("L07"); ObjectDelete("L08"); 
    ObjectDelete("L09"); ObjectDelete("L10"); ObjectDelete("L11"); ObjectDelete("L12"); 
    ObjectDelete("L13"); ObjectDelete("L14"); ObjectDelete("L15"); ObjectDelete("L16"); 
    ObjectDelete("L17"); ObjectDelete("L18"); ObjectDelete("L19"); ObjectDelete("L20"); 
    ObjectDelete("L21"); ObjectDelete("L22"); ObjectDelete("L23"); ObjectDelete("L24"); 
    ObjectDelete("L25"); ObjectDelete("L26"); ObjectDelete("L27"); ObjectDelete("L28"); 
    ObjectDelete("L29"); ObjectDelete("L30"); ObjectDelete("L31"); ObjectDelete("L32"); 
    ObjectDelete("L33"); ObjectDelete("L34"); ObjectDelete("L35"); ObjectDelete("L36"); 
    ObjectDelete("L37"); ObjectDelete("L38"); ObjectDelete("L39"); ObjectDelete("L40"); 
    ObjectDelete("L41"); ObjectDelete("L42"); ObjectDelete("L43"); ObjectDelete("L44"); 
    ObjectDelete("L45"); ObjectDelete("L46"); ObjectDelete("L47"); ObjectDelete("L48"); 
    ObjectDelete("L49"); ObjectDelete("L50"); ObjectDelete("L51"); ObjectDelete("L52"); 
    ObjectDelete("L53"); ObjectDelete("L54"); ObjectDelete("L55"); ObjectDelete("L56"); 
    ObjectDelete("L57"); ObjectDelete("L58"); ObjectDelete("L59"); ObjectDelete("L60"); 
    ObjectDelete("L61"); ObjectDelete("L62"); ObjectDelete("L63"); 
    ObjectDelete("Average_Price_Line_Bep");
    ObjectDelete("Average_Price_Line_Buy");
    ObjectDelete("Average_Price_Line_Sell");
    ObjectDelete("Information_");
    ObjectDelete("Average_Price_Buy");
    ObjectDelete("Average_Price_Sell");
    ObjectDelete("MENU");
    ObjectDelete("MENU1");
}

bool IsAccountAuthorised()
{
    if (!Enforce_Account_Whitelist)
        return(true);

    long login = AccountInfoInteger(ACCOUNT_LOGIN);
    return(login == Allowed_Account_1 || login == Allowed_Account_2);
}

string DeinitReasonText(const int reason)
{
    if (reason == REASON_PROGRAM)     return("REASON_PROGRAM");
    if (reason == REASON_REMOVE)      return("REASON_REMOVE");
    if (reason == REASON_RECOMPILE)   return("REASON_RECOMPILE");
    if (reason == REASON_CHARTCHANGE) return("REASON_CHARTCHANGE");
    if (reason == REASON_CHARTCLOSE)  return("REASON_CHARTCLOSE");
    if (reason == REASON_PARAMETERS)  return("REASON_PARAMETERS");
    if (reason == REASON_ACCOUNT)     return("REASON_ACCOUNT");
    if (reason == REASON_TEMPLATE)    return("REASON_TEMPLATE");
    if (reason == REASON_INITFAILED)  return("REASON_INITFAILED");
    if (reason == REASON_CLOSE)       return("REASON_CLOSE");
    return("REASON_UNKNOWN");
}

bool IsWeekendCloseWindow()
{
    if (!Close_Baskets_Before_Weekend)
        return(false);

    datetime nowTime = TimeCurrent();
    if (TimeDayOfWeek(nowTime) != 5)
        return(false);

    int nowMinutes = TimeHour(nowTime) * 60 + TimeMinute(nowTime);
    int closeMinutes = Friday_Close_Hour * 60 + Friday_Close_Minute;
    return(nowMinutes >= closeMinutes);
}

bool IsRolloverWindow()
{
    if (!Avoid_Rollover_Hours)
        return(false);

    int currentHour = TimeHour(TimeCurrent());
    if (Rollover_Start_Hour <= Rollover_End_Hour)
        return(currentHour >= Rollover_Start_Hour && currentHour <= Rollover_End_Hour);

    return(currentHour >= Rollover_Start_Hour || currentHour <= Rollover_End_Hour);
}

int GetHedgeMagic()
{
    return(Magic + HEDGE_MAGIC_OFFSET);
}

// Order milik EA ini: basket utama (Magic) dan Hedge Guard (Magic+777).
bool IsEAMagic(int orderMagic)
{
    return(orderMagic == Magic || orderMagic == GetHedgeMagic());
}

bool IsManagedOrderBookFlat()
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() == Symbol() && IsEAMagic(OrderMagicNumber()))
            return(false);
    }
    return(true);
}

bool CloseManagedOrdersAndStop(string messageText)
{
    closeallpair();
    if (!IsManagedOrderBookFlat())
    {
        Print("EA STOP DELAYED: masih ada order/pending yang belum tertutup. Close akan diulang pada tick berikutnya.");
        return(false);
    }

    clear();
    text(1, messageText);
    if (IsTesting() && Auto_Resume_In_Tester)
    {
        Print("TESTER NOTICE: ", messageText, ". Seluruh order berhasil ditutup. Siklus di-reset untuk melanjutkan backtest.");
        ObjectDelete("STOP");
        EAstopped = false;
        targeting = false;
    }
    else
    {
        EAstopped = true;
        stop();
    }
    return(true);
}

void OnTick()
{
    MainTick();
}

void OnTimer()
{
    if (IsTesting() && Disable_Timer_In_Tester)
        return;
    Display_Info();
}

int MainTick()
{
    if(!IsAccountAuthorised())
    {
        Alert("Maaf, akun ini belum terdaftar untuk EA.");
        Print("EA STOP: ACCOUNT_LOGIN=", AccountInfoInteger(ACCOUNT_LOGIN), " tidak lolos whitelist aktif.");
        return(0);
    }

    if(TimeCurrent() >= StringToTime("2070.10.6"))
    {
        Alert("MASA BERLAKU HABIS HUBUBGI ADMIN.....!!!!"); 
        return(0);
    }

    if (IsWeekendCloseWindow())
    {
        if (!IsManagedOrderBookFlat())
        {
            Print("WEEKEND FLAT: menutup semua basket sebelum penutupan Jumat.");
            closeallpair();
        }
        return(0);
    }

    bool ContinueTrading=true;
    if(AvoidNews)
    {
        if (IsTesting())
        {
            static bool sNewsWarnedInTester = false;
            if (!sNewsWarnedInTester && Tester_Diagnostic_Log)
            {
                Print("TESTER NOTICE: News Filter FFCal dilewati selama backtest offline.");
                sNewsWarnedInTester = true;
            }
        }
        else
        {
            ResetLastError();
            double MinSinceNews=iCustom(NULL,0,"FFCal",true,true,true,true,true,1,0);
            double MinToNews=iCustom(NULL,0,"FFCal",true,true,true,true,true,1,1);
            double ImpactSinceNews=iCustom(NULL,0,"FFCal",true,true,true,true,true,2,0);
            double ImpactToNews=iCustom(NULL,0,"FFCal",true,true,true,true,true,2,1);
            int newsErr = GetLastError();

            if (newsErr != 0)
            {
                Print("NEWS FILTER ERROR | FFCal tidak tersedia/error=", newsErr,
                      ". New order ", (News_Filter_Fail_Closed ? "DIBLOKIR" : "diizinkan"), ".");
                if (News_Filter_Fail_Closed)
                    ContinueTrading=false;
            }
            else if((MinToNews<=MinsBeforeNews && ImpactToNews>=MinimumImpact) ||
                    (MinSinceNews<=MinsAfterNews && ImpactSinceNews>=MinimumImpact))
                ContinueTrading=false;
        }
    }

    bool dailyTargetReached = (use_daily_target && dailyprofit() >= daily_target);
    if(dailyTargetReached)
    {
        Comment("\ndaily target achieved. New entries and averaging are blocked; open baskets remain managed.");
        ContinueTrading = false;
    }
    bool entryWindowOpen = JAM_OP() && !IsRolloverWindow();

    hitung();
    if (!targeting)
    {
        targetnya = AccountCredit() + AccountBalance() * (1 + (Persen_profit / 100.0)); targeting = 1; EAstopped = 0; ObjectDelete("STOP");
    }
    if (Use_Target_persen_profit)
    {
        if (AccountEquity() >= targetnya)
            if (Buy + Sell > 0)
            {
                closeallpair();
                if (!IsManagedOrderBookFlat())
                    return(0);
                clear(); text(1, " TARGET % PROFIT TERCAPAI");
                if (OFF_EA_Target_Done)
                {
                    if (IsTesting() && Auto_Resume_In_Tester)
                    {
                        Print("TESTER NOTICE: Target % profit tercapai ($", DoubleToStr(AccountEquity(), 2), "). Siklus baru di-reset untuk melanjutkan backtest.");
                        ObjectDelete("STOP");
                        EAstopped = 0;
                        targeting = 0;
                    }
                    else
                    {
                        EAstopped = 1; stop();
                    }
                }
                else
                    targeting = 0;
                return(0);
            }
    }

    double TargetLossPct = NormalizeDouble(AccountBalance()*(Percent_Loss/100),Digits);
    double managedOpenNet = GetManagedOpenNetProfit();
    bool accountLossLimitHit = ((Use_SL_inPercent == TRUE && managedOpenNet <= (-1 * TargetLossPct)) ||
                                (Use_SL_inMoney == TRUE && managedOpenNet <= (-1 * Loss_inMoney)));
    if(accountLossLimitHit)
    {
        closeallpair();
        if (!IsManagedOrderBookFlat())
            return(0);
        if (Stop_After_Account_Loss)
        {
            if (IsTesting() && Auto_Resume_In_Tester)
            {
                Print("TESTER NOTICE: Batas rugi akun tercapai (Net loss: $", DoubleToStr(managedOpenNet, 2), "). Semua posisi ditutup. Siklus di-reset untuk pengujian lanjutan.");
                ObjectDelete("STOP");
                EAstopped = 0;
                targeting = 0;
            }
            else
            {
                clear(); text(1, " BATAS RUGI AKUN TERCAPAI");
                EAstopped = true; stop();
            }
        }
        return(0);
    }

    if(Use_TP_InMoney) CloseAllinProfit();   
    
    if (EAstopped)
    {
        if (IsTesting() && Auto_Resume_In_Tester)
        {
            ObjectDelete("STOP");
            EAstopped = 0;
            targeting = 0;
        }
        else
        {
            if (ObjectFind("STOP") > -1)
                return(0);
            EAstopped = 0; targeting = 0;
        }
    }

    if (Use_Equity_target)
        if (AccountEquity() >= Target_Equity)
        {
            CloseManagedOrdersAndStop(" TARGET EQUITY TERCAPAI");
            return(0);
        }

    if (Use_Target_Equity_Minus && AccountEquity() <= Jumlah_Equity_Minus)
    {
        Alert("Batas equity rugi tercapai. EA dihentikan setelah seluruh posisi dikelola ditutup.");
        CloseManagedOrdersAndStop(" BATAS EQUITY RUGI TERCAPAI");
        return(0);
    }
    if (Use_Target_Equity_Plus && AccountEquity() >= Jumlah_Equity_Plus)
    {
        Alert("Target equity tercapai. EA dihentikan setelah seluruh posisi dikelola ditutup.");
        CloseManagedOrdersAndStop(" TARGET EQUITY TERCAPAI");
        return(0);
    }

    if (bar != Bars)
    {
        sig = 9;

        stochbuy=False;
        stochsell=False;
        stochbuy2=False;
        stochsell2=False;

        if (UsedStoc)
        {
            if (fnc02(1) > fnc13(1) && fnc13(0) <= input25) stochbuy = True;
            if (fnc02(1) < fnc13(1) && fnc13(0) >= input26) stochsell = True;
        }
        else
        {
            stochbuy = True;
            stochsell = True;
        }

        if (UsedStoci2)
        {
            if (fnc02i(1) > fnc13i(1) && fnc13i(0) <= input25i) stochbuy2 = True;
            if (fnc02i(1) < fnc13i(1) && fnc13i(0) >= input26i) stochsell2 = True;
        }
        else
        {
            stochbuy2 = True;
            stochsell2 = True;
        }
        
        bool l1StochBuyReady  = IsL1StochReady(OP_BUY);
        bool l1StochSellReady = IsL1StochReady(OP_SELL);

        if (L1_Entry_Debug)
            Print("L1 STOCH | BUY=", l1StochBuyReady, " SELL=", l1StochSellReady,
                  " slow(B/S)=", stochbuy, "/", stochsell,
                  " fast(B/S)=", stochbuy2, "/", stochsell2);

        srbbBuySignal = false;
        srbbSellSignal = false;

        int trendRegime = GetTrendRegime();

        if (Use_Trend_Directional_Entry && trendRegime != 0)
        {
            // Indikator Trend Pullback Terpadu:
            double bbUpper1 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_UPPER, 1);
            double bbLower1 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_LOWER, 1);
            double bbMid1   = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_MAIN, 1);
            bool isBullCandle = (Close[1] > Open[1]);
            bool isBearCandle = (Close[1] < Open[1]);

            // Filter RSI Dinamis untuk menghindari pucuk/lembah ekstrim
            double rsiVal = iRSI(NULL, 0, 14, PRICE_CLOSE, 1);

            if (trendRegime == 1) // H1 Bullish Trend
            {
                // Hanya Buy saat Pullback ke Mid/Lower BB atau Reversal Bounce di Support, JANGAN Buy di Pucuk Upper BB
                bool bullPullback = (Low[1] <= bbMid1 || Low[1] <= bbLower1 || IsL1SRBBBuySignal());
                bool notOverbought = (Close[1] < bbUpper1 && rsiVal <= 68.0);
                
                if (isBullCandle && bullPullback && notOverbought && l1StochBuyReady && Trade_Buy && ContinueTrading && IsL1TrendAllowed(OP_BUY))
                {
                    sig = 0; // BUY DI ZONA PULLBACK SEARAH TREN
                }
            }
            else if (trendRegime == -1) // H1 Bearish Trend
            {
                // Hanya Sell saat Pullback ke Mid/Upper BB atau Reversal Bounce di Resistance, JANGAN Sell di Lembah Lower BB
                bool bearPullback  = (High[1] >= bbMid1 || High[1] >= bbUpper1 || IsL1SRBBSellSignal());
                bool notOversold   = (Close[1] > bbLower1 && rsiVal >= 32.0);
                
                if (isBearCandle && bearPullback && notOversold && l1StochSellReady && Trade_Sell && ContinueTrading && IsL1TrendAllowed(OP_SELL))
                {
                    sig = 1; // SELL DI ZONA PULLBACK SEARAH TREN
                }
            }
        }
        else if (Use_SR_BB_Entry)
        {
            srbbBuySignal  = IsL1SRBBBuySignal();
            srbbSellSignal = IsL1SRBBSellSignal();

            if (srbbBuySignal  && l1StochBuyReady  && Trade_Buy  && ContinueTrading && IsL1TrendAllowed(OP_BUY))
                sig = 0;

            if (srbbSellSignal && l1StochSellReady && Trade_Sell && ContinueTrading && IsL1TrendAllowed(OP_SELL))
                sig = 1;
        }
        else
        {
            double Tdibuy  = Open[1] < Close[1];
            double Tdisell = Open[1] > Close[1];

            if (Tdibuy  && l1StochBuyReady  && Trade_Buy  && ContinueTrading && IsL1TrendAllowed(OP_BUY))
                sig = 0;
            if (Tdisell && l1StochSellReady && Trade_Sell && ContinueTrading && IsL1TrendAllowed(OP_SELL))
                sig = 1;
        }

        bar = Bars;
        hitung();

        if (Cut_Switch)
        {
            if (sig == 1 && Buy > 0)
            {
                CUT(0);
                hitung();
            }
            if (sig == 0 && Sell > 0)
            {
                CUT(1);
                hitung();
            }
        }

        bool blockNewL1ThisBar = false;
        if (OrdersHistoryTotal() > 0)
            if (OrderSelect(OrdersHistoryTotal() - 1, SELECT_BY_POS, MODE_HISTORY))
                if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
                    if (iBarShift(Symbol(), 0, OrderOpenTime(), true) == 0)
                        blockNewL1ThisBar = true;

        if (L1_Entry_Debug && blockNewL1ThisBar)
            Print("L1 ENTRY BLOCKED: last historical order was opened on current bar");

        if (!blockNewL1ThisBar)
        {
            if (Dual_Mode)
            {
                if (Buy == 0)
                    if (sig == 0)
                        if (JAM_OP() && !IsRolloverWindow() && !IsFridayAfternoon())
                            if (!IsSignalExhausted(OP_BUY) && IsHistoricalHourConfirm(OP_BUY))
                                if (IsL1VolumeReversalReady(OP_BUY))
                                    if (OPE(0, LOTnya(), com) <= 0)
                                        bar = 0;

                if (Sell == 0)
                    if (sig == 1)
                        if (JAM_OP() && !IsRolloverWindow() && !IsFridayAfternoon())
                            if (!IsSignalExhausted(OP_SELL) && IsHistoricalHourConfirm(OP_SELL))
                                if (IsL1VolumeReversalReady(OP_SELL))
                                    if (OPE(1, LOTnya(), com) <= 0)
                                        bar = 0;
            }
            else
            {
                if (Buy == 0 && Sell == 0)
                    if (sig == 0)
                        if (JAM_OP() && !IsRolloverWindow() && !IsFridayAfternoon())
                            if (!IsSignalExhausted(OP_BUY) && IsHistoricalHourConfirm(OP_BUY))
                                if (IsL1VolumeReversalReady(OP_BUY))
                                    if (OPE(0, LOTnya(), com) <= 0)
                                        bar = 0;

                if (Buy == 0 && Sell == 0)
                    if (sig == 1)
                        if (JAM_OP() && !IsRolloverWindow() && !IsFridayAfternoon())
                            if (!IsSignalExhausted(OP_SELL) && IsHistoricalHourConfirm(OP_SELL))
                                if (IsL1VolumeReversalReady(OP_SELL))
                                    if (OPE(1, LOTnya(), com) <= 0)
                                        bar = 0;
            }
        }
    }

    hitung();
    if (ManageNetBasketProfit()) hitung();
    if (ManagePartialPairClose()) hitung();
    if (ManageSideBasketRisk()) hitung();
    tpsl();
    if (UseTrailingStop)
        trail();
        
    ManageHedgeTrailing();

    //======================================================================
    // PURE UNHINDERED RECOVERY AVERAGING ENGINE
    // Averaging dipicu murni oleh jarak harga (Grid_Pipstep) tanpa hambatan indikator/delay
    //======================================================================
    bool allowAveragingCheck = true;
    if (Averaging_New_Candle)
    {
        allowAveragingCheck = (timeprev != Time[0]);
        if (allowAveragingCheck)
            timeprev = Time[0];
    }

    if (allowAveragingCheck)
    {
        hitung();

        if (Sell > 0)
        {
            if (Sell < Max_Sell_Layers && ContinueTrading && JAM_OP())
            {
                double sellStepPips = GetHybridPipstep(Sell, OP_SELL);
                if (Use_Martiangle && IsAveragingDistanceReady(OP_SELL, Sell, Bid - hisell, sellStepPips * pt, hisell))
                {
                    if (IsAveragingTrendAllowed(OP_SELL, Sell) && IsAveragingCandleConfirm(OP_SELL, Sell))
                    {
                        datetime newestSell = GetNewestOrderTime(OP_SELL);
                        if (TimeCurrent() - newestSell >= GetMinMinutesBetweenLayers(Sell) * 60)
                        {
                            // Lot adaptif (scan fractal H1 14 hari) hanya dihitung saat layer benar-benar akan dibuka.
                            double sellNextLot = NR(GetAdaptiveRecoveryLot(OP_SELL, Sell, lowlotsell));
                            int tk_sell = OPE(1, sellNextLot, com);
                            if (tk_sell > 0 && Use_L4_Hedge_Guard && (Sell + 1) >= Hedge_Activation_Layer)
                                OpenHedgeOrder(OP_BUY, sellNextLot);
                        }
                    }
                }
            }
        }

        if (Buy > 0)
        {
            if (Buy < Max_Buy_Layers && ContinueTrading && JAM_OP())
            {
                double buyStepPips = GetHybridPipstep(Buy, OP_BUY);
                if (Use_Martiangle && IsAveragingDistanceReady(OP_BUY, Buy, lobuy - Ask, buyStepPips * pt, lobuy))
                {
                    if (IsAveragingTrendAllowed(OP_BUY, Buy) && IsAveragingCandleConfirm(OP_BUY, Buy))
                    {
                        datetime newestBuy = GetNewestOrderTime(OP_BUY);
                        if (TimeCurrent() - newestBuy >= GetMinMinutesBetweenLayers(Buy) * 60)
                        {
                            // Lot adaptif (scan fractal H1 14 hari) hanya dihitung saat layer benar-benar akan dibuka.
                            double buyNextLot = NR(GetAdaptiveRecoveryLot(OP_BUY, Buy, lowlotbuy));
                            int tk_buy = OPE(0, buyNextLot, com);
                            if (tk_buy > 0 && Use_L4_Hedge_Guard && (Buy + 1) >= Hedge_Activation_Layer)
                                OpenHedgeOrder(OP_SELL, buyNextLot);
                        }
                    }
                }
            }
        }
    }

    return(0);
}

int GetTrendRegime()
{
    if (!Use_Trend_Regime_Guard && !Use_Trend_Directional_Entry)
        return(0);

    int tf = Trend_Timeframe;
    int fastP = MathMax(2, Trend_Fast_EMA);
    int slowP = MathMax(fastP + 1, Trend_Slow_EMA);
    int slopeBars = MathMax(1, Trend_Slope_Bars);
    int atrP = MathMax(2, Trend_ATR_Period);

    double fast1 = iMA(NULL, tf, fastP, 0, MODE_EMA, PRICE_CLOSE, 1);
    double slow1 = iMA(NULL, tf, slowP, 0, MODE_EMA, PRICE_CLOSE, 1);
    double fastOld = iMA(NULL, tf, fastP, 0, MODE_EMA, PRICE_CLOSE, 1 + slopeBars);
    double atr1 = iATR(NULL, tf, atrP, 1);
    double close1 = iClose(NULL, tf, 1);

    if (fast1 <= 0 || slow1 <= 0 || fastOld <= 0 || atr1 <= 0 || close1 <= 0)
        return(0);

    double spread = MathAbs(fast1 - slow1);
    double minSpread = atr1 * Min_EMA_Spread_ATR;
    bool hasSpread = (spread >= minSpread);
    bool fastSlopeUp   = (fast1 > fastOld);
    bool fastSlopeDown = (fast1 < fastOld);

    bool bull = (fast1 > slow1 && close1 > fast1 && hasSpread && fastSlopeUp);
    bool bear = (fast1 < slow1 && close1 < fast1 && hasSpread && fastSlopeDown);

    if (bull) return(1);
    if (bear) return(-1);
    return(0);
}

bool IsStrongAdverseTrend(int orderType)
{
    int regime = GetTrendRegime();
    if (orderType == OP_BUY  && regime < 0) return(true);
    if (orderType == OP_SELL && regime > 0) return(true);
    return(false);
}

double GetAdaptiveRecoveryLot(int orderType, int existingOrders, double baseLot)
{
    double currentMultiplier = Averaging_Lot_Multiplier;
    if (existingOrders == 1) currentMultiplier = Averaging_Lot_Multiplier_L2; // Khusus L2
    
    // Perhitungan pangkat yang dimodifikasi
    double staticLot;
    if (existingOrders == 1) 
    {
        staticLot = baseLot * currentMultiplier; // L2: L1 * 1.50
    }
    else 
    {
        // L3 dan seterusnya: L2 * Averaging_Lot_Multiplier^(existingOrders - 1)
        staticLot = (baseLot * Averaging_Lot_Multiplier_L2) * MathPow(Averaging_Lot_Multiplier, existingOrders - 1);
    }
    
    // NEW RULE: Fungsi Adaptif dan Hybrid hanya dimaksimalkan pada L3+
    if (!Use_Adaptive_Lot_Multiplier || existingOrders < 2)
        return staticLot;

    double L_total = 0;
    double cost = 0;
    double P_last = 0;
    double P_first = 0; // NEW: Menyimpan harga OP L1
    
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == orderType)
            {
                double l = OrderLots();
                double p = OrderOpenPrice();
                L_total += l;
                cost += l * p;
                
                if (orderType == OP_BUY) {
                    if (P_last == 0 || p < P_last) P_last = p;
                    if (P_first == 0 || p > P_first) P_first = p; // L1 Buy adalah harga tertinggi
                } else {
                    if (P_last == 0 || p > P_last) P_last = p;
                    if (P_first == 0 || p < P_first) P_first = p; // L1 Sell adalah harga terendah
                }
            }
        }
    }
    
    if (L_total <= 0) return staticLot;
    
    double P_avg = cost / L_total;
    double currentPrice = (orderType == OP_BUY) ? Ask : Bid;
    
    double gap = 0;
    double dist_from_L1 = 0; // NEW: Total jarak market jatuh dari L1
    
    if (orderType == OP_BUY) {
        gap = P_avg - currentPrice;
        dist_from_L1 = P_first - currentPrice;
    }
    if (orderType == OP_SELL) {
        gap = currentPrice - P_avg; 
        dist_from_L1 = currentPrice - P_first;
    }
    
    if (gap <= 0) return staticLot;
    if (dist_from_L1 < 0) dist_from_L1 = 0;
    
    // Gunakan rata-rata jarak reversal historis (14 hari terakhir di sesi yang sama) sebagai referensi
    double D_avg_pips = GetAdaptiveReversalDistancePips(14); 
    double D_avg_points = D_avg_pips * pt;
    
    // Jika jarak jatuh dari L1 ternyata JAUH LEBIH BESAR dari rata-rata historis (Black Swan),
    // maka gunakan dist_from_L1 sebagai referensi pantulan! 
    // Ini menjamin target_T akan ikut membesar, sehingga L_new (Lot Adaptif) TIDAK AKAN membengkak!
    double reference_Distance = MathMax(D_avg_points, dist_from_L1);
    
    // Target BEP kita adalah sebagian dari referensi jarak tersebut
    double target_T = reference_Distance * Adaptive_Lot_Target_BEP_Fraction; 
    
    // Jangan biarkan target T lebih kecil dari minimum TP Averaging
    double min_T = TP_Averaging * 10.0 * pt;
    if (target_T < min_T) target_T = min_T;
    
    if (gap <= target_T) return staticLot;
    
    // Rumus hibrida: Hitung persis berapa lot baru yang dibutuhkan agar BEP baru bergeser
    double L_new = L_total * (gap - target_T) / target_T;
    
    // Cap 1.25x masih memicu lot terlalu besar saat volatilitas flat.
    // SOLUSI DD TERENDAH: Maksimal adaptif lot dikunci di 1.0x dari lot statis. 
    // Artinya, EA boleh MENGECILKAN lot (hemat margin) jika reversal sedang besar, 
    // tapi DILARANG MEMBESARKAN lot melebihi standar matematis.
    double minAllowed = staticLot * 0.50; // Hemat margin saat reversal ekstrem
    double maxAllowed = staticLot * ADAPTIVE_LOT_MAX_FACTOR; // Dilebarkan ke 1.35x. Terbukti membatasi lot justru meledakkan DD!
    
    if (L_new < minAllowed) L_new = minAllowed;
    if (L_new > maxAllowed) L_new = maxAllowed;
    
    return L_new;
}

string GetRiskStopCooldownKey(int orderType)
{
    string side = (orderType == OP_BUY) ? "BUY" : "SELL";
    return("BioOnePro.RiskCooldown." + IntegerToString(AccountNumber()) + "." + Symbol() + "." + IntegerToString(Magic) + "." + side);
}

datetime GetRiskStopCooldownUntil(int orderType)
{
    datetime untilTime = (orderType == OP_BUY) ? gRiskStopBuyUntil : gRiskStopSellUntil;
    string key = GetRiskStopCooldownKey(orderType);

    if (GlobalVariableCheck(key))
    {
        datetime persistedUntil = (datetime)GlobalVariableGet(key);
        if (persistedUntil > untilTime)
            untilTime = persistedUntil;
    }

    if (orderType == OP_BUY)
        gRiskStopBuyUntil = untilTime;
    else if (orderType == OP_SELL)
        gRiskStopSellUntil = untilTime;

    return(untilTime);
}

bool IsRiskStopCooldownAllowed(int orderType)
{
    if (!Use_Risk_Stop_Cooldown || Risk_Stop_Cooldown_Hours <= 0.0)
        return(true);

    datetime nowTime = TimeCurrent();
    datetime untilTime = GetRiskStopCooldownUntil(orderType);

    if (untilTime <= 0 || nowTime >= untilTime)
        return(true);

    return(false);
}

void SetRiskStopCooldown(int orderType)
{
    if (!Use_Risk_Stop_Cooldown || Risk_Stop_Cooldown_Hours <= 0.0)
        return;

    datetime untilTime = TimeCurrent() + (int)MathRound(Risk_Stop_Cooldown_Hours * 3600.0);
    if (orderType == OP_BUY)
        gRiskStopBuyUntil = untilTime;
    else if (orderType == OP_SELL)
        gRiskStopSellUntil = untilTime;

    GlobalVariableSet(GetRiskStopCooldownKey(orderType), (double)untilTime);
}

bool IsL1TrendAllowed(int orderType)
{
    if (!IsRiskStopCooldownAllowed(orderType))
        return(false);

    if (!Use_Trend_Regime_Guard && !Use_Trend_Directional_Entry)
        return(true);

    if (!L1_Block_Strong_CounterTrend && !Use_Trend_Directional_Entry)
        return(true);

    if (Use_ADX_Filter)
    {
        double adxMain  = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, 1);
        double adxPlus  = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, 1);
        double adxMinus = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, 1);

        if (adxMain >= ADX_Max_Level)
        {
            if (orderType == OP_BUY  && adxMinus > adxPlus) return(false); 
            if (orderType == OP_SELL && adxPlus > adxMinus) return(false); 
        }
    }

    if (Use_MACD_Filter)
    {
        double macdMain   = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
        double macdSignal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
        
        // MACD wajib searah dengan order (Mencegah OP melawan momentum jangka pendek)
        if (orderType == OP_BUY  && macdMain < macdSignal) return(false);
        if (orderType == OP_SELL && macdMain > macdSignal) return(false);
    }

    if (Use_MA_Filter)
    {
        double maVal = iMA(Symbol(), MA_Filter_Timeframe, MA_Filter_Period, 0, MA_Filter_Method, PRICE_CLOSE, 1);
        if (orderType == OP_BUY && Close[1] < maVal) return(false);
        if (orderType == OP_SELL && Close[1] > maVal) return(false);
    }

    if (Use_PSAR_L1_Filter && !IsPSARAligned(orderType, PSAR_L1_TF))
        return(false);

    bool allowed = !IsStrongAdverseTrend(orderType);
    return(allowed);
}

int GetAdaptiveReversalMinutes(int days)
{
    int tf = PERIOD_H1;
    int barsToScan = 24 * days;
    int maxBars = iBars(NULL, tf);
    if(barsToScan > maxBars) barsToScan = maxBars;
    if(barsToScan < 24) return Min_Minutes_Between_L4Plus; // Fallback
    
    datetime lastPeakTime = 0;
    int peakType = 0; // 1 = High, -1 = Low
    
    int totalMinutes = 0;
    int reversalCount = 0;
    
    for(int i = 3; i < barsToScan; i++)
    {
        double up = iFractals(NULL, tf, MODE_UPPER, i);
        double dn = iFractals(NULL, tf, MODE_LOWER, i);
        
        if(up > 0) // Swing High
        {
            if(peakType == -1 && lastPeakTime > 0) // Didahului oleh Low
            {
                datetime timeDiff_up = lastPeakTime - iTime(NULL, tf, i);
                if (timeDiff_up < 0) timeDiff_up = -timeDiff_up;
                totalMinutes += (timeDiff_up / 60);
                reversalCount++;
            }
            lastPeakTime = iTime(NULL, tf, i);
            peakType = 1;
        }
        if(dn > 0) // Swing Low
        {
            if(peakType == 1 && lastPeakTime > 0) // Didahului oleh High
            {
                datetime timeDiff_dn = lastPeakTime - iTime(NULL, tf, i);
                if (timeDiff_dn < 0) timeDiff_dn = -timeDiff_dn;
                totalMinutes += (timeDiff_dn / 60);
                reversalCount++;
            }
            lastPeakTime = iTime(NULL, tf, i);
            peakType = -1;
        }
    }
    
    if(reversalCount > 0)
    {
        int avgMinutes = totalMinutes / reversalCount;
        // Batasi rentang kewarasan: minimal 60 menit, maksimal 300 menit (5 jam)
        if(avgMinutes < 60) avgMinutes = 60;
        if(avgMinutes > 300) avgMinutes = 300;
        return avgMinutes;
    }
    
    return Min_Minutes_Between_L4Plus; // Fallback ke parameter manual
}

double GetAdaptiveReversalDistancePips(int days)
{
    int tf = PERIOD_H1;
    // Scan lebih jauh (misal 14 hari) karena kita memfilter berdasarkan sesi
    int barsToScan = 24 * days; 
    int maxBars = iBars(NULL, tf);
    if(barsToScan > maxBars) barsToScan = maxBars;
    if(barsToScan < 24) return 200.0; // Fallback default
    
    double lastPeakPrice = 0;
    int peakType = 0; // 1 = High, -1 = Low
    
    double totalPips = 0;
    int reversalCount = 0;
    
    double localPt = pt;
    if (localPt <= 0) return 200.0;
    
    int currentHour = Hour();
    
    for(int i = 3; i < barsToScan; i++)
    {
        double up = iFractals(NULL, tf, MODE_UPPER, i);
        double dn = iFractals(NULL, tf, MODE_LOWER, i);
        
        // NEW SESSION FILTER: Hanya gunakan data reversal yang terjadi di jam yang sama (+/- 2 jam)
        int barHour = TimeHour(iTime(NULL, tf, i));
        int hourDiff = MathAbs(currentHour - barHour);
        if (hourDiff > 12) hourDiff = 24 - hourDiff;
        bool isSameSession = (hourDiff <= 2);
        
        if(up > 0)
        {
            if(peakType == -1 && lastPeakPrice > 0 && isSameSession) 
            {
                double dist_up = MathAbs(up - lastPeakPrice) / localPt;
                totalPips += dist_up;
                reversalCount++;
            }
            lastPeakPrice = up;
            peakType = 1;
        }
        if(dn > 0)
        {
            if(peakType == 1 && lastPeakPrice > 0 && isSameSession)
            {
                double dist_dn = MathAbs(lastPeakPrice - dn) / localPt;
                totalPips += dist_dn;
                reversalCount++;
            }
            lastPeakPrice = dn;
            peakType = -1;
        }
    }
    
    if(reversalCount > 0)
    {
        double avgPips = totalPips / reversalCount;
        if(avgPips < 50.0) avgPips = 50.0;
        return avgPips;
    }
    
    return 200.0; // Fallback
}

int GetHistoricalHourDirection(int checkHour, int daysBack)
{
    int countedDays = 0;
    double netMovePips = 0;
    int tf = PERIOD_H1;
    int maxBars = iBars(NULL, tf);
    
    int currentDay = TimeDayOfYear(TimeCurrent());
    int lastSeenDay = currentDay;
    
    double localPt = pt;
    if(localPt <= 0) localPt = Point;
    
    for (int i = 1; i < maxBars; i++)
    {
        datetime t = iTime(NULL, tf, i);
        int barHour = TimeHour(t);
        int barDay = TimeDayOfYear(t);
        
        if (barHour == checkHour && barDay != currentDay)
        {
            double open = iOpen(NULL, tf, i);
            double close = iClose(NULL, tf, i);
            netMovePips += (close - open) / localPt;
            
            lastSeenDay = barDay;
            countedDays++;
            
            if (countedDays >= daysBack) break;
            
            // Skip sisa bar di hari yang sama agar tidak menghitung ganda (meski H1 jarang ganda)
            while(i+1 < maxBars && TimeDayOfYear(iTime(NULL, tf, i+1)) == barDay && TimeHour(iTime(NULL, tf, i+1)) == checkHour)
            {
                i++;
            }
        }
    }
    
    if (netMovePips > 50.0) return OP_BUY;   // Mayoritas Bullish di jam ini
    if (netMovePips < -50.0) return OP_SELL; // Mayoritas Bearish di jam ini
    
    return -1; // Sideways / Neutral
}

bool IsSignalExhausted(int orderType)
{
    datetime lastCloseTime = 0;
    int lastOrderType = -1;
    double lastNetProfit = 0;

    for (int i = 0; i < OrdersHistoryTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
            {
                if (OrderCloseTime() > lastCloseTime)
                {
                    lastCloseTime = OrderCloseTime();
                    lastOrderType = OrderType();
                    lastNetProfit = OrderProfit() + OrderSwap() + OrderCommission();
                }
            }
        }
    }

    if (lastCloseTime > 0)
    {
        if (lastOrderType == orderType)
        {
            // NEW RULE: Jarak waktu antara CLOSE order sebelumnya dengan OP L1 searah MINIMAL 2 JAM
            if (TimeCurrent() - lastCloseTime < 7200) // 7200 detik = 2 jam
            {
                return true; // Cooldown aktif, JANGAN OP searah!
            }

    // Mencegah EA OP L1 berulang kali pada kondisi tren yang sama 
            if (lastNetProfit > 0)
            {
                double rsi = iRSI(NULL, PERIOD_M15, 14, PRICE_CLOSE, 1);
                if (orderType == OP_BUY) {
                    if (rsi < 40) return true; // Sinyal exhausted 
                } else if (orderType == OP_SELL) {
                    if (rsi > 60) return true; // Sinyal exhausted
                }
            }
        }
    }
    return false; // Aman untuk OP
}

bool IsHistoricalHourConfirm(int orderType)
{
    if (!Use_Historical_Hour_Filter) return true;
    
    // Cek pergerakan rata-rata di jam yang sama selama 5 hari terakhir
    int histDir = GetHistoricalHourDirection(TimeHour(TimeCurrent()), 5);
    
    if (histDir == -1) return true; // Sideways, bebas masuk
    
    if (orderType == OP_BUY && histDir == OP_SELL) return false; // Jam ini biasanya turun tajam, blokir Buy
    if (orderType == OP_SELL && histDir == OP_BUY) return false; // Jam ini biasanya naik tajam, blokir Sell
    
    return true;
}

int GetMinMinutesBetweenLayers(int existingOrders)
{
    // Jeda waktu buatan (seperti 120 menit atau adaptif 5 jam) 
    // akan BERTABRAKAN dengan fitur Sniper Averaging. Jika Sniper M1 sudah mendeteksi pantulan yang valid,
    // EA tidak boleh ditahan oleh timer! Waktu optimal L2 dan L3 adalah murni bergantung pada jarak (Pipstep) + Price Action (Sniper).
    
    if (existingOrders == 1) return Min_Minutes_Between_Layers; // Default 3 menit
    if (existingOrders == 2) return Min_Minutes_Between_L3;     // Default 3 menit
    if (existingOrders >= 3) return Min_Minutes_Between_L4Plus; // Default 120 menit (Khusus L4 ke atas ditahan agar aman dari flash crash beruntun)

    return Min_Minutes_Between_Layers; 
}

//==================== v80: PARABOLIC SAR HELPERS ====================
// true bila SAR bar terakhir yang sudah close berada di sisi yang mendukung arah order.
bool IsPSARAligned(int orderType, int tf)
{
    double sar = iSAR(NULL, tf, PSAR_Step, PSAR_Max, 1);
    double closePrice = iClose(NULL, tf, 1);
    if (sar <= 0.0 || closePrice <= 0.0)
        return(true); // data belum siap: jangan blokir
    if (orderType == OP_BUY)
        return(sar < closePrice);
    return(sar > closePrice);
}

int      gArmedBuyCount  = 0;
double   gArmedBuyRef    = 0.0;
int      gArmedSellCount = 0;
double   gArmedSellRef   = 0.0;

// Gate averaging: tanpa PSAR sama persis dengan v79 (jarak >= step).
// Dengan PSAR: jarak >= step meng-"arm" layer untuk basket ini (count + harga layer terakhir),
// lalu layer dibuka saat PSAR searah basket dan jarak masih >= PSAR_Arm_Min_Fraction x step.
bool IsAveragingDistanceReady(int orderType, int existingOrders, double distancePrice, double stepPrice, double lastLayerPrice)
{
    bool reached = (stepPrice <= distancePrice);
    if (!Use_PSAR_Averaging_Gate)
        return(reached);

    bool isBuy = (orderType == OP_BUY);
    int armedCount = isBuy ? gArmedBuyCount : gArmedSellCount;
    double armedRef = isBuy ? gArmedBuyRef : gArmedSellRef;
    bool armed = (armedCount == existingOrders && MathAbs(armedRef - lastLayerPrice) < Point / 2.0);

    if (reached && !armed)
    {
        armed = true;
        if (isBuy) { gArmedBuyCount = existingOrders; gArmedBuyRef = lastLayerPrice; }
        else       { gArmedSellCount = existingOrders; gArmedSellRef = lastLayerPrice; }
    }
    if (!armed)
        return(false);

    double minFraction = MathMax(0.0, MathMin(1.0, PSAR_Arm_Min_Fraction));
    if (distancePrice < stepPrice * minFraction)
        return(false);

    return(IsPSARAligned(orderType, PSAR_Avg_TF));
}

bool IsAveragingTrendAllowed(int orderType, int existingOrders)
{
    // Filter Indikator pada entry Averaging (seperti RSI) 
    // terbukti menyebabkan "Retracement-Grid_Pipstep Paradox". Di mana saat harga memantul (unblocked), 
    // jaraknya jatuh di bawah Grid_Pipstep, dan saat jarak melampaui Grid_Pipstep, indikator memblokirnya.
    // Ini menyebabkan L1 nyangkut sendirian sejauh ribuan pips.
    // Solusi terbaik untuk menurunkan DD bukanlah menahan OP Averaging dengan indikator,
    // melainkan MELEBARKAN Grid_Pipstep secara dinamis saat tren kuat (sudah aktif di GetHybridPipstep).
    
    if (!Averaging_Block_Strong_CounterTrend)
        return(true);

    if (!IsStrongAdverseTrend(orderType))
        return(true);

    int blockFrom = MathMax(1, Averaging_Block_From_Existing);
    if (existingOrders >= blockFrom)
        return(false);

    return(true);
}

bool IsAveragingCandleConfirm(int orderType, int existingOrders)
{
    if (existingOrders < 1) return(true); // L1 selalu bebas

    // NEW: Filter BB + Volume khusus L2+
    if (Use_L2Plus_BB_Volume_Filter && existingOrders >= 1)
    {
        double bbUpper1 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_UPPER, 1);
        double bbLower1 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_LOWER, 1);
        double vol1 = iVolume(NULL, 0, 1);
        
        double maVol = 0;
        for (int i=2; i<=6; i++) maVol += iVolume(NULL, 0, i);
        if (maVol > 0) maVol /= 5.0;
        else maVol = 1.0;
        
        bool isVolumeClimax = (vol1 > maVol * L2Plus_Volume_Climax_Factor);
        
        if (orderType == OP_BUY)
        {
            // Averaging Buy hanya boleh jika harga menembus BB Bawah DAN Volume meledak
            if (Low[1] > bbLower1 || !isVolumeClimax)
                return false;
        }
        else if (orderType == OP_SELL)
        {
            // Averaging Sell hanya boleh jika harga menembus BB Atas DAN Volume meledak
            if (High[1] < bbUpper1 || !isVolumeClimax)
                return false;
        }
    }

    if (!Use_L3Plus_Candle_Confirm || existingOrders < L3Plus_Confirm_Min_Layer)
        return(true);
        
    if (orderType == OP_BUY)
    {
        return (Close[1] > Open[1]);
    }
    else if (orderType == OP_SELL)
    {
        return (Close[1] < Open[1]);
    }
    return(true);
}
double GetManagedOpenNetProfit()
{
    double net = 0.0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        // Termasuk Hedge Guard agar cut-loss akun menilai eksposur bersih yang sebenarnya.
        if (OrderSymbol() != Symbol() || !IsEAMagic(OrderMagicNumber()))
            continue;
        if (OrderType() != OP_BUY && OrderType() != OP_SELL)
            continue;
        net += OrderProfit() + OrderSwap() + OrderCommission();
    }
    return(net);
}

double GetSideBasketNetProfit(int orderType, int &count)
{
    double net = 0.0;
    count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol())
            continue;
            
        if (OrderMagicNumber() == Magic && OrderType() == orderType)
        {
            net += OrderProfit() + OrderSwap() + OrderCommission();
            count++;
        }
        else if (OrderMagicNumber() == GetHedgeMagic())
        {
    // Profit dari Hedge GUARD HARUS dihitung untuk mengurangi Drawdown Semu.
            // Hedge dari basket BUY adalah SELL, Hedge dari basket SELL adalah BUY.
            if (orderType == OP_BUY && OrderType() == OP_SELL)
                net += OrderProfit() + OrderSwap() + OrderCommission();
            else if (orderType == OP_SELL && OrderType() == OP_BUY)
                net += OrderProfit() + OrderSwap() + OrderCommission();
        }
    }
    return(net);
}

datetime GetSideBasketOldestOpenTime(int orderType)
{
    datetime oldest = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic || OrderType() != orderType)
            continue;

        if (oldest == 0 || OrderOpenTime() < oldest)
            oldest = OrderOpenTime();
    }
    return(oldest);
}

double GetSideBasketAgeHours(int orderType)
{
    datetime oldest = GetSideBasketOldestOpenTime(orderType);
    if (oldest <= 0)
        return(0.0);

    double ageSeconds = (double)(TimeCurrent() - oldest);
    if (ageSeconds < 0.0)
        ageSeconds = 0.0;
    return(ageSeconds / 3600.0);
}

datetime GetNewestOrderTime(int orderType)
{
    datetime newest = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == orderType)
            {
                if(OrderOpenTime() > newest)
                    newest = OrderOpenTime();
            }
        }
    }
    return newest;
}

double GetDynamicBasketRiskPct(int orderType, int count)
{
    double limitPct = MathMax(0.1, Side_Basket_Max_Loss_Pct);

    // NEW: Time Decay Risk Guard (Mengatasi Slow Bleed)
    if (Use_Time_Decay_Risk_Guard)
    {
        double ageHours = GetSideBasketAgeHours(orderType);
        if (ageHours > Time_Decay_Start_Hours)
        {
            double decayRangeHours = Time_Decay_End_Hours - Time_Decay_Start_Hours;
            if (decayRangeHours <= 0) decayRangeHours = 1.0;
            
            double elapsed = ageHours - Time_Decay_Start_Hours;
            double progress = MathMin(1.0, elapsed / decayRangeHours);
            
            // Linear interpolation from Side_Basket_Max_Loss_Pct down to Time_Decay_Min_Loss_Pct
            double decayAmount = (limitPct - Time_Decay_Min_Loss_Pct) * progress;
            limitPct = limitPct - decayAmount;
            
            limitPct = MathMax(limitPct, Time_Decay_Min_Loss_Pct);
        }
    }

    if (Use_Dynamic_Basket_Risk_Guard)
    {
        double dynLimit = Dynamic_Risk_L2_Pct;
        if (count == 3)
            dynLimit = Dynamic_Risk_L3_Pct;
        else if (count >= 4)
            dynLimit = Dynamic_Risk_L4Plus_Pct;

        double minPct = MathMax(0.1, Dynamic_Risk_Min_Pct);
        double maxPct = MathMax(minPct, Dynamic_Risk_Max_Pct);
        dynLimit = MathMax(minPct, MathMin(dynLimit, maxPct));
        
        limitPct = MathMin(limitPct, dynLimit);
    }

    return(limitPct);
}

double GetSideBasketLossPct(int orderType, int &count)
{
    double net = GetSideBasketNetProfit(orderType, count);
    double balance = AccountBalance();

    if (balance <= 0.0 || net >= 0.0)
        return(0.0);

    return((-net / balance) * 100.0);
}

bool IsBasketAveragingFrozen(int orderType, int existingOrders)
{
    // Pure Recovery: Averaging tidak pernah dibekukan
    if (!Use_Dynamic_Basket_Risk_Guard)
        return(false);

    return(false);
}

double GetPipstepRiskPressureMult(int orderType)
{
    return(1.0);
}

double GetBasketProfitTargetDollar(int count)
{
    double lotMultiplier = LOTnya() / (Lot > 0 ? Lot : 0.01);
    
    if (count <= 1) return(0.0);
    
    double target = 0.0;
    if (count == 2) target = Basket_Target_L2_Net;
    else if (count == 3) target = Basket_Target_L3_Net;
    else target = Basket_Target_L4Plus_Net;
    
    // NEW: Friday Panic Exit - Turunkan target 50% di hari Jumat agar cepat kabur sebelum Cut Loss jam 19:00!
    if (DayOfWeek() == 5) target *= 0.5;
    
    return(MathMax(0.0, target * lotMultiplier));
}

double GetBasketCloseReserveDollar(int orderType)
{
    double totalLots = 0.0;
    double commissionAbs = 0.0;
    double lotMultiplier = LOTnya() / (Lot > 0 ? Lot : 0.01);

    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic || OrderType() != orderType)
            continue;

        totalLots += OrderLots();
        commissionAbs += MathAbs(OrderCommission());
    }

    double reserve = MathMax(0.0, Basket_Close_Safety_Reserve_Dollar * lotMultiplier);
    reserve += commissionAbs;

    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);

    if (totalLots > 0.0 && tickValue > 0.0 && tickSize > 0.0 && pt > 0.0)
    {
        double moneyPerPip = (tickValue / tickSize) * pt * totalLots;
        reserve += moneyPerPip * MathMax(0.0, Basket_Close_Slippage_Reserve_Pips);
    }

    return(MathMax(0.0, reserve));
}

double GetBrokerStopDistancePrice()
{
    int stopLevel   = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
    int freezeLevel = (int)MarketInfo(Symbol(), MODE_FREEZELEVEL);
    int points      = MathMax(stopLevel, freezeLevel);
    return((points + 2) * Point);
}

bool IsChangedStopValid(int orderType,
                        double currentSL, double currentTP,
                        double newSL, double newTP)
{
    RefreshRates();
    double minDist = GetBrokerStopDistancePrice();

    bool slChanged = (ND(currentSL) != ND(newSL));
    bool tpChanged = (ND(currentTP) != ND(newTP));

    if (orderType == OP_BUY)
    {
        if (slChanged && newSL > 0.0 && newSL > Bid - minDist)
            return(false);
        if (tpChanged && newTP > 0.0 && newTP < Ask + minDist)
            return(false);
    }
    else if (orderType == OP_SELL)
    {
        if (slChanged && newSL > 0.0 && newSL < Ask + minDist)
            return(false);
        if (tpChanged && newTP > 0.0 && newTP > Bid - minDist)
            return(false);
    }

    return(true);
}

bool SafeModifyStops(int orderTicket, double newSL, double newTP)
{
    if (!OrderSelect(orderTicket, SELECT_BY_TICKET, MODE_TRADES))
        return(false);

    int type = OrderType();
    if (type != OP_BUY && type != OP_SELL)
        return(false);

    newSL = ND(newSL);
    newTP = ND(newTP);

    double oldSL = ND(OrderStopLoss());
    double oldTP = ND(OrderTakeProfit());

    if (oldSL == newSL && oldTP == newTP)
        return(true);

    if (!IsChangedStopValid(type, oldSL, oldTP, newSL, newTP))
        return(false);

    ResetLastError();
    if (OrderModify(orderTicket, OrderOpenPrice(), newSL, newTP, OrderExpiration()))
        return(true);

    return(false);
}

double GetSideBasketCosts(int orderType)
{
    double costs = 0.0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic || OrderType() != orderType)
            continue;
        costs += OrderSwap() + OrderCommission();
    }
    return(costs);
}

double GetCostAdjustedBasketBE(int orderType, double rawBep, double totalLots)
{
    if (!Use_Cost_Adjusted_Basket_TP || rawBep <= 0 || totalLots <= 0)
        return(rawBep);

    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
    if (tickValue <= 0 || tickSize <= 0)
        return(rawBep);

    double moneyPerPrice = (tickValue / tickSize) * totalLots;
    if (moneyPerPrice <= 0)
        return(rawBep);

    double costs = GetSideBasketCosts(orderType);
    double costShift = (-costs) / moneyPerPrice;
    if (costShift < 0)
        costShift = 0;

    if (orderType == OP_BUY)
        return(rawBep + costShift);
    if (orderType == OP_SELL)
        return(rawBep - costShift);

    return(rawBep);
}

bool CloseSideBasketProfit(int orderType, double netNow, double target)
{
    if (Basket_Profit_Debug)
        Print("BASKET PROFIT CLOSE TRIGGER | side=", (orderType == OP_BUY ? "BUY" : "SELL"),
              " net=", DoubleToStr(netNow, 2),
              " target=", DoubleToStr(target, 2));

    CUT(orderType);
    return(true);
}

// v79: tutup layer terbaru yang profit + sebagian lot layer tertua yang rugi.
// Net pasangan yang ditutup selalu >= Pair_Close_Min_Net_Dollar x skala lot, jadi realisasinya tidak rugi.
bool PairCloseSide(int orderType)
{
    int count = 0;
    int newestTicket = -1;
    int oldestTicket = -1;
    datetime newestTime = 0;
    datetime oldestTime = 0;

    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic || OrderType() != orderType)
            continue;

        count++;
        if (newestTicket < 0 || OrderOpenTime() > newestTime ||
            (OrderOpenTime() == newestTime && OrderTicket() > newestTicket))
        {
            newestTicket = OrderTicket();
            newestTime = OrderOpenTime();
        }
        if (oldestTicket < 0 || OrderOpenTime() < oldestTime ||
            (OrderOpenTime() == oldestTime && OrderTicket() < oldestTicket))
        {
            oldestTicket = OrderTicket();
            oldestTime = OrderOpenTime();
        }
    }

    if (count < MathMax(2, Pair_Close_Min_Layers) || newestTicket == oldestTicket)
        return(false);

    if (Pair_Close_Min_Basket_DD_Pct > 0.0)
    {
        int sideCount = 0;
        double sideNet = GetSideBasketNetProfit(orderType, sideCount);
        double balance = AccountBalance();
        if (balance <= 0.0 || sideNet >= 0.0 || (-sideNet / balance * 100.0) < Pair_Close_Min_Basket_DD_Pct)
            return(false);
    }

    if (!OrderSelect(newestTicket, SELECT_BY_TICKET, MODE_TRADES))
        return(false);
    double newestNet = OrderProfit() + OrderSwap() + OrderCommission();
    if (newestNet <= 0.0)
        return(false);

    if (!OrderSelect(oldestTicket, SELECT_BY_TICKET, MODE_TRADES))
        return(false);
    double oldestNet = OrderProfit() + OrderSwap() + OrderCommission();
    double oldestLots = OrderLots();
    if (oldestNet >= 0.0 || oldestLots <= 0.0)
        return(false); // basket yang sudah profit diurus ManageNetBasketProfit

    double lotMultiplier = LOTnya() / (Lot > 0 ? Lot : 0.01);
    double minNet = MathMax(0.0, Pair_Close_Min_Net_Dollar) * lotMultiplier;
    double budget = newestNet - minNet;
    if (budget <= 0.0)
        return(false);

    double lossPerLot = -oldestNet / oldestLots;
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
    if (lossPerLot <= 0.0 || lotStep <= 0.0)
        return(false);

    double closeLots = MathFloor((budget / lossPerLot) / lotStep + 1e-8) * lotStep;
    if (closeLots >= oldestLots)
        closeLots = oldestLots;
    else if (oldestLots - closeLots < minLot)
        closeLots = oldestLots - minLot; // sisa lot harus >= lot minimum broker
    closeLots = NormalizeDouble(closeLots, 2);
    if (closeLots < minLot)
        return(false);

    // Tutup yang profit dulu: bila penutupan layer tertua gagal, profit tetap terkunci.
    if (!CloseOrderTicketWithRetry(newestTicket, CLR_NONE))
        return(false);
    if (!CloseOrderTicketWithRetry(oldestTicket, CLR_NONE, closeLots))
        Print("PAIR CLOSE: layer terbaru ditutup, tetapi penutupan layer tertua gagal | ticket=", oldestTicket);

    if (Basket_Profit_Debug)
        Print("PAIR CLOSE | side=", (orderType == OP_BUY ? "BUY" : "SELL"),
              " newestNet=", DoubleToStr(newestNet, 2),
              " oldestLotsClosed=", DoubleToStr(closeLots, 2), "/", DoubleToStr(oldestLots, 2));
    return(true);
}

bool ManagePartialPairClose()
{
    if (!Use_Partial_Pair_Close)
        return(false);

    bool closedAny = false;
    if (PairCloseSide(OP_BUY))
        closedAny = true;
    if (PairCloseSide(OP_SELL))
        closedAny = true;
    return(closedAny);
}

bool ManageNetBasketProfit()
{
    if (!Use_Net_Basket_Profit_Close)
        return false;

    double lotMultiplier = LOTnya() / (Lot > 0 ? Lot : 0.01);
    bool closedAny = false;

    int buyCount = 0;
    double buyNet = GetSideBasketNetProfit(OP_BUY, buyCount);
    if (buyCount >= 2)
    {
        double buyTarget = GetBasketProfitTargetDollar(buyCount);
        double buyReserve = GetBasketCloseReserveDollar(OP_BUY);
        double buyTrigger = buyTarget
                          + MathMax(0.0, Basket_Close_Trigger_Buffer_Dollar * lotMultiplier)
                          + buyReserve;
                          
        if (Use_Escape_Guard && buyCount >= Escape_Min_Layers) {
            if (buyNet >= Escape_Activation_Dollar * lotMultiplier) {
                isBuyEscapeArmed = true;
            }
            if (isBuyEscapeArmed && buyNet <= Escape_CutLoss_Dollar * lotMultiplier) {
                if (Basket_Profit_Debug) Print("ESCAPE GUARD TRIGGERED (BUY)! Bailing out at ", buyNet);
                CloseSideBasketProfit(OP_BUY, buyNet, buyTarget);
                closedAny = true;
                isBuyEscapeArmed = false;
                highestBuyBasketNet = -999999;
            }
        }
                          
        if (Use_Trailing_Basket && !closedAny) {
            if (buyNet > highestBuyBasketNet) highestBuyBasketNet = buyNet;
            
            bool stochCut = false;
            if (Use_Stoch_Trailing_Basket && buyNet >= Stoch_Basket_Lock_Dollar * lotMultiplier) {
                double stK = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
                double stK_prev = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 1);
                
                // Jika M1 Stochastic berbalik turun dari area Overbought, langsung CUT (Lock profit di BEP)
                if (stK_prev > Stoch_Trail_OB && stK <= Stoch_Trail_OB) {
                    stochCut = true;
                }
                // Jika masih di area OB, aktifkan trailing ultra-ketat ($0.10)
                else if (stK > Stoch_Trail_OB) {
                    if (buyNet <= highestBuyBasketNet - (0.10 * lotMultiplier)) {
                        stochCut = true;
                    }
                }
            }
            
            if (stochCut) {
                CloseSideBasketProfit(OP_BUY, buyNet, buyTarget);
                closedAny = true;
                highestBuyBasketNet = -999999;
            }
            else if (highestBuyBasketNet >= buyTrigger) {
                if (buyNet <= highestBuyBasketNet - (Basket_Trailing_Step_Dollar * lotMultiplier)) {
                    CloseSideBasketProfit(OP_BUY, buyNet, buyTarget);
                    closedAny = true;
                    highestBuyBasketNet = -999999;
                }
            }
        } else {
            if (buyNet >= buyTrigger) {
                CloseSideBasketProfit(OP_BUY, buyNet, buyTarget);
                closedAny = true;
            }
        }
    } else {
        highestBuyBasketNet = -999999;
        isBuyEscapeArmed = false;
    }

    int sellCount = 0;
    double sellNet = GetSideBasketNetProfit(OP_SELL, sellCount);
    if (sellCount >= 2)
    {
        double sellTarget = GetBasketProfitTargetDollar(sellCount);
        double sellReserve = GetBasketCloseReserveDollar(OP_SELL);
        double sellTrigger = sellTarget
                           + MathMax(0.0, Basket_Close_Trigger_Buffer_Dollar * lotMultiplier)
                           + sellReserve;
                           
        if (Use_Escape_Guard && sellCount >= Escape_Min_Layers) {
            if (sellNet >= Escape_Activation_Dollar * lotMultiplier) {
                isSellEscapeArmed = true;
            }
            if (isSellEscapeArmed && sellNet <= Escape_CutLoss_Dollar * lotMultiplier) {
                if (Basket_Profit_Debug) Print("ESCAPE GUARD TRIGGERED (SELL)! Bailing out at ", sellNet);
                CloseSideBasketProfit(OP_SELL, sellNet, sellTarget);
                closedAny = true;
                isSellEscapeArmed = false;
                highestSellBasketNet = -999999;
            }
        }
                           
        if (Use_Trailing_Basket && !closedAny) {
            if (sellNet > highestSellBasketNet) highestSellBasketNet = sellNet;
            
            bool stochCutSell = false;
            if (Use_Stoch_Trailing_Basket && sellNet >= Stoch_Basket_Lock_Dollar * lotMultiplier) {
                double stKSell = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
                double stK_prevSell = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 1);
                
                // Jika M1 Stochastic berbalik naik dari area Oversold, langsung CUT (Lock profit di BEP)
                if (stK_prevSell < Stoch_Trail_OS && stKSell >= Stoch_Trail_OS) {
                    stochCutSell = true;
                }
                // Jika masih di area OS, aktifkan trailing ultra-ketat ($0.10)
                else if (stKSell < Stoch_Trail_OS) {
                    if (sellNet <= highestSellBasketNet - (0.10 * lotMultiplier)) {
                        stochCutSell = true;
                    }
                }
            }
            
            if (stochCutSell) {
                CloseSideBasketProfit(OP_SELL, sellNet, sellTarget);
                closedAny = true;
                highestSellBasketNet = -999999;
            }
            else if (highestSellBasketNet >= sellTrigger) {
                if (sellNet <= highestSellBasketNet - (Basket_Trailing_Step_Dollar * lotMultiplier)) {
                    CloseSideBasketProfit(OP_SELL, sellNet, sellTarget);
                    closedAny = true;
                    highestSellBasketNet = -999999;
                }
            }
        } else {
            if (sellNet >= sellTrigger) {
                CloseSideBasketProfit(OP_SELL, sellNet, sellTarget);
                closedAny = true;
            }
        }
    } else {
        highestSellBasketNet = -999999;
        isSellEscapeArmed = false;
    }
    return closedAny;
}

bool DetectMarketAnomaly(int orderType)
{
    double atr = iATR(NULL, PERIOD_H1, 14, 1);
    if (atr <= 0) return false;
    
    double ema50 = iMA(NULL, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE, 1);
    double bbUp = iBands(NULL, PERIOD_H1, 20, 2.5, 0, PRICE_CLOSE, MODE_UPPER, 1);
    double bbDn = iBands(NULL, PERIOD_H1, 20, 2.5, 0, PRICE_CLOSE, MODE_LOWER, 1);
    double bbWidth = bbUp - bbDn;
    
    bool isSuperVolatile = (bbWidth > 4.0 * atr);
    
    if (orderType == OP_BUY)
    {
        if ((ema50 - Bid > 3.0 * atr) && isSuperVolatile && Bid < bbDn) return true;
    }
    else if (orderType == OP_SELL)
    {
        if ((Ask - ema50 > 3.0 * atr) && isSuperVolatile && Ask > bbUp) return true;
    }
    
    return false;
}

bool ManageSideBasketRisk()
{
    if (!Use_Dynamic_Basket_Risk_Guard && !Use_Side_Basket_Loss_Guard && !Use_Anomaly_Emergency_Close)
        return false;

    double balance = AccountBalance();
    if (balance <= 0.0)
        return false;

    bool closedAny = false;
    int minOrders = MathMax(1, Side_Basket_Stop_Min_Orders);

    int buyCount = 0;
    double buyNet = GetSideBasketNetProfit(OP_BUY, buyCount);

    if (buyCount >= minOrders && buyNet < 0.0)
    {
        double buyLimitPct = GetDynamicBasketRiskPct(OP_BUY, buyCount);
        if (Use_Anomaly_Emergency_Close && DetectMarketAnomaly(OP_BUY))
        {
            buyLimitPct = MathMin(buyLimitPct, Anomaly_Emergency_Loss_Pct);
            Print("ANOMALY DETECTED (BUY)! Menerapkan Emergency Close Limit: ", buyLimitPct, "%");
        }
        
        double buyTriggerPct = MathMax(0.10, buyLimitPct - MathMax(0.0, Side_Basket_Risk_Trigger_Buffer_Pct));
        double buyMaxLoss = balance * buyTriggerPct / 100.0;

        if (buyNet <= -buyMaxLoss)
        {
            CUT(OP_BUY);
            SetRiskStopCooldown(OP_BUY);
            closedAny = true;
        }
    }

    int sellCount = 0;
    double sellNet = GetSideBasketNetProfit(OP_SELL, sellCount);

    if (sellCount >= minOrders && sellNet < 0.0)
    {
        double sellLimitPct = GetDynamicBasketRiskPct(OP_SELL, sellCount);
        if (Use_Anomaly_Emergency_Close && DetectMarketAnomaly(OP_SELL))
        {
            sellLimitPct = MathMin(sellLimitPct, Anomaly_Emergency_Loss_Pct);
            Print("ANOMALY DETECTED (SELL)! Menerapkan Emergency Close Limit: ", sellLimitPct, "%");
        }
        
        double sellTriggerPct = MathMax(0.10, sellLimitPct - MathMax(0.0, Side_Basket_Risk_Trigger_Buffer_Pct));
        double sellMaxLoss = balance * sellTriggerPct / 100.0;

        if (sellNet <= -sellMaxLoss)
        {
            CUT(OP_SELL);
            SetRiskStopCooldown(OP_SELL);
            closedAny = true;
        }
    }
    return closedAny;
}

bool CanOpenNewOrder(int orderType, double lots)
{
    if (!Use_Averaging_Margin_Guard)
        return(true);
    if (lots <= 0)
        return(false);

    ResetLastError();
    double freeAfter = AccountFreeMarginCheck(Symbol(), orderType, lots);
    int err = GetLastError();
    if (freeAfter <= 0 || err == 134)
        return(false);

    double equity = AccountEquity();
    if (equity > 0 && Min_FreeMargin_After_Avg_PctEquity > 0)
    {
        double minFree = equity * Min_FreeMargin_After_Avg_PctEquity / 100.0;
        if (freeAfter < minFree)
            return(false);
    }

    return(true);
}

double ClampPipstepValue(double value, double minValue, double maxValue)
{
    if (value < minValue) value = minValue;
    if (maxValue > 0 && value > maxValue) value = maxValue;
    return(value);
}

double GetAverageDailyRangePips(int days)
{
    if (days < 1) days = 1;
    double total = 0.0;
    int counted = 0;

    for (int shift = 1; shift <= days; shift++)
    {
        double hi = iHigh(NULL, PERIOD_D1, shift);
        double lo = iLow(NULL, PERIOD_D1, shift);
        if (hi <= 0 || lo <= 0 || hi <= lo)
            continue;

        total += (hi - lo) / pt;
        counted++;
    }

    if (counted <= 0)
        return(0.0);
    return(total / counted);
}

double GetTodayRangePips()
{
    double hi = iHigh(NULL, PERIOD_D1, 0);
    double lo = iLow(NULL, PERIOD_D1, 0);
    if (hi <= 0 || lo <= 0 || hi <= lo)
        return(0.0);
    return((hi - lo) / pt);
}

double GetHybridPipstep(int existingOrders, int orderType)
{
    double minimumStep = MathMax(1.0, Minimum_Pipstep);
    double staticBase = MathMax(Grid_Pipstep, minimumStep);

    if (!Use_Hybrid_Pipstep)
    {
        if (Pipstep_Exponent > 1.0 && existingOrders >= 2)
            staticBase *= MathPow(Pipstep_Exponent, existingOrders - 1);
        return(staticBase);
    }
    
    // NEW: Adaptive Grid_Pipstep using Bollinger Band Width (H1)
    if (Use_BB_Adaptive_Pipstep && BB_Pipstep_Fraction > 0)
    {
        double bbUp = iBands(NULL, Trend_Timeframe, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_UPPER, 1);
        double bbDn = iBands(NULL, Trend_Timeframe, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_LOWER, 1);
        if (bbUp > 0 && bbDn > 0 && pt > 0)
        {
            double bbWidthPips = (bbUp - bbDn) / pt;
            double bbPipstep = bbWidthPips * BB_Pipstep_Fraction;
            // Jika BB sedang melebar drastis, Grid_Pipstep akan ikut melebar.
            staticBase = MathMax(staticBase, bbPipstep);
        }
    }

    int fastDays = MathMax(1, Pipstep_ADR_Fast_Days);
    int slowDays = MathMax(fastDays + 1, Pipstep_ADR_Slow_Days);
    double adrFast = GetAverageDailyRangePips(fastDays);
    double adrSlow = GetAverageDailyRangePips(slowDays);

    double adaptiveMax = MathMax(1.0, Pipstep_Adaptive_Max_Factor);
    double absoluteMax = MathMax(adaptiveMax, Pipstep_Absolute_Max_Factor);
    double factor = 1.0;

    if (adrFast > 0 && adrSlow > 0)
        factor = adrFast / adrSlow;
    factor = ClampPipstepValue(factor, 1.0, adaptiveMax);

    if (adrFast > 0)
    {
        double todayRatio = GetTodayRangePips() / adrFast;
        double trigger = Pipstep_Today_Range_Trigger;
        if (trigger < 0.10) trigger = 0.10;
        if (trigger > 0.95) trigger = 0.95;

        if (todayRatio > trigger)
        {
            double progress = (todayRatio - trigger) / (1.0 - trigger);
            progress = ClampPipstepValue(progress, 0.0, 1.0);
            factor = factor + (absoluteMax - factor) * progress;
        }
    }

    factor = ClampPipstepValue(factor, 1.0, absoluteMax);
    double result = staticBase * factor;

    double h1Atr = iATR(NULL, Trend_Timeframe, Trend_ATR_Period, 1);
    if (h1Atr > 0 && pt > 0 && Pipstep_H1_ATR_Fraction > 0)
    {
        double atrFloorPips = (h1Atr / pt) * Pipstep_H1_ATR_Fraction;
        result = MathMax(result, atrFloorPips);
    }

    double levelMult = Pipstep_L2_Mult;
    double levelCap = Pipstep_L2_Cap;
    string levelName = "L2";

    if (existingOrders == 2)
    {
        levelMult = Pipstep_L3_Mult;
        levelCap = Pipstep_L3_Cap;
        levelName = "L3";
    }
    else if (existingOrders == 3)
    {
        levelMult = Pipstep_L4_Mult;
        levelCap = Pipstep_L4_Cap;
        levelName = "L4";
    }
    else if (existingOrders >= 4)
    {
        levelMult = Pipstep_L5Plus_Mult;
        levelCap = Pipstep_L5Plus_Cap;
        levelName = "L5+";
    }

    double exponentMult = 1.0;
    if (Pipstep_Exponent > 1.0 && existingOrders >= 2)
    {
        exponentMult = MathPow(Pipstep_Exponent, existingOrders - 1);
    }
    
    // MENCEGAH DOUBLE COMPOUNDING:
    double finalMult = MathMax(levelMult, exponentMult);
    result *= MathMax(1.0, finalMult);

    // ================= TREN KUAT (ADVERSE TREND) =================
    // Jika EA sedang melawan arus tren yang sangat kuat, lebarkan Grid_Pipstep sedikit 
    // (default 1.20x) agar tidak terlalu cepat nyangkut di awal spike.
    if (IsStrongAdverseTrend(orderType))
    {
        double advMult = Pipstep_Adverse_Trend_Mult;
        if (advMult < 1.0) advMult = 1.0;
        if (advMult > 3.0) advMult = 3.0;
        result *= advMult;
    }
    // =============================================================

    // ================= HYBRID VELOCITY EXPANDER (L3+) =================
    // NEW: Maksimalkan adaptif hibrida untuk L3 ke atas berdasarkan kecepatan jatuh harga (Velocity).
    if (existingOrders >= 2 && Use_BB_Adaptive_Pipstep) 
    {
        double distancePips = 0;
        datetime oldestTime = GetSideBasketOldestOpenTime(orderType);
        if (oldestTime > 0)
        {
            double elapsedMinutes = (TimeCurrent() - oldestTime) / 60.0;
            if (elapsedMinutes > 0 && elapsedMinutes < 1440.0)
            {
                if (orderType == OP_BUY) distancePips = (lobuy - Ask) / pt;
                if (orderType == OP_SELL) distancePips = (Bid - hisell) / pt;
                
                if (distancePips > 0)
                {
                    double velocityPipsPerMinute = distancePips / elapsedMinutes;
                    if (velocityPipsPerMinute > 2.0) // Jatuh > 2 pips per menit konstan
                    {
                        double velocityMult = 1.0 + (velocityPipsPerMinute / 5.0);
                        velocityMult = MathMin(velocityMult, 2.5); // Max 2.5x
                        result *= velocityMult;
                    }
                }
            }
        }
    }
    // =========================================================================

    // ================= M15 RSI EXTREME EXPANDER (L3+) =================
    // Memblokir OP dengan RSI memicu "Retracement-Grid_Pipstep Paradox".
    // Solusi brilian: Jangan blokir, tapi KALIKAN Grid_Pipstep 2x lipat saat RSI M15 Ekstrem!
    // Saat RSI memantul normal, Grid_Pipstep menyusut seketika dan EA langsung "Sniper Entry" di dasar harga.
    if (existingOrders >= 2)
    {
        double rsiM15_1 = iRSI(NULL, PERIOD_M15, 14, PRICE_CLOSE, 1);
        if (orderType == OP_BUY && rsiM15_1 < 30) {
            result *= 2.0; 
        }
        else if (orderType == OP_SELL && rsiM15_1 > 70) {
            result *= 2.0;
        }
    }
    // =========================================================================

    // ================= GRID EXPANSION PADA DRAWDOWN TINGGI =================
    // Mengkompres (merapatkan) Grid saat Drawdown tinggi adalah kesalahan fatal (Death Spiral).
    // Jika DD sedang tinggi, itu artinya kita sedang terseret tren kuat. Peluru harus direnggangkan (Expand)
    // agar Margin tidak cepat habis dan kita bisa bertahan hingga tren benar-benar berbalik!
    int tmpCount = 0;
    double netBasketProfit = GetSideBasketNetProfit(orderType, tmpCount);
    double basketDDPct = 0;
    if (netBasketProfit < 0 && AccountBalance() > 0) {
        basketDDPct = (MathAbs(netBasketProfit) / AccountBalance()) * 100.0;
    }
    
    double maxLossPct = Side_Basket_Max_Loss_Pct > 0 ? Side_Basket_Max_Loss_Pct : 40.0;
    if (basketDDPct >= (maxLossPct * 0.70)) {
        result *= 1.50; // Expand 1.5x (Gentle stretch agar L4/L5 tetap bisa terbuka untuk menyelamatkan)
    } 
    else if (basketDDPct >= (maxLossPct * 0.50)) {
        result *= 1.25; // Expand 1.25x 
    }
    else if (basketDDPct >= (maxLossPct * 0.30)) {
        result *= 1.10; // Expand 1.1x 
    }
    // =========================================================================

    result = MathMax(result, minimumStep);
    if (levelCap > 0)
        result = MathMin(result, MathMax(levelCap, minimumStep));
    if (Pipstep_Global_Max > 0)
        result = MathMin(result, MathMax(Pipstep_Global_Max, minimumStep));

    result = NormalizeDouble(result, 0);
    PipStep_ = result;

    return(result);
}

bool IsL1StochReady(int orderType)
{
    int enabled = 0;
    int passed  = 0;

    if (UsedRSI)
    {
        enabled++;
        double rsiValue = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
        bool rsiBuy  = (rsiValue <= RSI_Lower_Level);
        bool rsiSell = (rsiValue >= RSI_Upper_Level);
        if ((orderType == OP_BUY && rsiBuy) || (orderType == OP_SELL && rsiSell))
            passed++;
    }

    if (UsedStoc)
    {
        enabled++;
        bool slowBuy  = (fnc02(1) > fnc13(1) && fnc13(0) <= L1_Stoch_Lower_Level);
        bool slowSell = (fnc02(1) < fnc13(1) && fnc13(0) >= L1_Stoch_Upper_Level);
        if ((orderType == OP_BUY && slowBuy) || (orderType == OP_SELL && slowSell))
            passed++;
    }

    if (UsedStoci2)
    {
        enabled++;
        bool fastBuy  = (fnc02i(1) > fnc13i(1) && fnc13i(0) <= L1_Stoch_Lower_Level);
        bool fastSell = (fnc02i(1) < fnc13i(1) && fnc13i(0) >= L1_Stoch_Upper_Level);
        if ((orderType == OP_BUY && fastBuy) || (orderType == OP_SELL && fastSell))
            passed++;
    }

    if (enabled <= 0)
        return(true);

    int required = L1_Stoch_Min_Confirmations;
    if (required < 1) required = 1;
    if (required > enabled) required = enabled;

    return(passed >= required);
}

bool IsL1VolumePatternAtShift(int climaxShift)
{
    if (climaxShift < 1)
        return(false);

    int avgPeriod = L1_Volume_Avg_Period;
    if (avgPeriod < 5) avgPeriod = 14;

    if (Bars < climaxShift + avgPeriod + 1)
        return(false);

    double vClimax = (double)Volume[climaxShift];
    
    // Memaksimalkan indikator volume bukan berarti mencari "Staircase" (tangga beruntun)
    // yang sangat jarang terjadi. Makna sebenarnya dari Volume Climax adalah lonjakan volume 
    // yang signifikan melebihi rata-rata (Moving Average) volume sebelumnya.
    double sumVolume = 0;
    for (int i = 1; i <= avgPeriod; i++) {
        sumVolume += (double)Volume[climaxShift + i];
    }
    double avgVolume = sumVolume / avgPeriod;

    if (avgVolume <= 0) return true; // Tidak ada data volume yang valid, bypass

    // Volume harus minimal 20% lebih besar dari rata-rata (bisa diatur lewat parameter)
    double minMultiplier = 1.20; 
    if (vClimax >= avgVolume * minMultiplier) {
        return true;
    }

    return false;
}

bool IsL1VolumeReversalReady(int orderType)
{
    if (Max_L1_Candle_Size_Pips > 0)
    {
        double myPt = (pt > 0.0) ? pt : Point;
        double candleSizePips = (High[1] - Low[1]) / myPt;
        if (candleSizePips > Max_L1_Candle_Size_Pips)
        {
            if (L1_Volume_Debug) Print("BLOCK L1: Candle size ", candleSizePips, " pips exceeds limit ", Max_L1_Candle_Size_Pips);
            return(false);
        }
    }

    if (Use_L1_Volume_Staircase)
    {
        double vol1 = iVolume(NULL, L1_Volume_Staircase_TF, 1);
        double vol2 = iVolume(NULL, L1_Volume_Staircase_TF, 2);
        double vol3 = iVolume(NULL, L1_Volume_Staircase_TF, 3);
        
        if (!(vol1 > vol2 && vol2 > vol3))
        {
            return(false);
        }
    }

    if (!Use_L1_Volume_Reversal)
        return(true);

    int armedBars = L1_Volume_Armed_Bars;
    if (armedBars < 1) armedBars = 1;

    bool priceConfirm = true;
    if (L1_Volume_Require_Price_Confirm)
    {
        if (Bars < 3)
            return(false);
        if (orderType == OP_BUY)
            priceConfirm = (Close[1] > Open[1]);
        else if (orderType == OP_SELL)
            priceConfirm = (Close[1] < Open[1]);
    }

    if (!priceConfirm)
        return(false);

    for (int postBars = 1; postBars <= armedBars; postBars++)
    {
        int climaxShift = postBars + 1;
        if (IsL1VolumePatternAtShift(climaxShift))
            return(true);
    }

    return(false);
}

bool IsSwingLow(int shift, int depth)
{
    if (shift <= depth) return(false);
    for (int i = 1; i <= depth; i++)
    {
        if (Low[shift] > Low[shift - i] || Low[shift] > Low[shift + i])
            return(false);
    }
    return(true);
}

bool IsSwingHigh(int shift, int depth)
{
    if (shift <= depth) return(false);
    for (int i = 1; i <= depth; i++)
    {
        if (High[shift] < High[shift - i] || High[shift] < High[shift + i])
            return(false);
    }
    return(true);
}

double GetATR_SRBB(int shift)
{
    return(iATR(NULL, 0, ATR_Period_SRBB, shift));
}

void GetNearestSRLevels(double &support, double &resistance)
{
    support = 0;
    resistance = 0;
    double price = Close[1];

    for (int i = SR_SwingDepth + 1; i <= SR_Lookback; i++)
    {
        if (support == 0 && IsSwingLow(i, SR_SwingDepth) && Low[i] <= price)
            support = Low[i];

        if (resistance == 0 && IsSwingHigh(i, SR_SwingDepth) && High[i] >= price)
            resistance = High[i];

        if (support > 0 && resistance > 0)
            break;
    }

    if (support <= 0)
        support = Low[iLowest(NULL, 0, MODE_LOW, SR_Lookback, 1)];

    if (resistance <= 0)
        resistance = High[iHighest(NULL, 0, MODE_HIGH, SR_Lookback, 1)];
}

int GetL1SRBBBuyScore()
{
    if (Bars < MathMax(SR_Lookback + SR_SwingDepth + 5, BB_Period + 5)) return(0);
    double atr = GetATR_SRBB(1);
    if (atr <= 0) return(0);

    double support, resistance;
    GetNearestSRLevels(support, resistance);

    double bbLower1 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_LOWER, 1);
    double bbLower2 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_LOWER, 2);
    double bbMid1   = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_MAIN, 1);
    double bbMid2   = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_MAIN, 2);

    double zone = atr * SR_Zone_ATR_Mult;
    bool touchSupport = (Low[1] <= support + zone);
    bool reEntryBB = ((Close[2] < bbLower2) || (Low[1] < bbLower1)) && (Close[1] > bbLower1);
    bool bullishReject = Close[1] > Open[1];
    bool midSlopeOK = (!Require_BB_Mid_Slope || bbMid1 > bbMid2);
    bool roomOK = ((resistance - Ask) >= atr * Min_Room_ATR_Target);

    int score = 0;
    if (touchSupport)  score++;
    if (reEntryBB)     score++;
    if (bullishReject) score++;
    if (midSlopeOK)    score++;
    if (roomOK)        score++;

    return(score);
}

int GetL1SRBBSellScore()
{
    if (Bars < MathMax(SR_Lookback + SR_SwingDepth + 5, BB_Period + 5)) return(0);
    double atr = GetATR_SRBB(1);
    if (atr <= 0) return(0);

    double support, resistance;
    GetNearestSRLevels(support, resistance);

    double bbUpper1 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_UPPER, 1);
    double bbUpper2 = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_UPPER, 2);
    double bbMid1   = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_MAIN, 1);
    double bbMid2   = iBands(NULL, 0, BB_Period, BB_Deviation, BB_Shift, BB_AppliedPrice, MODE_MAIN, 2);

    double zone = atr * SR_Zone_ATR_Mult;
    bool touchResistance = (High[1] >= resistance - zone);
    bool reEntryBB = ((Close[2] > bbUpper2) || (High[1] > bbUpper1)) && (Close[1] < bbUpper1);
    bool bearishReject = Close[1] < Open[1];
    bool midSlopeOK = (!Require_BB_Mid_Slope || bbMid1 < bbMid2);
    bool roomOK = ((Bid - support) >= atr * Min_Room_ATR_Target);

    int score = 0;
    if (touchResistance) score++;
    if (reEntryBB)       score++;
    if (bearishReject)   score++;
    if (midSlopeOK)      score++;
    if (roomOK)          score++;

    return(score);
}

bool IsL1SRBBBuySignal()
{
    int need = L1_SRBB_Min_Score;
    if (need < 1) need = 1;
    if (need > 5) need = 5;
    return(GetL1SRBBBuyScore() >= need);
}

bool IsL1SRBBSellSignal()
{
    int need = L1_SRBB_Min_Score;
    if (need < 1) need = 1;
    if (need > 5) need = 5;
    return(GetL1SRBBSellScore() >= need);
}

double GetRawBaseLot()
{
    if (Auto_Compounding_Lot && Lot_Base_Balance_Safe > 0.0)
        return(Lot * (AccountBalance() / Lot_Base_Balance_Safe));

    if (!Compound)
        return(Lot);

    double tick = MarketInfo(Symbol(), MODE_TICKVALUE);
    if (tick <= 0.0 || Ketahanan_pip <= 0.0 || dg <= 0.0)
    {
        Print("COMPOUND LOT FALLBACK: nilai tick/pip tidak valid; menggunakan Lot tetap.");
        return(Lot);
    }

    return(AccountBalance() / (Ketahanan_pip * dg * tick));
}

double LOTnya()
{
    double lot = GetRawBaseLot();

    if (Max_L1_Lot > 0.0 && lot > Max_L1_Lot)
        lot = Max_L1_Lot;

    if (Survive_Adverse_Move_Pips > 0.0)
    {
        double survivalCap = GetSurvivalLotCap(Survive_Adverse_Move_Pips);
        if (survivalCap > 0.0 && lot > survivalCap)
            lot = survivalCap;

        if (survivalCap > 0.0 && survivalCap < MarketInfo(Symbol(), MODE_MINLOT))
        {
            static bool sMinLotWarned = false;
            if (!sMinLotWarned)
            {
                Print("SURVIVAL LOT WARNING: balance terlalu kecil untuk Survive_Adverse_Move_Pips=",
                      DoubleToStr(Survive_Adverse_Move_Pips, 0), "; lot dipaksa ke minimum broker sehingga risiko melebihi target.");
                sMinLotWarned = true;
            }
        }
    }

    return(NR(lot));
}

//==================== v78: GRID RISK MODEL ====================
// Model grid statis: jarak layer sama dengan GetHybridPipstep() saat Use_Hybrid_Pipstep=false,
// kelipatan lot sama dengan GetAdaptiveRecoveryLot() tanpa penyesuaian adaptif.

int GetModelMaxLayers()
{
    if (!Use_Martiangle)
        return(1);
    return((int)MathMax(1, MathMax(Max_Buy_Layers, Max_Sell_Layers)));
}

double GetStaticStepPips(int existingOrders)
{
    double stepPips = MathMax(Grid_Pipstep, MathMax(1.0, Minimum_Pipstep));
    if (Pipstep_Exponent > 1.0 && existingOrders >= 2)
        stepPips *= MathPow(Pipstep_Exponent, existingOrders - 1);
    return(stepPips);
}

// Kelipatan lot layer ke-n terhadap lot L1 (layer mulai dari 1).
double GetStaticLotMultiple(int layer)
{
    if (layer <= 1)
        return(1.0);
    if (layer == 2)
        return(Averaging_Lot_Multiplier_L2);
    return(Averaging_Lot_Multiplier_L2 * MathPow(Averaging_Lot_Multiplier, layer - 2));
}

// Jarak (pips EA) dari harga L1 ke harga pembukaan layer ke-n.
double GetStaticLayerOffsetPips(int layer)
{
    double offset = 0.0;
    for (int k = 1; k < layer; k++)
        offset += GetStaticStepPips(k);
    return(offset);
}

double GetMoneyPerPricePerLot()
{
    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
    if (tickValue <= 0.0 || tickSize <= 0.0)
        return(0.0);
    return(tickValue / tickSize);
}

// Estimasi rugi mengambang (USD) per 1.0 lot L1 saat harga bergerak adversePips melawan L1
// dan semua layer yang jaraknya sudah terlewati ikut terbuka.
double EstimateGridLossPerL1Lot(double adversePips)
{
    double moneyPerPrice = GetMoneyPerPricePerLot();
    if (moneyPerPrice <= 0.0 || pt <= 0.0 || adversePips <= 0.0)
        return(0.0);

    int maxLayers = GetModelMaxLayers();
    double loss = 0.0;
    for (int layer = 1; layer <= maxLayers; layer++)
    {
        double offsetPips = GetStaticLayerOffsetPips(layer);
        if (offsetPips > adversePips)
            break;
        loss += GetStaticLotMultiple(layer) * (adversePips - offsetPips) * pt * moneyPerPrice;
    }
    return(loss);
}

double GetGridLossBudget()
{
    return(AccountBalance() * MathMax(0.0, Percent_Loss) / 100.0);
}

// Lot L1 maksimum agar rugi grid belum mencapai Percent_Loss sebelum harga bergerak adversePips.
double GetSurvivalLotCap(double adversePips)
{
    double lossPerLot = EstimateGridLossPerL1Lot(adversePips);
    double budget = GetGridLossBudget();
    if (lossPerLot <= 0.0 || budget <= 0.0)
        return(0.0);
    return(budget / lossPerLot);
}

// Jarak (pips EA) melawan L1 saat rugi grid menyentuh Percent_Loss untuk lot L1 tertentu.
double GetBreakerDistancePips(double l1Lot)
{
    double budget = GetGridLossBudget();
    if (l1Lot <= 0.0 || budget <= 0.0)
        return(0.0);

    double lo = 0.0;
    double hi = 1000.0;
    int expand = 0;
    while (EstimateGridLossPerL1Lot(hi) * l1Lot < budget && expand < 30)
    {
        lo = hi;
        hi *= 2.0;
        expand++;
    }
    if (EstimateGridLossPerL1Lot(hi) * l1Lot < budget)
        return(0.0);

    for (int iter = 0; iter < 50; iter++)
    {
        double mid = (lo + hi) / 2.0;
        if (EstimateGridLossPerL1Lot(mid) * l1Lot >= budget)
            hi = mid;
        else
            lo = mid;
    }
    return(hi);
}

void PrintGridRiskReport()
{
    double moneyPerPrice = GetMoneyPerPricePerLot();
    if (pt <= 0.0 || moneyPerPrice <= 0.0)
    {
        Print("GRID RISK REPORT: data tick belum valid, laporan dilewati.");
        return;
    }

    double l1Lot = LOTnya();
    double balance = AccountBalance();
    int maxLayers = GetModelMaxLayers();

    Print("===== GRID RISK REPORT v78 | ", Symbol(), " | balance=", DoubleToStr(balance, 2),
          " | lot L1=", DoubleToStr(l1Lot, 2), " | 1 pip EA=", DoubleToStr(pt, Digits), " harga =====");

    double cumLots = 0.0;
    for (int layer = 1; layer <= maxLayers; layer++)
    {
        double offsetPips = GetStaticLayerOffsetPips(layer);
        double layerLot = l1Lot * GetStaticLotMultiple(layer);
        cumLots += layerLot;

        // Rugi saat harga mencapai level layer berikutnya (untuk layer terakhir: satu step lagi).
        double nextPips = offsetPips + GetStaticStepPips(layer);
        double lossNext = EstimateGridLossPerL1Lot(nextPips) * l1Lot;
        double lossPct = (balance > 0.0) ? lossNext / balance * 100.0 : 0.0;

        Print("L", layer, " | jarak dari L1=", DoubleToStr(offsetPips, 0), " pips (", DoubleToStr(offsetPips * pt, 2),
              ") | lot~", DoubleToStr(layerLot, 2), " | total lot~", DoubleToStr(cumLots, 2),
              " | rugi saat harga di ", DoubleToStr(nextPips, 0), " pips = ", DoubleToStr(lossNext, 2),
              " (", DoubleToStr(lossPct, 1), "% balance)");
    }

    double breakerPips = GetBreakerDistancePips(l1Lot);
    if (breakerPips > 0.0)
        Print("CUT-LOSS ", DoubleToStr(Percent_Loss, 1), "% tercapai bila harga bergerak ~", DoubleToStr(breakerPips, 0),
              " pips (", DoubleToStr(breakerPips * pt, 2), " harga) melawan L1. Lot adaptif L3+ bisa sampai ",
              DoubleToStr(ADAPTIVE_LOT_MAX_FACTOR, 2), "x statis, jadi jarak aktual bisa lebih pendek.");
    Print("Catatan: model memakai grid statis (Use_Hybrid_Pipstep=false) dan mengabaikan hedge, swap, komisi, serta gap harga.");
}

void CUT_HEDGE(int hedgeType)
{
    for (int x = OrdersTotal() - 1; x >= 0; x--)
    {
        if (OrderSelect(x, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderMagicNumber() == GetHedgeMagic() && OrderSymbol() == Symbol() && OrderType() == hedgeType)
            {
                CloseOrderTicketWithRetry(OrderTicket(), CLR_NONE);
            }
        }
    }
}

void ManageHedgeTrailing()
{
    if (!Use_L4_Hedge_Guard) return;
    
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == GetHedgeMagic() && OrderSymbol() == Symbol())
        {
            double sl = 0;
            if (OrderType() == OP_BUY)
            {
                if (Bid - OrderOpenPrice() > Hedge_Trailing_Start_Pips * pt)
                {
                    sl = Bid - Hedge_Trailing_Step_Pips * pt;
                    if (OrderStopLoss() < sl || OrderStopLoss() == 0) {
                        bool mod1 = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0, clrBlue);
                    }
                }
            }
            else if (OrderType() == OP_SELL)
            {
                if (OrderOpenPrice() - Ask > Hedge_Trailing_Start_Pips * pt)
                {
                    sl = Ask + Hedge_Trailing_Step_Pips * pt;
                    if (OrderStopLoss() > sl || OrderStopLoss() == 0) {
                        bool mod2 = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0, clrRed);
                    }
                }
            }
        }
    }
}

void CUT(int tip)
{
    if (tip == OP_BUY) CUT_HEDGE(OP_SELL);
    if (tip == OP_SELL) CUT_HEDGE(OP_BUY);
    
    for (int x = OrdersTotal() - 1; x >= 0; x--)
    {
        if (!OrderSelect(x, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderMagicNumber() != Magic || OrderSymbol() != Symbol())
            continue;
        if (OrderType() != tip)
            continue;

        int tk = OrderTicket();
        if (!CloseOrderTicketWithRetry(tk, CLR_NONE))
            Print("CUT gagal setelah retry | ticket=", tk);
    }
}

double fnc02( int sif)
{  
    double cc =iStochastic(NULL, 0, input22, input23, input24, MODE_SMA, 0, MODE_MAIN, sif);
    return(cc);  
}

double fnc13( int sif)
{  
    double cc =iStochastic(NULL, 0, input22, input23, input24, MODE_SMA, 0, MODE_SIGNAL, sif);
    return(cc);  
}  

double fnc02i( int sif)
{  
    double cc =iStochastic(NULL, 0, input22i, input23i, input24i, MODE_SMA, 0, MODE_MAIN, sif);
    return(cc);  
}

double fnc13i( int sif)
{  
    double cc =iStochastic(NULL, 0, input22i, input23i, input24i, MODE_SMA, 0, MODE_SIGNAL, sif);
    return(cc);  
}  

void hitung()
{
    OP = 0;
    Buy = 0; lotbuy = 0; lotsbuy = 0; Sell = 0; lotsell = 0; lotssell = 0; SUM = 0; SWAP = 0; profitbuy = 0; profitsell = 0;
    sumbuy = 0; sumsell = 0; bepbuy = 0; bepsell = 0; lowlotbuy = 9999; lowlotsell = 9999; hisell = 0; lobuy = 999999999;

    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol())
            continue;
        if (OrderMagicNumber() != Magic)
            continue;

        if (OrderType() == OP_BUY)
        {
            Buy++; OP++; lotbuy = OrderLots();
            profitbuy += OrderProfit(); lotsbuy += OrderLots(); lowlotbuy = MathMin(lowlotbuy, OrderLots());
            sumbuy    += OrderLots() * OrderOpenPrice(); lobuy = MathMin(lobuy, OrderOpenPrice());
        }
        if (OrderType() == OP_SELL)
        {
            Sell++; OP++; lotsell = OrderLots();
            profitsell += OrderProfit(); lotssell += OrderLots(); lowlotsell = MathMin(lowlotsell, OrderLots());
            sumsell    += OrderLots() * OrderOpenPrice(); hisell = MathMax(hisell, OrderOpenPrice());
        }
    }

    if (lotsbuy > 0)
        bepbuy = sumbuy / lotsbuy;
    if (lotssell > 0)
        bepsell = sumsell / lotssell;
        
    // Bersihkan Hedge jika basket utama sudah close (TP / BEP / Cut)
    if (Buy == 0) CUT_HEDGE(OP_SELL);
    if (Sell == 0) CUT_HEDGE(OP_BUY);
}

double NR(double thelot)
{
    double maxlots = MarketInfo(Symbol(), MODE_MAXLOT),
           minilot = MarketInfo(Symbol(), MODE_MINLOT),
           lstep   = MarketInfo(Symbol(), MODE_LOTSTEP);
    double lots    = lstep * NormalizeDouble(thelot / lstep, 0);
    lots = MathMax(MathMin(maxlots, lots), minilot);
    return(lots);
}

double ND(double p)
{
    return(NormalizeDouble(p, Digits));
}

double GetCurrentSpreadPips()
{
    if (pt <= 0.0) return(999999.0);
    RefreshRates();
    return((Ask - Bid) / pt);
}

double GetAllowedSpreadPips()
{
    double allowed = MathMax(0.0, Base_Max_Spread_Pips);
    if (Spread_ATR_Allowance_Fraction > 0.0 && pt > 0.0)
    {
        double atrH1 = iATR(NULL, PERIOD_H1, MathMax(1, Trend_ATR_Period), 1);
        if (atrH1 > 0.0)
            allowed += (atrH1 / pt) * Spread_ATR_Allowance_Fraction;
    }
    if (Absolute_Max_Spread_Pips > 0.0)
        allowed = MathMin(allowed, Absolute_Max_Spread_Pips);
    return(allowed);
}

bool IsSpreadAllowedForEntry()
{
    if (!Use_Dynamic_Spread_Filter) return(true);
    double current = GetCurrentSpreadPips();
    double allowed = GetAllowedSpreadPips();
    bool ok = (current <= allowed);
    return(ok);
}

bool CloseOrderTicketWithRetry(int orderTicket, color closeColor, double closeLots = 0.0)
{
    int attempts = MathMax(1, Trade_Close_Retry_Attempts);
    int delayMs = MathMax(0, Trade_Close_Retry_Delay_MS);

    for (int attempt = 0; attempt < attempts; attempt++)
    {
        if (!OrderSelect(orderTicket, SELECT_BY_TICKET, MODE_TRADES))
            return(false);

        int type = OrderType();
        if (type != OP_BUY && type != OP_SELL)
            return(false);

        string sym = OrderSymbol();
        double lots = OrderLots();
        if (closeLots > 0.0 && closeLots < lots)
            lots = closeLots; // partial close; MT4 membuat tiket baru untuk sisa lot
        RefreshRates();
        double price = (type == OP_BUY) ? MarketInfo(sym, MODE_BID) : MarketInfo(sym, MODE_ASK);

        ResetLastError();
        if (OrderClose(orderTicket, lots, price, Slippage, closeColor))
            return(true);

        int err = GetLastError();
        Print("CLOSE RETRY | ticket=", orderTicket,
              " attempt=", attempt+1, "/", attempts,
              " err=", err, " ", TradeErrorDescription(err));

        if (delayMs > 0) Sleep(delayMs);
    }
    return(false);
}

bool DeleteOrderTicketWithRetry(int orderTicket)
{
    int attempts = MathMax(1, Trade_Close_Retry_Attempts);
    int delayMs = MathMax(0, Trade_Close_Retry_Delay_MS);
    for (int attempt = 0; attempt < attempts; attempt++)
    {
        if (!OrderSelect(orderTicket, SELECT_BY_TICKET, MODE_TRADES))
            return(false);
        ResetLastError();
        if (OrderDelete(orderTicket))
            return(true);
        int err = GetLastError();
        if (delayMs > 0) Sleep(delayMs);
    }
    return(false);
}

string TradeErrorDescription(int err)
{
    switch(err)
    {
        case 0:   return("no error");
        case 1:   return("no error returned, result unknown");
        case 2:   return("common error");
        case 3:   return("invalid trade parameters");
        case 4:   return("trade server busy");
        case 5:   return("old terminal version");
        case 6:   return("no connection with trade server");
        case 8:   return("too frequent requests");
        case 64:  return("account disabled");
        case 65:  return("invalid account");
        case 128: return("trade timeout");
        case 129: return("invalid price");
        case 130: return("invalid stops");
        case 131: return("invalid trade volume");
        case 132: return("market closed");
        case 133: return("trade disabled");
        case 134: return("not enough money");
        case 135: return("price changed");
        case 136: return("off quotes");
        case 137: return("broker busy");
        case 138: return("requote");
        case 139: return("order locked");
        case 140: return("long positions only allowed");
        case 141: return("too many requests");
        case 145: return("modification denied: order too close to market");
        case 146: return("trade context busy");
        case 147: return("expiration denied by broker");
        case 148: return("too many open/pending orders");
        case 149: return("hedging prohibited");
        case 150: return("FIFO rule prohibited");
    }
    return("error code " + IntegerToString(err));
}

int OPE(int type, double L, string orderComment, int orderMagic = -1, bool applySpreadFilter = true)
{
    if (L <= 0.0)
        return(-1);
    L = NR(L);
    if (orderMagic < 0)
        orderMagic = Magic;

    if (applySpreadFilter && !IsSpreadAllowedForEntry())
        return(-1);
    if (!CanOpenNewOrder(type, L))
        return(-1);

    int localTicket = -1;
    double price = 0;
    color clr = (type == OP_BUY) ? Blue : Red;
    string open = (type == OP_BUY) ? "BUY" : "SELL";

    for (int attempt = 0; attempt < 3; attempt++)
    {
        while (IsTradeContextBusy())
            Sleep(200);

        RefreshRates();
        price = (type == OP_BUY) ? Ask : Bid;
        localTicket = OrderSend(Symbol(), type, L, price, Slippage, 0, 0, orderComment, orderMagic, 0, clr);
        if (localTicket > 0)
            break;

        int error = GetLastError();
        Print("OPEN ", open, " gagal. attempt=", attempt + 1, " lot=", DoubleToStr(L, 2), " price=", DoubleToStr(price, Digits), " err=", error, " ", TradeErrorDescription(error));
        Sleep(500);
    }

    ticket = localTicket;
    return(localTicket);
}

// Hedge Guard: posisi berlawanan saat averaging mencapai Hedge_Activation_Layer.
// Tidak diblokir filter spread (proteksi), tetapi tetap melewati cek margin dan retry.
void OpenHedgeOrder(int hedgeType, double basketLayerLot)
{
    double hedgeLot = NR(basketLayerLot * Hedge_Lot_Ratio);
    string hedgeComment = (hedgeType == OP_BUY) ? "Hedge Guard (SELL)" : "Hedge Guard (BUY)";
    if (OPE(hedgeType, hedgeLot, hedgeComment, GetHedgeMagic(), false) <= 0)
        Print("HEDGE GUARD gagal dibuka | type=", (hedgeType == OP_BUY ? "BUY" : "SELL"),
              " lot=", DoubleToStr(hedgeLot, 2));
}

void tpsl()
{
    double bePrice = 0.0;

    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic)
            continue;

        int tk = OrderTicket();

        if (OrderType() == OP_BUY)
        {
            double oSLB = OrderStopLoss();
            double oTPB = 0.0;

            if (Buy <= 1)
            {
                oTPB = ND(OrderOpenPrice() + TP * pt) * (TP > 0);
                if (SL > 0)
                    oSLB = OrderOpenPrice() - SL * pt;

                // Smart Breakeven Lock for L1:
                if (Use_Breakeven_Lock && Breakeven_Trigger_Pips > 0.0)
                {
                    if (Bid >= OrderOpenPrice() + Breakeven_Trigger_Pips * pt)
                    {
                        bePrice = OrderOpenPrice() + Breakeven_Buffer_Pips * pt;
                        if (oSLB < bePrice)
                            oSLB = bePrice;
                    }
                }

                oTPB = ND(oTPB);
                oSLB = ND(oSLB);

                if (oTPB > 0.0 && Bid >= oTPB)
                {
                    CloseOrderTicketWithRetry(tk, CLR_NONE);
                    continue;
                }
                if (oSLB > 0.0 && Bid <= oSLB)
                {
                    CloseOrderTicketWithRetry(tk, CLR_NONE);
                    continue;
                }
            }
            else
            {
                if (Use_Net_Basket_Profit_Close)
                    oTPB = 0.0;
                else
                {
                    double activeTPBuy = (Buy >= 4) ? TP_Averaging_L4Plus : TP_Averaging;
                    double basketBEBuy = GetCostAdjustedBasketBE(OP_BUY, bepbuy, lotsbuy);
                    oTPB = ND((basketBEBuy + activeTPBuy * pt) * (activeTPBuy > 0));
                }

                if (Basket_Stop_Below_BEP_Pips > 0)
                    oSLB = ND(bepbuy - Basket_Stop_Below_BEP_Pips * pt);
            }

            SafeModifyStops(tk, oSLB, oTPB);
        }

        if (OrderType() == OP_SELL)
        {
            double oSLS = OrderStopLoss();
            double oTPS = 0.0;

            if (Sell <= 1)
            {
                oTPS = ND(OrderOpenPrice() - TP * pt) * (TP > 0);
                if (SL > 0)
                    oSLS = OrderOpenPrice() + SL * pt;

                // Smart Breakeven Lock for L1:
                if (Use_Breakeven_Lock && Breakeven_Trigger_Pips > 0.0)
                {
                    if (Ask <= OrderOpenPrice() - Breakeven_Trigger_Pips * pt)
                    {
                        bePrice = OrderOpenPrice() - Breakeven_Buffer_Pips * pt;
                        if (oSLS == 0.0 || oSLS > bePrice)
                            oSLS = bePrice;
                    }
                }

                oTPS = ND(oTPS);
                oSLS = ND(oSLS);

                if (oTPS > 0.0 && Ask <= oTPS)
                {
                    CloseOrderTicketWithRetry(tk, CLR_NONE);
                    continue;
                }
                if (oSLS > 0.0 && Ask >= oSLS)
                {
                    CloseOrderTicketWithRetry(tk, CLR_NONE);
                    continue;
                }
            }
            else
            {
                if (Use_Net_Basket_Profit_Close)
                    oTPS = 0.0;
                else
                {
                    double activeTPSell = (Sell >= 4) ? TP_Averaging_L4Plus : TP_Averaging;
                    double basketBESell = GetCostAdjustedBasketBE(OP_SELL, bepsell, lotssell);
                    oTPS = ND((basketBESell - activeTPSell * pt) * (activeTPSell > 0));
                }

                if (Basket_Stop_Below_BEP_Pips > 0)
                    oSLS = ND(bepsell + Basket_Stop_Below_BEP_Pips * pt);
            }

            SafeModifyStops(tk, oSLS, oTPS);
        }
    }
}

void stop()
{
    int Fontsize = 14; color col = Yellow;
    ObjectCreate("STOP", OBJ_LABEL, 0, 0, 0);
    ObjectSet("STOP", OBJPROP_CORNER, 1);
    ObjectSet("STOP", OBJPROP_BACK, 0);
    ObjectSet("STOP", OBJPROP_XDISTANCE, 200);
    ObjectSet("STOP", OBJPROP_YDISTANCE, 5);
    ObjectSetText("STOP", "EA STOPPED.. DELETE THIS TEXT TO CONTINUE", Fontsize, "Arial Bold", col);
}

void text(int zz, string text)
{
    int Fontsize = 9; color col = Yellow;
    ObjectCreate("zzz" + zz, OBJ_LABEL, 0, 0, 0);
    ObjectSet("zzz" + zz, OBJPROP_CORNER, 0);
    ObjectSet("zzz" + zz, OBJPROP_BACK, 0);
    ObjectSet("zzz" + zz, OBJPROP_XDISTANCE, 5);
    ObjectSet("zzz" + zz, OBJPROP_YDISTANCE, 5 + 1.7 * Fontsize * (0 + zz) + (2 * Fontsize));
    ObjectSetText("zzz" + zz, text, Fontsize, "Comic Sans MS", col);
}

void clear()
{
    for (int x = ObjectsTotal() - 1; x >= 0; x--)
    {
        string n = ObjectName(x);
        if (StringFind(n, "zzz", 0) > -1)
            ObjectDelete(n);
    }
}

// Profit minimum (dalam satuan harga) yang harus terkunci oleh trailing L1:
// komisi pulang-pergi per lot dikonversi ke jarak harga, ditambah buffer Min_L1_Lock_Pips.
double GetMinL1LockPrice()
{
    double lockPrice = MathMax(0.0, Min_L1_Lock_Pips) * pt;
    if (Commission_Per_Lot_RoundTurn > 0.0)
    {
        double moneyPerPrice = GetMoneyPerPricePerLot();
        if (moneyPerPrice > 0.0)
            lockPrice += Commission_Per_Lot_RoundTurn / moneyPerPrice;
    }
    return(lockPrice);
}

void trail()
{
    int cnt = OrdersTotal();
    
    // NEW: Kalkulasi Adaptive Trailing berdasarkan volatilitas ritme M15 (ATR)
    double active_trail = TrailingStop;
    double active_step = Step;
    
    if (Use_Adaptive_Trailing)
    {
        double atr = iATR(Symbol(), Adaptive_Trail_TF, Adaptive_Trail_Period, 1);
        if (atr > 0)
        {
            double atr_points = atr / pt; 
            active_trail = atr_points * Adaptive_Trail_ATR_Mult;
            active_step = atr_points * Adaptive_Step_ATR_Mult;
            
            // Batas kewarasan (Sanity Limits) agar trail tidak terlalu sempit saat market flat
            if (active_trail < 400) active_trail = 400; // SAFETY: Batas bawah dinaikkan ke 400 agar tidak memotong profit terlalu dini 
            if (active_step < 150) active_step = 150; // SAFETY: Batas bawah step 150
        }
    }

    double minLockPrice = GetMinL1LockPrice();

    for (int xxx = 0; xxx < cnt; xxx++)
    {
        if (!OrderSelect(xxx, SELECT_BY_POS, MODE_TRADES))
            continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic)
            continue;

        int tk = OrderTicket();

        if (OrderType() == OP_BUY)
        {
            if (Buy >= 2)
                continue;

            double local_trail = active_trail;
            double local_step = active_step;
            
            if (Use_Stoch_Trailing_L1 && OrderProfit() > 0) {
                double stK = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
                double stK_prev = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 1);
                
                // Jika masih di pucuk OB, trail super ketat (15 pips belakang harga)
                if (stK > Stoch_Trail_OB) {
                    local_trail = 150;
                    local_step = 50;
                }
                // Jika mulai memutar ke bawah OB, kunci BEP sangat rapat (2 pips) agar langsung close!
                else if (stK_prev > Stoch_Trail_OB && stK <= Stoch_Trail_OB) {
                    local_trail = 20;
                    local_step = 10;
                }
            }

            double OSLB  = NormalizeDouble(OrderStopLoss(), Digits);
            double oopB  = bepbuy;
            double BID   = NormalizeDouble(Bid, Digits);
            double opitB = NormalizeDouble((BID - oopB) / pt, 0);
            double TSLB  = NormalizeDouble(BID - local_trail * pt, Digits);

            // v78: jangan kunci profit di bawah biaya komisi + buffer.
            if (minLockPrice > 0.0)
            {
                double floorB = NormalizeDouble(OrderOpenPrice() + minLockPrice, Digits);
                if (TSLB < floorB)
                    TSLB = floorB;
            }

            if (opitB > local_trail && (OSLB <= TSLB - local_step * pt || OSLB == 0))
                SafeModifyStops(tk, TSLB, OrderTakeProfit());
        }

        if (OrderType() == OP_SELL)
        {
            if (Sell >= 2)
                continue;

            double local_trail_sell = active_trail;
            double local_step_sell = active_step;
            
            if (Use_Stoch_Trailing_L1 && OrderProfit() > 0) {
                double stKSell = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
                double stK_prevSell = iStochastic(NULL, Stoch_Trail_TF, Stoch_Trail_K, Stoch_Trail_D, Stoch_Trail_Slowing, MODE_SMA, 0, MODE_MAIN, 1);
                
                // Jika masih di dasar OS, trail super ketat (15 pips belakang harga)
                if (stKSell < Stoch_Trail_OS) {
                    local_trail_sell = 150;
                    local_step_sell = 50;
                }
                // Jika mulai memutar ke atas OS, kunci BEP sangat rapat (2 pips) agar langsung close!
                else if (stK_prevSell < Stoch_Trail_OS && stKSell >= Stoch_Trail_OS) {
                    local_trail_sell = 20;
                    local_step_sell = 10;
                }
            }

            double OSLS = NormalizeDouble(OrderStopLoss(), Digits);
            double oopS = bepsell;
            double ASK  = NormalizeDouble(Ask, Digits);
            double opitS = NormalizeDouble((oopS - ASK) / pt, 0);
            double TSLS  = NormalizeDouble(ASK + local_trail_sell * pt, Digits);

            // v78: jangan kunci profit di bawah biaya komisi + buffer.
            if (minLockPrice > 0.0)
            {
                double floorS = NormalizeDouble(OrderOpenPrice() - minLockPrice, Digits);
                if (TSLS > floorS)
                    TSLS = floorS;
            }

            if (opitS > local_trail_sell && (OSLS >= TSLS + local_step_sell * pt || OSLS == 0))
                SafeModifyStops(tk, TSLS, OrderTakeProfit());
        }
    }
}

void f0_4(string as_0, string as_8, int ai_16, int ai_20, int ai_24, color ai_28, int ai_32, string as_36)
{
    if (ObjectFind(as_0) < 0)
        ObjectCreate(as_0, OBJ_LABEL, 0, 0, 0);
    ObjectSetText(as_0, as_36, ai_16, as_8, ai_28);
    ObjectSet(as_0, OBJPROP_CORNER, ai_32);
    ObjectSet(as_0, OBJPROP_XDISTANCE, ai_20);
    ObjectSet(as_0, OBJPROP_YDISTANCE, ai_24);
}

void f0_30()
{
    for (int idx = OrdersTotal() - 1; idx >= 0; idx--)
    {
        if (!OrderSelect(idx, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
        if (OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
        int tk = OrderTicket();
        CloseOrderTicketWithRetry(tk, (OrderType() == OP_BUY ? Blue : Red));
    }
}

void CloseAllinProfit()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
        bool isSingleOrderSide = ((OrderType() == OP_BUY && Buy <= 1) ||
                                  (OrderType() == OP_SELL && Sell <= 1));
        if(isSingleOrderSide && (OrderType() == OP_BUY || OrderType() == OP_SELL) &&
           (OrderProfit() + OrderSwap() + OrderCommission() >= Target_Dollar))
        {
            int tk = OrderTicket();
            CloseOrderTicketWithRetry(tk, Red);
        }
    }
}

double dailyprofit()
{
    datetime dayStart = StringToTime(TimeToStr(TimeCurrent(), TIME_DATE));
    double res = 0;
    for(int i = 0; i < OrdersHistoryTotal(); i++)
    {
        if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
        if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=Magic) continue;
        if(OrderCloseTime() >= dayStart) res += (OrderProfit() + OrderSwap() + OrderCommission());
    }
    return(res);
}

void Display_Info()
{
    hitung();

    double spreadPips = GetCurrentSpreadPips();
    double allowedSpread = GetAllowedSpreadPips();
    string spreadText = DoubleToStr(spreadPips, 1) + " pips";
    if (Use_Dynamic_Spread_Filter)
        spreadText += " / max " + DoubleToStr(allowedSpread, 1);

    LABEL("L01", "Arial", 12, 30,30, White,0,"BioOnePro Institutional Edition v5.25 (v80)" );
    LABEL("L02", "Arial", 12, 30,50, White,0,"A/C no :  " + AccountNumber() );
    LABEL("L03", "Arial", 12,30,70,White,0,"Balance :   " + DoubleToStr(AccountBalance(), 2) );
    LABEL("L04", "Arial", 12,30,90,White,0,"Equity :  " + DoubleToStr(AccountEquity(), 2) );
    LABEL("L05", "Arial", 12,30,110,White,0,"Profit/Lost :  " + DoubleToStr(AccountEquity() - AccountBalance(), 2)+"USD");
    LABEL("L06", "Arial", 12,30,130,White,0,"Spread :  " + spreadText);
    LABEL("L07", "Arial", 12,30,150,White,0,"EA Orders :  " + IntegerToString((int)(Buy + Sell)));

    double breakerPips = GetBreakerDistancePips(LOTnya());
    string riskText = (breakerPips > 0.0)
                    ? DoubleToStr(breakerPips * pt, 2) + " melawan L1 (" + DoubleToStr(Percent_Loss, 0) + "%)"
                    : "n/a";
    LABEL("L08", "Arial", 12,30,170,White,0,"Cut-loss grid :  " + riskText);
}

void LABEL(string a_name_0, string a_fontname_8, int a_fontsize_16, int a_x_20, int a_y_24, color a_color_28, int a_corner_32, string a_text_36)
{
    if (ObjectFind(a_name_0) < 0)
        ObjectCreate(a_name_0, OBJ_LABEL, 0, 0, 0);
    ObjectSetText(a_name_0, a_text_36, a_fontsize_16, a_fontname_8, a_color_28);
    ObjectSet(a_name_0, OBJPROP_CORNER, a_corner_32);
    ObjectSet(a_name_0, OBJPROP_XDISTANCE, a_x_20);
    ObjectSet(a_name_0, OBJPROP_YDISTANCE, a_y_24);
}

// NEW: Blokir L1 di hari Jumat siang agar terhindar dari Cut Loss akhir pekan
bool IsFridayAfternoon()
{
    if (Close_Baskets_Before_Weekend && DayOfWeek() == 5 && Hour() >= 12)
        return true;
    return false;
}

bool JAM_OP()
{
    if (!Time_Filter)
        return(true);

    if (Jam_Mulai == Jam_Akhir)
        return(true);

    int currentHour = TimeHour(TimeCurrent());
    if (Jam_Mulai < Jam_Akhir)
        return(currentHour >= Jam_Mulai && currentHour < Jam_Akhir);

    return(currentHour >= Jam_Mulai || currentHour < Jam_Akhir);
}

void closeallpair()
{
    int tickets[256];
    int types[256];
    int count = 0;

    for (int i = OrdersTotal() - 1; i >= 0 && count < 256; i--)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderSymbol() != Symbol() || !IsEAMagic(OrderMagicNumber())) continue;
        tickets[count] = OrderTicket();
        types[count] = OrderType();
        count++;
    }

    for (int k = 0; k < count; k++)
    {
        bool ok = false;
        if (types[k] == OP_BUY || types[k] == OP_SELL)
            ok = CloseOrderTicketWithRetry(tickets[k], Violet);
        else if (types[k] == OP_BUYSTOP || types[k] == OP_SELLSTOP ||
                 types[k] == OP_BUYLIMIT || types[k] == OP_SELLLIMIT)
            ok = DeleteOrderTicketWithRetry(tickets[k]);
        else
            ok = true;

        if (!ok)
            Print("CLOSE ALL lanjut ke tiket berikutnya setelah gagal | ticket=", tickets[k]);
    }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (ObjectGetInteger(0, "CLOSE ALL", OBJPROP_STATE) != 0)
    {
        ObjectSetInteger(0, "CLOSE ALL", OBJPROP_STATE, 0);
        closeallpair();
    }
}
