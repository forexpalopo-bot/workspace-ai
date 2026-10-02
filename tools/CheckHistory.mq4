//+------------------------------------------------------------------+
//| CheckHistory.mq4 - cek kelengkapan history semua timeframe       |
//| Jalankan di chart simbol yang akan di-backtest. Hasil di tab     |
//| Experts dan file <folder data>\MQL4\Files\history_check_<sym>.txt|
//+------------------------------------------------------------------+
#property strict

void OnStart()
{
    int tfs[7] = {1, 5, 15, 30, 60, 240, 1440};
    string name = "history_check_" + Symbol() + ".txt";
    int h = FileOpen(name, FILE_WRITE | FILE_TXT | FILE_ANSI);
    string head = "Simbol=" + Symbol() + " Digits=" + IntegerToString(Digits) + " Server=" + AccountServer();
    Print(head);
    if (h != INVALID_HANDLE) FileWrite(h, head);
    for (int k = 0; k < 7; k++)
    {
        int tf = tfs[k];
        int bars = iBars(NULL, tf);
        if (bars <= 0)
        {
            string e = "TF " + IntegerToString(tf) + ": TIDAK ADA DATA";
            Print(e);
            if (h != INVALID_HANDLE) FileWrite(h, e);
            continue;
        }
        datetime first = iTime(NULL, tf, bars - 1);
        datetime last = iTime(NULL, tf, 0);
        // celah > 4 hari (lebih panjang dari akhir pekan biasa) = data bolong
        int gaps = 0;
        string gapList = "";
        for (int i = bars - 1; i > 0; i--)
        {
            int d = (int)(iTime(NULL, tf, i - 1) - iTime(NULL, tf, i));
            if (d > 4 * 86400)
            {
                gaps++;
                if (gaps <= 10)
                    gapList = gapList + " " + TimeToString(iTime(NULL, tf, i), TIME_DATE) + "->" + TimeToString(iTime(NULL, tf, i - 1), TIME_DATE);
            }
        }
        string line = "TF " + IntegerToString(tf) + ": bars=" + IntegerToString(bars) + " dari " + TimeToString(first) +
                      " s/d " + TimeToString(last) + " | celah>4hari=" + IntegerToString(gaps) + gapList;
        Print(line);
        if (h != INVALID_HANDLE) FileWrite(h, line);
    }
    if (h != INVALID_HANDLE) FileClose(h);
}
