//+------------------------------------------------------------------+
//| ExportBars.mq4 - ekspor bar OHLC simbol chart ke CSV             |
//| Pasang di <folder data>\MQL4\Scripts, kompilasi, lalu jalankan   |
//| di chart XAUUSD. File tersimpan di <folder data>\MQL4\Files\.    |
//+------------------------------------------------------------------+
#property strict
#property show_inputs

input int      InpTF   = 60;                 // Timeframe (menit): 60 = H1, 15 = M15
input datetime InpFrom = D'2022.01.01';
input datetime InpTo   = D'2026.09.30 23:59';

void OnStart()
{
    string name = Symbol() + "_" + IntegerToString(InpTF) + ".csv";
    int h = FileOpen(name, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
    if (h == INVALID_HANDLE)
    {
        Print("ExportBars: gagal membuka file ", name, " err=", GetLastError());
        return;
    }
    FileWrite(h, "time", "open", "high", "low", "close", "tick_volume");
    int bars = iBars(NULL, InpTF);
    int n = 0;
    for (int i = bars - 1; i >= 0; i--)
    {
        datetime t = iTime(NULL, InpTF, i);
        if (t < InpFrom || t > InpTo)
            continue;
        FileWrite(h, TimeToString(t, TIME_DATE | TIME_MINUTES),
                  DoubleToString(iOpen(NULL, InpTF, i), Digits), DoubleToString(iHigh(NULL, InpTF, i), Digits),
                  DoubleToString(iLow(NULL, InpTF, i), Digits), DoubleToString(iClose(NULL, InpTF, i), Digits),
                  IntegerToString(iVolume(NULL, InpTF, i)));
        n++;
    }
    FileClose(h);
    Print("ExportBars: ", name, " bars=", n, " (", TimeToString(iTime(NULL, InpTF, bars - 1)), " .. ", TimeToString(iTime(NULL, InpTF, 0)), ")");
}
