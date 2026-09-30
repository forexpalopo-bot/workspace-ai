# Analisis Claude Code atas putaran 10

(Ditulis terpisah dari NOTES.md karena terminal sesi Claude sedang gangguan; akan digabung ke NOTES.md nanti.)

## Validasi di tahun yang belum pernah dipakai menyetel
| Run | 2023 (P4) | 2022 (P5) |
|---|---|---|
| Y1 | −$38 (DD 25.3%) | −$1,007 (DD 39.6%, PF 0.70) |
| Z1 | +$120 (DD 25.2%) | −$963 (DD 37.7%, PF 0.72) |

- 2023 hampir impas; **2022 rugi ~32% dari $3000**, walaupun akun tidak habis.
- Rugi per basket tetap terkendali (worst basket −$289, ≈ 10% modal, sesuai anggaran risiko). Masalah 2022 adalah
  **frekuensi**: 46–51 basket rugi (vs 35 di 2024) dan 24–26 basket sampai L4+. Artinya, tahun 2022 (emas naik-turun
  lebar karena kenaikan suku bunga Fed) memicu banyak SL berturut-turut, bukan satu kerugian raksasa.

## Tuning Z1 (P3 / P2 / P1D, deposit $3000)
| Run | Total | DD maks | Catatan |
|---|---|---|---|
| **A5 risiko 8%** | **+$1,867** (−$7 / +$1,062 / +$812) | **16.1%** | Lebih baik dari Z1 (+$1,405, DD 18%) di SEMUA periode |
| A6 risiko 12% | +$2,247 (−$52 / +$1,485 / +$814) | 23.4% | Profit lebih besar, DD dan worst basket (−$488) lebih besar |
| A1 / A2 (batas ATR 1.5 / 3.0) | ≈ Z1 | 18% | Batas atas rasio ATR hampir tidak pernah tercapai |
| A3 (hanya melebar) | +$1,061 | 18% | Profit P1D turun separuh: grid perlu MENYEMPIT saat pasar tenang |
| A4 (Z1 + trend stop) | +$1,182 | 22.2% | Trend stop memperburuk 2024 lagi. Ditolak |

- **A5 menjadi kandidat utama.** Risiko per basket yang lebih kecil (8%) justru menaikkan profit, karena kerugian di
  SL lebih kecil sementara jumlah kemenangan L1 hampir sama (lot L1 hanya turun sedikit, dibatasi lot minimum).
- Putaran 11: (1) validasi A5 di 2022/2023, (2) risiko 6% (B1), (3) A5 + belajar 60 hari (B2) untuk statistik swing
  yang lebih stabil di tahun bergejolak seperti 2022. Semua di 5 periode, supaya setting akhir dipilih dari 5 tahun data.

## Rencana setelah putaran 11
Kalau 2022 tetap rugi > 20%, tambahkan **circuit breaker berbasis equity** (jeda trading beberapa hari setelah
N SL berturut-turut atau rugi bulanan > X%). Tujuannya membatasi kerugian di tahun yang tidak cocok untuk grid,
tanpa mengubah perilaku di tahun normal.
