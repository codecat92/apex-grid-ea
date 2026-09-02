//+------------------------------------------------------------------+
//|                                               ApexGrid.mq4       |
//|                                   Apex Grid EA - Grid+Martingale |
//|                          Inspired by Yetti Classic v3.03_fix     |
//+------------------------------------------------------------------+
#property copyright "codecat92"
#property link      ""
#property version   "1.15"
#property strict

//+------------------------------------------------------------------+
//| CORE TRADING PARAMETERS (shared)                                 |
//+------------------------------------------------------------------+
extern string Group01 = "===== 1. PENGATURAN UTAMA (SHARED) =====";
extern int    MagicNumber       = 1888;   // ID unik bot
extern bool   UseTrailingStop   = true;   // Aktifkan trailing stop (global)

//+------------------------------------------------------------------+
//| BUY GRID PARAMETERS (per side)                                   |
//+------------------------------------------------------------------+
extern string Group02 = "===== 2. PARAMETER GRID BUY =====";
extern bool   EnableBuyGrid     = true;   // Aktifkan basket BUY
extern double StartLotBuy       = 0.13;   // Lot pertama grid BUY (Yetti-aligned)
extern double MultiplierBuy     = 1.5;    // Pengali lot per level BUY
extern int    GridStepBuy       = 250;    // Jarak antar level BUY (points; 250 = 25 pips 5-digit)
extern int    GeneralTPBuy      = 200;    // TP keseluruhan BUY (pips; Yetti-aligned)
extern int    OrdersPerStepBuy  = 2;      // Jumlah order per level BUY
extern int    MaxGridLevelBuy   = 20;     // Batas maksimum level grid BUY
extern int    StopLossPipsBuy   = 375;    // Jarak Stop Loss per level BUY (pips)
extern bool   UseStopLossBuy    = true;   // Pasang SL per order BUY (false = SL 0 ala Yetti)
extern int    FixedDistanceBuy  = 10;     // Jarak trailing BUY (pips)
extern int    TriggerDistanceBuy= 15;     // Jarak minimal trailing BUY (pips)
extern double MinGapPipsBuy     = 3.0;    // Gap MA minimal untuk BUY (pips)
extern int    EntryCooldownSecBuy = 30;   // Jeda antar entry BUY (detik)
extern int    MaxBasketsPerSideBuy = 1;   // Maksimum basket BUY (1 = Yetti single-basket)

//+------------------------------------------------------------------+
//| SELL GRID PARAMETERS (per side)                                  |
//+------------------------------------------------------------------+
extern string Group03 = "===== 3. PARAMETER GRID SELL =====";
extern bool   EnableSellGrid    = true;   // Aktifkan basket SELL
extern double StartLotSell      = 0.13;   // Lot pertama grid SELL (Yetti-aligned)
extern double MultiplierSell    = 1.5;    // Pengali lot per level SELL
extern int    GridStepSell      = 250;    // Jarak antar level SELL (points; 250 = 25 pips 5-digit)
extern int    GeneralTPSell     = 200;    // TP keseluruhan SELL (pips; Yetti-aligned)
extern int    OrdersPerStepSell = 2;      // Jumlah order per level SELL
extern int    MaxGridLevelSell  = 20;     // Batas maksimum level grid SELL
extern int    StopLossPipsSell  = 375;    // Jarak Stop Loss per level SELL (pips)
extern bool   UseStopLossSell   = true;   // Pasang SL per order SELL (false = SL 0 ala Yetti)
extern int    FixedDistanceSell = 10;     // Jarak trailing SELL (pips)
extern int    TriggerDistanceSell = 15;   // Jarak minimal trailing SELL (pips)
extern double MinGapPipsSell    = 3.0;    // Gap MA minimal untuk SELL (pips)
extern int    EntryCooldownSecSell = 30;  // Jeda antar entry SELL (detik)
extern int    MaxBasketsPerSideSell = 1;  // Maksimum basket SELL (1 = Yetti single-basket)

//+------------------------------------------------------------------+
//| MA ENTRY SIGNAL PARAMETERS (shared — single crossover)           |
//+------------------------------------------------------------------+
extern string Group04 = "===== 4. SINYAL ENTRY (MA CROSSOVER) =====";
extern int    MAFastPeriod      = 5;      // Periode MA cepat
extern int    MASlowPeriod      = 20;     // Periode MA lambat
extern int    MAMethod          = 0;      // 0=SMA,1=EMA,2=SMMA,3=LWMA
extern int    MAPrice           = 0;      // 0=Close,1=Open,2=High,3=Low,4=Median,5=Typical,6=Weighted
extern int    BBPeriod          = 20;     // Periode Bollinger Bands (unused)
extern double BBDeviation       = 2.0;    // Deviasi Bollinger Bands (unused)

//+------------------------------------------------------------------+
//| TIME FILTER PARAMETERS                                           |
//+------------------------------------------------------------------+
extern string Group05 = "===== 5. FILTER WAKTU (JAM TRADING) =====";
extern string StartTime         = "00:00";// Jam mulai trading
extern string EndTime           = "23:59";// Jam berhenti trading
extern bool   FridayTrade       = true;   // Trading hari Jumat
extern string FridayStop        = "14:00";// Jam stop Jumat
extern bool   UseExtraTime      = true;   // Window tambahan
extern string ExtraStart        = "01:06";// Mulai extra window
extern string ExtraEnd          = "01:07";// Akhir extra window
extern int    AdditionalGridStep = 100;   // Grid step extra window (points)

//+------------------------------------------------------------------+
//| RISK MANAGEMENT PARAMETERS                                       |
//+------------------------------------------------------------------+
extern string Group06 = "===== 6. MANAJEMEN RISIKO =====";
extern double DailyProfitPct    = 20.0;   // Stop jika profit harian tercapai
extern double WeeklyProfitPct   = 20.0;   // Stop jika profit mingguan tercapai
extern double DrawdownCloseAll  = 90.0;   // Tutup semua jika drawdown > X%
extern double MarginCloseAll    = 20.0;   // Tutup semua jika margin < X%
extern bool   AutoStopTrading   = true;   // Aktifkan auto stop
extern double MaxDrawdown       = 15.0;   // Batas drawdown sebelum berhenti
extern double MinMarginLevel    = 1000.0; // Batas minimum margin level

//+------------------------------------------------------------------+
//| NEWS FILTER PARAMETERS                                           |
//+------------------------------------------------------------------+
extern string Group07 = "===== 7. FILTER NEWS =====";
extern bool   NewsFilter         = false;   // Aktifkan news filter
extern int    NewsMinutesBefore  = 30;      // Menit sebelum news (no entry)
extern int    NewsMinutesAfter   = 60;      // Menit setelah news (no entry)
extern int    NewsRefreshMin     = 15;      // Interval refresh data news via web (menit)
extern string NewsCurrencies     = "GBP,USD"; // Filter mata uang
extern int    NewsTimezoneOffset = 0;       // Offset jam UTC ke broker time (contoh: 2, -5)

//+------------------------------------------------------------------+
//| STOP REASON CONSTANTS                                            |
//+------------------------------------------------------------------+
#define STOP_NONE      0
#define STOP_DRAWDOWN  1
#define STOP_PROFIT    2
#define STOP_MARGIN    3

//+------------------------------------------------------------------+
//| GLOBAL CONSTANTS                                                 |
//+------------------------------------------------------------------+
string   G_Name            = "Apex Grid";
int      G_Magic           = 1888;
int      G_StartMin        = 0;
int      G_EndMin          = 0;
int      G_FridayStopMin   = 0;
int      G_ExtraStartMin   = 0;
int      G_ExtraEndMin     = 0;

//+------------------------------------------------------------------+
//| GRID STATE — Multi-basket per side, indexed 0..MaxBasketsPerSide |
//+------------------------------------------------------------------+
int      G_BuyActive[];       // 1 jika basket ini punya order aktif
int      G_SellActive[];
int      G_BuyLevel[];        // level grid saat ini (-1 = belum mulai)
int      G_SellLevel[];
double   G_BuyFirstPrice[];
double   G_SellFirstPrice[];
double   G_BuyPeak[];
double   G_SellTrough[];
int      G_BuyTrailing[];
int      G_SellTrailing[];
double   G_BuyPeakProfit[];
double   G_SellPeakProfit[];
datetime G_BuyLastClosed[];
datetime G_SellLastClosed[];

// Entry throttle
datetime G_LastBuyEntry  = 0;
datetime G_LastSellEntry = 0;

//+------------------------------------------------------------------+
//| RISK STATE                                                       |
//+------------------------------------------------------------------+
bool     G_Stopped         = false;
int      G_StopReason      = 0;
datetime G_DayStart        = 0;
datetime G_WeekStart       = 0;
double   G_DayEquity       = 0;
double   G_WeekEquity      = 0;

//+------------------------------------------------------------------+
//| NEWS FILTER STATE                                                |
//+------------------------------------------------------------------+
datetime G_NewsLastFetch   = 0;
int      G_NewsEventCount  = 0;
datetime G_NewsBlackouts[][2];  // [n][0]=start, [n][1]=end in broker time
bool     G_NewsDataValid   = false;

//+------------------------------------------------------------------+
//| Helper: Get true pip value                                       |
//+------------------------------------------------------------------+
double PipSize() {
   if (Digits == 5 || Digits == 3) return Point * 10;
   return Point;
}

//+------------------------------------------------------------------+
//| Helper: Human-readable text for a stop reason code                |
//+------------------------------------------------------------------+
string StopReasonText(int reason) {
   if (reason == STOP_DRAWDOWN) return "drawdown limit";
   if (reason == STOP_PROFIT)   return "profit target";
   if (reason == STOP_MARGIN)   return "margin level";
   return "unknown";
}

//+------------------------------------------------------------------+
//| Set stopped state and log it ONLY on a state transition          |
//| (prevents flooding the log with the same message every tick)      |
//+------------------------------------------------------------------+
void StopTrading(int reason, string sentence) {
   bool transition = (!G_Stopped || G_StopReason != reason);
   G_Stopped = true;
   G_StopReason = reason;
   if (transition) Print(G_Name + " STOPPED: " + sentence);
}

//+------------------------------------------------------------------+
//| Helper: Normalize lot to broker rules                             |
//| ROUNDING (bukan floor) agar deret martingale selaras dengan Yetti  |
//| Contoh 0.13*1.5=0.195 → 0.20, bukan 0.19                          |
//+------------------------------------------------------------------+
double NormalizeLot(double lot) {
   double min  = MarketInfo(Symbol(), MODE_MINLOT);
   double max  = MarketInfo(Symbol(), MODE_MAXLOT);
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   int digits = (step >= 0.1) ? 1 : 2;
   lot = MathRound(lot / step) * step;
   if (lot < min) lot = min;
   if (lot > max) lot = max;
   return NormalizeDouble(lot, digits);
}

//+------------------------------------------------------------------+
//| Calculate lot for a grid level: StartLot*Side * Multiplier*Side^level |
//+------------------------------------------------------------------+
double LotByLevel(string side, int level) {
   double start = (side == "BUY") ? StartLotBuy : StartLotSell;
   double mult  = (side == "BUY") ? MultiplierBuy : MultiplierSell;
   return NormalizeLot(start * MathPow(mult, level));
}

//+------------------------------------------------------------------+
//| Build order comment for a side + level                           |
//+------------------------------------------------------------------+
string MakeComment(string side, int level) {
   if (level == 0) return G_Name + " " + side;
   return G_Name + " " + side + " " + IntegerToString(level);
}

//+------------------------------------------------------------------+
//| Magic number for a basket: MagicNumber*100 + offset              |
//| BUY offset  = basketId (0..MaxBasketsPerSideBuy-1)               |
//| SELL offset = MaxBasketsPerSideBuy + basketId                    |
//+------------------------------------------------------------------+
int BasketMagic(string side, int basketId) {
   int offset = basketId;
   if (side == "SELL") offset = MaxBasketsPerSideBuy + basketId;
   return MagicNumber * 100 + offset;
}

//+------------------------------------------------------------------+
//| Helper: Convert "HH:MM" string to integer minutes                |
//+------------------------------------------------------------------+
int StrToMinutes(string t) {
   return StrToInteger(StringSubstr(t, 0, 2)) * 60 + StrToInteger(StringSubstr(t, 3, 2));
}

//+------------------------------------------------------------------+
//| Get current grid step (uses AdditionalGridStep during extra time)|
//| Returned in POINTS (Yetti-aligned): 250 = 25 pips on 5-digit      |
//+------------------------------------------------------------------+
int CurrentGridStep(string side) {
   if (UseExtraTime) {
      int now = Hour() * 60 + Minute();
      if (now >= G_ExtraStartMin && now <= G_ExtraEndMin) return AdditionalGridStep;
   }
   return (side == "BUY") ? GridStepBuy : GridStepSell;
}

//+------------------------------------------------------------------+
//| TIME FILTER (Layer 4)                                            |
//+------------------------------------------------------------------+
bool IsTradingAllowed() {
   if (G_Stopped) return false;

   if (NewsFilter && IsNewsBlackout()) {
      static datetime newsLog = 0;
      if (TimeCurrent() - newsLog > 300) {
         Print(G_Name + " Trading blocked: news filter is active near a scheduled news release.");
         newsLog = TimeCurrent();
      }
      return false;
   }
   int dow = DayOfWeek();
   if (dow == 0 || dow == 6) {
      static datetime wkndLog = 0;
      if (TimeCurrent() - wkndLog > 300) {
         Print(G_Name + " Trading blocked: the market is closed (weekend).");
         wkndLog = TimeCurrent();
      }
      return false;
   }
   int now = Hour() * 60 + Minute();
   if (now < G_StartMin || now > G_EndMin) {
      static datetime hrsLog = 0;
      if (TimeCurrent() - hrsLog > 300) {
         Print(G_Name + " Trading blocked: current time is outside the active window " + StartTime + "-" + EndTime + ".");
         hrsLog = TimeCurrent();
      }
      return false;
   }
   if (dow == 5) {
      if (!FridayTrade) {
         static datetime friLog = 0;
         if (TimeCurrent() - friLog > 300) {
            Print(G_Name + " Trading blocked: Friday trading is disabled.");
            friLog = TimeCurrent();
         }
         return false;
      }
      if (now >= G_FridayStopMin) {
         static datetime friStopLog = 0;
         if (TimeCurrent() - friStopLog > 300) {
            Print(G_Name + " Trading blocked: Friday trading already ended at " + FridayStop + ".");
            friStopLog = TimeCurrent();
         }
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Find the lowest open price among BUY orders (deepest level)      |
//+------------------------------------------------------------------+
double LowestBuyPrice(int basketId) {
   double low = DBL_MAX;
   string prefix = G_Name + " BUY";
   int targetMagic = BasketMagic("BUY", basketId);
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != targetMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      if (OrderOpenPrice() < low) low = OrderOpenPrice();
   }
   return (low == DBL_MAX) ? 0 : low;
}

//+------------------------------------------------------------------+
//| Find the highest open price among SELL orders (deepest level)    |
//+------------------------------------------------------------------+
double HighestSellPrice(int basketId) {
   double high = 0;
   string prefix = G_Name + " SELL";
   int targetMagic = BasketMagic("SELL", basketId);
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != targetMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      if (OrderOpenPrice() > high) high = OrderOpenPrice();
   }
   return high;
}

//+------------------------------------------------------------------+
//| Get total profit + swap + commission for one side                |
//+------------------------------------------------------------------+
double SideProfit(string side, int basketId) {
   double p = 0;
   string prefix = G_Name + " " + side;
   int targetMagic = BasketMagic(side, basketId);
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != targetMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      p += OrderProfit() + OrderSwap() + OrderCommission();
   }
     return p;
}

//+------------------------------------------------------------------+
//| Calculate lot-weighted average entry price for a side            |
//+------------------------------------------------------------------+
double BasketAvgPrice(string side, int basketId) {
   double totalLots = 0, weightedPrice = 0;
   string prefix = G_Name + " " + side;
   int targetMagic = BasketMagic(side, basketId);
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != targetMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      weightedPrice += OrderOpenPrice() * OrderLots();
      totalLots     += OrderLots();
   }
   return (totalLots > 0) ? (weightedPrice / totalLots) : 0;
}

//+------------------------------------------------------------------+
//| Get total lots for one side                                      |
//+------------------------------------------------------------------+
double TotalSideLots(string side, int basketId) {
   double lots = 0;
   string prefix = G_Name + " " + side;
   int targetMagic = BasketMagic(side, basketId);
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != targetMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      lots += OrderLots();
   }
   return lots;
}

//+------------------------------------------------------------------+
//| GRID MANAGER (Layer 2)                                           |
//| Level 0 = market order (instant entry)                           |
//| Level > 0 = pending stop order at exact grid level               |
//+------------------------------------------------------------------+
void OpenGridLevel(string side, int basketId) {
   int level;
   int cmd, slip = 3;
   bool isPending;
   int targetMagic = BasketMagic(side, basketId);

   if (side == "BUY") {
      G_BuyActive[basketId] = true;
      G_BuyLevel[basketId]++;
      level = G_BuyLevel[basketId];
      isPending = (level > 0);
      cmd = isPending ? OP_BUYSTOP : OP_BUY;
   } else {
      G_SellActive[basketId] = true;
      G_SellLevel[basketId]++;
      level = G_SellLevel[basketId];
      isPending = (level > 0);
      cmd = isPending ? OP_SELLSTOP : OP_SELL;
   }

   double lot = LotByLevel(side, level);
   string cmt = MakeComment(side, level);
   int ordersPerStep = (side == "BUY") ? OrdersPerStepBuy : OrdersPerStepSell;
   int stopLossPips  = (side == "BUY") ? StopLossPipsBuy : StopLossPipsSell;
   bool useStopLoss  = (side == "BUY") ? UseStopLossBuy : UseStopLossSell;

   if (level == 0) {
      RefreshRates();
      if (side == "BUY") {
         G_BuyFirstPrice[basketId] = Ask;
         G_BuyPeak[basketId]       = Ask;
         G_BuyPeakProfit[basketId] = 0;
      } else {
         G_SellFirstPrice[basketId] = Bid;
         G_SellTrough[basketId]     = Bid;
         G_SellPeakProfit[basketId] = 0;
      }
   }

   // Calculate entry price for pending orders (levels > 0)
   // GridStep in POINTS (e.g. 250 points = 0.0025 on 5-digit) — Yetti-aligned
   double pendingPrice = 0;
   if (isPending) {
      double stepPrice = CurrentGridStep(side) * Point;
      if (side == "BUY") {
         double lowest = LowestBuyPrice(basketId);
         if (lowest == 0) lowest = G_BuyFirstPrice[basketId];
         pendingPrice = lowest - stepPrice;
      } else {
         double highest = HighestSellPrice(basketId);
         if (highest == 0) highest = G_SellFirstPrice[basketId];
         pendingPrice = highest + stepPrice;
      }
      // Ensure pending price is valid vs current market
      RefreshRates();
      double stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
      if (side == "BUY" && pendingPrice >= Ask - stoplevel) pendingPrice = Ask - stoplevel;
      if (side == "SELL" && pendingPrice <= Bid + stoplevel) pendingPrice = Bid + stoplevel;
   }

   Print(G_Name + " Grid ", side, " basket=", basketId, " level ", level, " lot=", lot, " pending=", isPending);

   bool anySucceeded = false;
   for (int j = 0; j < ordersPerStep; j++) {
      RefreshRates();
      double price = isPending ? pendingPrice : ((side == "BUY") ? Ask : Bid);
      double sl = 0;
      if (useStopLoss) {
         if (side == "BUY")
            sl = price - (stopLossPips * PipSize());
         else
            sl = price + (stopLossPips * PipSize());
      }
      int ticket = OrderSend(Symbol(), cmd, lot, price, slip, sl, 0, cmt, targetMagic, 0, CLR_NONE);
      if (ticket >= 0) {
         anySucceeded = true;
         Print(G_Name + " Order opened ticket=", ticket);
      } else {
         int err = GetLastError();
         if (isPending && (err == 130)) {
            RefreshRates();
            double mktPrice = (cmd == OP_BUYSTOP) ? Ask : Bid;
            double sl2 = 0;
            if (useStopLoss) {
               if (side == "BUY")
                  sl2 = mktPrice - (stopLossPips * PipSize());
               else
                  sl2 = mktPrice + (stopLossPips * PipSize());
            }
            ticket = OrderSend(Symbol(), (cmd == OP_BUYSTOP) ? OP_BUY : OP_SELL,
                               lot, mktPrice, slip, sl2, 0, cmt, targetMagic, 0, CLR_NONE);
            if (ticket >= 0) anySucceeded = true;
            else Print(G_Name + " Market fallback error ", GetLastError(), " side=", side, " level=", level);
         } else {
            Print(G_Name + " OrderSend error ", err, " side=", side, " level=", level);
         }
      }
   }

   if (!anySucceeded) {
      if (side == "BUY") {
         G_BuyLevel[basketId]--;
         if (G_BuyLevel[basketId] < 0) {
            G_BuyActive[basketId] = false; G_BuyLevel[basketId] = -1;
            G_BuyFirstPrice[basketId] = 0; G_BuyPeak[basketId] = 0;
            G_BuyPeakProfit[basketId] = 0; G_BuyTrailing[basketId] = false;
         }
      } else {
         G_SellLevel[basketId]--;
         if (G_SellLevel[basketId] < 0) {
            G_SellActive[basketId] = false; G_SellLevel[basketId] = -1;
            G_SellFirstPrice[basketId] = 0; G_SellTrough[basketId] = 0;
            G_SellPeakProfit[basketId] = 0; G_SellTrailing[basketId] = false;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| BASKET CLOSE (Layer 3)                                           |
//| Close ALL orders of a side, then reset grid state                |
//+------------------------------------------------------------------+
void BasketClose(string side, int basketId) {
   int tickets[500];
   ArrayInitialize(tickets, 0);
   int n = 0;
   string prefix = G_Name + " " + side;
   int targetMagic = BasketMagic(side, basketId);

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != targetMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      tickets[n] = OrderTicket();
      n++;
   }

   if (n == 0) {
      Print(G_Name + " BasketClose: no orders to close for ", side, " #", basketId);
      return;
   }

   int failed = 0;
   for (int i = 0; i < n; i++) {
      if (!OrderSelect(tickets[i], SELECT_BY_TICKET, MODE_TRADES)) {
         Print(G_Name + " BasketClose: order ", tickets[i], " no longer exists");
         continue;
      }
      RefreshRates();
      bool ok = false;
      if (OrderType() == OP_BUY)
         ok = OrderClose(tickets[i], OrderLots(), Bid, 3, CLR_NONE);
      else if (OrderType() == OP_SELL)
         ok = OrderClose(tickets[i], OrderLots(), Ask, 3, CLR_NONE);
      if (!ok) {
         failed++;
         Print(G_Name + " BasketClose error ", GetLastError(), " ticket=", tickets[i]);
      }
   }

   if (failed > 0) {
      Print(G_Name + " BasketClose: ", failed, " orders failed to close for ", side, " #", basketId);
      return;
   }

   Print(G_Name + " TRAL:::: close on the trawl ", side, " #", basketId);

   if (side == "BUY") {
      G_BuyActive[basketId]     = false;
      G_BuyLevel[basketId]      = -1;
      G_BuyFirstPrice[basketId] = 0;
      G_BuyPeak[basketId]       = 0;
      G_BuyPeakProfit[basketId] = 0;
      G_BuyTrailing[basketId]   = false;
      G_BuyLastClosed[basketId] = TimeCurrent();
   } else {
      G_SellActive[basketId]     = false;
      G_SellLevel[basketId]      = -1;
      G_SellFirstPrice[basketId] = 0;
      G_SellTrough[basketId]     = 0;
      G_SellPeakProfit[basketId] = 0;
      G_SellTrailing[basketId]   = false;
      G_SellLastClosed[basketId] = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| TRAILING STOP (Layer 3)                                          |
//| Trailing on basket profit peak — "close on the trawl"            |
//| Triggered after TriggerDistance pips from first entry.           |
//| Closes when basket profit drops FixedDistance pips of value.     |
//+------------------------------------------------------------------+
void CheckTrailing() {
   if (!UseTrailingStop) return;

   double pip    = PipSize();
   double pipVal = pip * MarketInfo(Symbol(), MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE);

   // --- BUY trailing (per basket) ---
   for (int id = 0; id < MaxBasketsPerSideBuy; id++) {
      if (!G_BuyActive[id]) continue;
      double dist   = (Bid - G_BuyFirstPrice[id]) / pip;
      double profit = SideProfit("BUY", id);
      if (dist >= TriggerDistanceBuy) {
         G_BuyTrailing[id] = true;
      }
      if (G_BuyTrailing[id]) {
         if (profit > G_BuyPeakProfit[id]) G_BuyPeakProfit[id] = profit;
         double drop      = G_BuyPeakProfit[id] - profit;
         double threshold = FixedDistanceBuy * pipVal * TotalSideLots("BUY", id);
         if (drop >= threshold && drop > 0) {
            Print(G_Name + " TRAL:::: close on the trawl BUY #", id);
            BasketClose("BUY", id);
         }
      }
   }

   // --- SELL trailing (per basket) ---
   for (int id = 0; id < MaxBasketsPerSideSell; id++) {
      if (!G_SellActive[id]) continue;
      double dist   = (G_SellFirstPrice[id] - Ask) / pip;
      double profit = SideProfit("SELL", id);
      if (dist >= TriggerDistanceSell) {
         G_SellTrailing[id] = true;
      }
      if (G_SellTrailing[id]) {
         if (profit > G_SellPeakProfit[id]) G_SellPeakProfit[id] = profit;
         double drop      = G_SellPeakProfit[id] - profit;
         double threshold = FixedDistanceSell * pipVal * TotalSideLots("SELL", id);
         if (drop >= threshold && drop > 0) {
            Print(G_Name + " TRAL:::: close on the trawl SELL #", id);
            BasketClose("SELL", id);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if a new grid level needs to be opened                     |
//| Harga bergerak GridStep berlawanan arah dari level sebelumnya   |
//+------------------------------------------------------------------+
void CheckGridLevels() {
   if (!IsTradingAllowed() || G_Stopped) return;

   // GridStep in POINTS — dist dihitung dalam point (Yetti-aligned)
   double point = Point;
   double dist;

   // BUY: price drops GridStep from deepest entry (per basket)
   if (EnableBuyGrid) {
      int stepBuy = CurrentGridStep("BUY");
      for (int id = 0; id < MaxBasketsPerSideBuy; id++) {
         if (!G_BuyActive[id]) continue;
         double lowest = LowestBuyPrice(id);
         if (lowest == 0) lowest = G_BuyFirstPrice[id];
         dist = (lowest - Bid) / point;
         if (dist >= stepBuy && G_BuyLevel[id] < MaxGridLevelBuy) OpenGridLevel("BUY", id);
      }
   }

   // SELL: price rises GridStep from deepest entry (per basket)
   if (EnableSellGrid) {
      int stepSell = CurrentGridStep("SELL");
      for (int id = 0; id < MaxBasketsPerSideSell; id++) {
         if (!G_SellActive[id]) continue;
         double highest = HighestSellPrice(id);
         if (highest == 0) highest = G_SellFirstPrice[id];
         dist = (Ask - highest) / point;
         if (dist >= stepSell && G_SellLevel[id] < MaxGridLevelSell) OpenGridLevel("SELL", id);
      }
   }
}

//+------------------------------------------------------------------+
//| MANAGE PENDING ORDERS                                            |
//| Gap-fill: if price passed a pending stop order without filling,  |
//| delete it and place a market order instead.                      |
//+------------------------------------------------------------------+
void ManagePendingOrders() {
   double pip = PipSize();
   int baseMagic = MagicNumber * 100;
   int maxMagic  = baseMagic + MaxBasketsPerSideBuy + MaxBasketsPerSideSell;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      int om = OrderMagicNumber();
      if (om < baseMagic || om >= maxMagic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() != OP_BUYSTOP && OrderType() != OP_SELLSTOP) continue;

      RefreshRates();
      if (OrderType() == OP_BUYSTOP && Ask <= OrderOpenPrice() - 5 * pip) {
         double lots = OrderLots();
         string cmt  = OrderComment();
         int delTicket = OrderTicket();
         if (OrderDelete(delTicket)) {
            int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, 0, 0, cmt, om, 0, CLR_NONE);
            if (ticket >= 0) Print(G_Name + " Gap-filled BUY ticket=", ticket);
            else Print(G_Name + " Gap-fill BUY error ", GetLastError());
         } else {
            Print(G_Name + " Gap-fill: failed to delete BUYSTOP ticket=", delTicket, " err=", GetLastError());
         }
      }
      if (OrderType() == OP_SELLSTOP && Bid >= OrderOpenPrice() + 5 * pip) {
         double lots = OrderLots();
         string cmt  = OrderComment();
         int delTicket = OrderTicket();
         if (OrderDelete(delTicket)) {
            int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, 0, 0, cmt, om, 0, CLR_NONE);
            if (ticket >= 0) Print(G_Name + " Gap-filled SELL ticket=", ticket);
            else Print(G_Name + " Gap-fill SELL error ", GetLastError());
         } else {
            Print(G_Name + " Gap-fill: failed to delete SELLSTOP ticket=", delTicket, " err=", GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| MA ENTRY SIGNAL (Layer 1) — Per tick, gap threshold (v1.09)      |
//| Bullish bias if fast-slow gap >= MinGapPips → open BUY basket    |
//| Bearish bias if fast-slow gap <= -MinGapPips → open SELL basket  |
//| Multi-basket: max MaxBasketsPerSide baskets per side              |
//| EntryCooldownSec prevents spam per tick                           |
//+------------------------------------------------------------------+
void CheckMA() {
   if (!IsTradingAllowed() || G_Stopped) return;

   double fast = iMA(Symbol(), 0, MAFastPeriod, 0, MAMethod, MAPrice, 0);
   double slow = iMA(Symbol(), 0, MASlowPeriod, 0, MAMethod, MAPrice, 0);
   if (fast <= 0 || slow <= 0) return;

   double pip = PipSize();
   double gapPips = (fast - slow) / pip;

   bool bullishBias = (gapPips >= MinGapPipsBuy);
   bool bearishBias = (gapPips <= -MinGapPipsSell);
   bool buyCoolOk  = (TimeCurrent() - G_LastBuyEntry  >= EntryCooldownSecBuy);
   bool sellCoolOk = (TimeCurrent() - G_LastSellEntry >= EntryCooldownSecSell);

   static datetime lastLog = 0;
   if (TimeCurrent() - lastLog >= 5) {
      int buyCnt = 0, sellCnt = 0;
      for (int i = 0; i < MaxBasketsPerSideBuy; i++)  if (G_BuyActive[i])  buyCnt++;
      for (int i = 0; i < MaxBasketsPerSideSell; i++) if (G_SellActive[i]) sellCnt++;
      Print(G_Name + " Tick gap=", DoubleToString(gapPips, 1),
            " bull=", bullishBias, " bear=", bearishBias,
            " buyBask=", buyCnt, " sellBask=", sellCnt);
      lastLog = TimeCurrent();
   }

   // Find free BUY basket slot
   if (EnableBuyGrid) {
      int buySlot = -1;
      for (int i = 0; i < MaxBasketsPerSideBuy; i++) {
         if (!G_BuyActive[i]) { buySlot = i; break; }
      }
      if (bullishBias && buyCoolOk && buySlot >= 0) {
         Print(G_Name + " Signal: bullish gap=", DoubleToString(gapPips, 1), " -> BUY #", buySlot);
         OpenGridLevel("BUY", buySlot);
         G_LastBuyEntry = TimeCurrent();
      }
   }

   // Find free SELL basket slot
   if (EnableSellGrid) {
      int sellSlot = -1;
      for (int i = 0; i < MaxBasketsPerSideSell; i++) {
         if (!G_SellActive[i]) { sellSlot = i; break; }
      }
      if (bearishBias && sellCoolOk && sellSlot >= 0) {
         Print(G_Name + " Signal: bearish gap=", DoubleToString(gapPips, 1), " -> SELL #", sellSlot);
         OpenGridLevel("SELL", sellSlot);
         G_LastSellEntry = TimeCurrent();
      }
   }
}

//+------------------------------------------------------------------+
//| GENERAL TP CHECK                                                 |
//| Basket close when basket-weighted average price reaches TP       |
//+------------------------------------------------------------------+
void CheckGeneralTP() {
   if (GeneralTPBuy <= 0 && GeneralTPSell <= 0) return;
   double pip = PipSize();

   for (int id = 0; id < MaxBasketsPerSideBuy; id++) {
      if (G_BuyActive[id]) {
         double avg = BasketAvgPrice("BUY", id);
         if (avg > 0 && (Bid - avg) / pip >= GeneralTPBuy) {
            Print(G_Name + " GeneralTP hit BUY #", id);
            BasketClose("BUY", id);
         }
      }
   }
   for (int id = 0; id < MaxBasketsPerSideSell; id++) {
      if (G_SellActive[id]) {
         double avg = BasketAvgPrice("SELL", id);
         if (avg > 0 && (avg - Ask) / pip >= GeneralTPSell) {
            Print(G_Name + " GeneralTP hit SELL #", id);
            BasketClose("SELL", id);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| RISK SHUTDOWN (Layer 5)                                          |
//| ORDER MATTERS: critical close-all checks must run BEFORE the      |
//| soft MaxDrawdown stop, otherwise a 90% drawdown would be masked   |
//| by the >=15% soft-stop returning first.                           |
//+------------------------------------------------------------------+
void CheckRisk() {
   double eq    = AccountEquity();
   double bal   = AccountBalance();
   double ddPct = (bal > 0) ? (bal - eq) / bal * 100 : 0;
   double mrgLv = (AccountMargin() > 0) ? (eq / AccountMargin()) * 100 : DBL_MAX;

    // Close all jika drawdown kritis
    if (ddPct >= DrawdownCloseAll) {
       for (int i = 0; i < MaxBasketsPerSideBuy; i++)  if (G_BuyActive[i])  BasketClose("BUY", i);
       for (int i = 0; i < MaxBasketsPerSideSell; i++) if (G_SellActive[i]) BasketClose("SELL", i);
       StopTrading(STOP_DRAWDOWN,
          "Critical drawdown of " + DoubleToString(ddPct, 2) + "% exceeded the safety limit of " +
          DoubleToString(DrawdownCloseAll, 2) + "%. All open positions were closed and trading stopped.");
       return;
    }

    // Close all jika margin level kritis
    if (mrgLv < MarginCloseAll) {
       for (int i = 0; i < MaxBasketsPerSideBuy; i++)  if (G_BuyActive[i])  BasketClose("BUY", i);
       for (int i = 0; i < MaxBasketsPerSideSell; i++) if (G_SellActive[i]) BasketClose("SELL", i);
       StopTrading(STOP_MARGIN,
          "Margin level dropped to " + DoubleToString(mrgLv, 2) + "%, below the critical limit of " +
          DoubleToString(MarginCloseAll, 2) + "%. All open positions were closed and trading stopped.");
       return;
    }

   // Auto stop jika drawdown melebihi batas (soft stop — positions stay managed)
   if (AutoStopTrading && ddPct >= MaxDrawdown) {
      StopTrading(STOP_DRAWDOWN,
         "Account drawdown reached " + DoubleToString(ddPct, 2) + "%, which is higher than the allowed MaxDrawdown of " +
         DoubleToString(MaxDrawdown, 2) + "%. Trading has been stopped, existing positions are still managed.");
      return;
   }

   // Stop trading jika margin level di bawah minimum
   if (mrgLv < MinMarginLevel) {
      StopTrading(STOP_MARGIN,
         "Margin level is only " + DoubleToString(mrgLv, 2) + "%, below the minimum required of " +
         DoubleToString(MinMarginLevel, 2) + "%. Trading has been stopped.");
      return;
   }

   // Daily profit target
   double dayProfit = eq - G_DayEquity;
   double dayPct    = (G_DayEquity > 0) ? (dayProfit / G_DayEquity) * 100 : 0;
   if (dayPct >= DailyProfitPct) {
      StopTrading(STOP_PROFIT,
         "Daily profit target of " + DoubleToString(DailyProfitPct, 2) + "% was reached (current " +
         DoubleToString(dayPct, 2) + "%). Trading has been stopped until the next trading day.");
      return;
   }

   // Weekly profit target
   double weekProfit = eq - G_WeekEquity;
   double weekPct    = (G_WeekEquity > 0) ? (weekProfit / G_WeekEquity) * 100 : 0;
   if (weekPct >= WeeklyProfitPct) {
      StopTrading(STOP_PROFIT,
         "Weekly profit target of " + DoubleToString(WeeklyProfitPct, 2) + "% was reached (current " +
         DoubleToString(weekPct, 2) + "%). Trading has been stopped until next week.");
   }
}

//+------------------------------------------------------------------+
//| NEWS PARSER — Parse ISO 8601 date to UTC datetime                |
//| Format: 2026-06-23T03:15:00-04:00 → returns UTC datetime         |
//+------------------------------------------------------------------+
datetime ParseISODate(string iso) {
   if (StringLen(iso) < 19) return 0;

   int y  = (int)StringToInteger(StringSubstr(iso, 0, 4));
   int mo = (int)StringToInteger(StringSubstr(iso, 5, 2));
   int d  = (int)StringToInteger(StringSubstr(iso, 8, 2));
   int h  = (int)StringToInteger(StringSubstr(iso, 11, 2));
   int mi = (int)StringToInteger(StringSubstr(iso, 14, 2));
   int s  = (int)StringToInteger(StringSubstr(iso, 17, 2));

   string dtStr = StringFormat("%04d.%02d.%02d %02d:%02d:%02d", y, mo, d, h, mi, s);
   datetime localDt = StrToTime(dtStr);
   if (localDt <= 0) return 0;

   // Parse timezone offset: -04:00 or +05:00
   string tzSign = StringSubstr(iso, 19, 1);
   if (tzSign != "+" && tzSign != "-") return localDt;

   int tzHours = (int)StringToInteger(StringSubstr(iso, 20, 2));
   int tzSec = tzHours * 3600;
   if (tzSign == "-") tzSec = -tzSec;

   // UTC = local time minus the timezone offset
   // E.g. 03:15-04:00 → UTC = 03:15 - (-14400) = 03:15 + 4h = 07:15
   return localDt - tzSec;
}

//+------------------------------------------------------------------+
//| Map country code from JSON to ISO currency code                  |
//+------------------------------------------------------------------+
string CountryToCurrency(string country) {
   if (country == "US" || country == "USD") return "USD";
   if (country == "EU" || country == "EUR") return "EUR";
   if (country == "GB" || country == "GBP") return "GBP";
   if (country == "CH" || country == "CHF") return "CHF";
   if (country == "CA" || country == "CAD") return "CAD";
   if (country == "AU" || country == "AUD") return "AUD";
   if (country == "NZ" || country == "NZD") return "NZD";
   if (country == "JP" || country == "JPY") return "JPY";
   if (country == "CN" || country == "CNY") return "CNY";
   return country;
}

//+------------------------------------------------------------------+
//| NEWS FETCHER — Fetch calendar JSON via WebRequest                |
//| Source: nfs.faireconomy.media (Fair Economy, Inc. JSON endpoint) |
//+------------------------------------------------------------------+
bool FetchNewsViaWeb() {
   if (!NewsFilter) {
      G_NewsDataValid = false;
      return false;
   }

   // Throttle: only refresh every NewsRefreshMin minutes
   if (G_NewsLastFetch > 0 && TimeCurrent() - G_NewsLastFetch < NewsRefreshMin * 60) {
      return G_NewsDataValid;
   }

   string url = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";
   char data[], result[];
   string headers;

   G_NewsLastFetch = TimeCurrent();

   int status = WebRequest("GET", url, NULL, NULL, 5000, data, 0, result, headers);

   if (status != 200) {
      G_NewsDataValid = false;
      G_NewsEventCount = 0;
      if (status == -1)
         Print(G_Name + " News: WebRequest failed — check Tools→Options→Expert Advisors→Allow WebRequest for ", url);
      else
         Print(G_Name + " News: HTTP ", status);
      return false;
   }

   string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   if (StringLen(json) < 100) {
      G_NewsDataValid = false;
      G_NewsEventCount = 0;
      return false;
   }

   // Parse JSON events — search for "date":"..." and "country":"..." pairs
   int offsetSec = NewsTimezoneOffset * 3600;
   datetime now = TimeCurrent();
   int count = 0;
   int searchPos = 0;

   // Reserve max 100 slots
   ArrayResize(G_NewsBlackouts, 100);

   while (count < 100) {
      // Find next date key
      int dateKey = StringFind(json, "\"date\":", searchPos);
      if (dateKey < 0) break;

      // Extract date value between quotes
      int dateStart = StringFind(json, "\"", dateKey + 7) + 1;
      if (dateStart <= 0) break;
      int dateEnd = StringFind(json, "\"", dateStart);
      if (dateEnd < 0) break;
      string dateStr = StringSubstr(json, dateStart, dateEnd - dateStart);

      // Find next country key (within 200 chars of date end)
      int countryKey = StringFind(json, "\"country\":", dateEnd);
      if (countryKey < 0 || countryKey > dateEnd + 200) {
         searchPos = dateEnd;
         continue;
      }
      int countryStart = StringFind(json, "\"", countryKey + 11) + 1;
      if (countryStart <= 0) { searchPos = dateEnd; continue; }
      int countryEnd = StringFind(json, "\"", countryStart);
      if (countryEnd < 0) { searchPos = dateEnd; continue; }
      string countryStr = StringSubstr(json, countryStart, countryEnd - countryStart);

      // Currency filter
      string currency = CountryToCurrency(countryStr);
      if (StringLen(NewsCurrencies) > 0 && StringFind(NewsCurrencies, currency) < 0) {
         searchPos = countryEnd;
         continue;
      }

      // Parse ISO 8601 → UTC
      datetime eventUtc = ParseISODate(dateStr);
      if (eventUtc <= 0) {
         searchPos = countryEnd;
         continue;
      }

      // Skip past events (>1h old) and events beyond 2 days
      if (eventUtc < now - 3600 || eventUtc > now + 172800) {
         searchPos = countryEnd;
         continue;
      }

      // Convert UTC to broker time
      datetime brokerEvent = eventUtc + offsetSec;

      G_NewsBlackouts[count][0] = brokerEvent - (NewsMinutesBefore * 60);
      G_NewsBlackouts[count][1] = brokerEvent + (NewsMinutesAfter  * 60);
      count++;

      searchPos = countryEnd;
   }

   ArrayResize(G_NewsBlackouts, count);
   G_NewsEventCount = count;
   G_NewsDataValid  = (count > 0);

   if (count > 0)
      Print(G_Name + " News: loaded ", count, " events via WebRequest");
   else
      Print(G_Name + " News: 0 events in range (or API returned empty)");

   return G_NewsDataValid;
}

//+------------------------------------------------------------------+
//| NEWS BLACKOUT CHECK                                              |
//| Returns true if current broker time falls in any blackout window |
//+------------------------------------------------------------------+
bool IsNewsBlackout() {
   if (!NewsFilter || !G_NewsDataValid) return false;

   for (int i = 0; i < G_NewsEventCount; i++) {
      if (G_NewsBlackouts[i][0] <= 0 || G_NewsBlackouts[i][1] <= 0) continue;
      if (TimeCurrent() >= G_NewsBlackouts[i][0] && TimeCurrent() <= G_NewsBlackouts[i][1]) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Reset daily/weekly equity tracking                               |
//+------------------------------------------------------------------+
void CheckReset() {
   datetime today  = iTime(Symbol(), PERIOD_D1, 0);
   datetime thisWk = iTime(Symbol(), PERIOD_W1, 0);

   if (today != G_DayStart) {
      int prevDayReason = G_StopReason;
      G_DayStart = today;
      G_DayEquity = AccountEquity();
      if (G_Stopped) {
         G_Stopped = false;
         G_StopReason = STOP_NONE;
         Print(G_Name + " Trading resumed (new trading day). Previous stop reason: " + StopReasonText(prevDayReason));
      }
   }

   if (thisWk != G_WeekStart) {
      G_WeekStart = thisWk;
      G_WeekEquity = AccountEquity();
      if (G_StopReason == STOP_PROFIT) {
         G_Stopped = false;
         G_StopReason = STOP_NONE;
         Print(G_Name + " Trading resumed (new trading week). Weekly profit target reached was reset.");
      }
   }
}

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION                                            |
//+------------------------------------------------------------------+
int OnInit() {
   G_Magic = MagicNumber;

   G_StartMin      = StrToMinutes(StartTime);
   G_EndMin        = StrToMinutes(EndTime);
   G_FridayStopMin = StrToMinutes(FridayStop);
   G_ExtraStartMin = StrToMinutes(ExtraStart);
   G_ExtraEndMin   = StrToMinutes(ExtraEnd);

   G_DayStart  = iTime(Symbol(), PERIOD_D1, 0);
   G_WeekStart = iTime(Symbol(), PERIOD_W1, 0);
   G_DayEquity  = AccountEquity();
   G_WeekEquity = AccountEquity();

   // Init multi-basket arrays
   ArrayResize(G_BuyActive, MaxBasketsPerSideBuy);
   ArrayResize(G_SellActive, MaxBasketsPerSideSell);
   ArrayResize(G_BuyLevel, MaxBasketsPerSideBuy);
   ArrayResize(G_SellLevel, MaxBasketsPerSideSell);
   ArrayResize(G_BuyFirstPrice, MaxBasketsPerSideBuy);
   ArrayResize(G_SellFirstPrice, MaxBasketsPerSideSell);
   ArrayResize(G_BuyPeak, MaxBasketsPerSideBuy);
   ArrayResize(G_SellTrough, MaxBasketsPerSideSell);
   ArrayResize(G_BuyTrailing, MaxBasketsPerSideBuy);
   ArrayResize(G_SellTrailing, MaxBasketsPerSideSell);
   ArrayResize(G_BuyPeakProfit, MaxBasketsPerSideBuy);
   ArrayResize(G_SellPeakProfit, MaxBasketsPerSideSell);
   ArrayResize(G_BuyLastClosed, MaxBasketsPerSideBuy);
   ArrayResize(G_SellLastClosed, MaxBasketsPerSideSell);

   for (int i = 0; i < MaxBasketsPerSideBuy; i++) {
      G_BuyActive[i] = false;  G_BuyLevel[i] = -1;  G_BuyFirstPrice[i] = 0;
      G_BuyPeak[i] = 0;        G_BuyPeakProfit[i] = 0;  G_BuyTrailing[i] = false;
      G_BuyLastClosed[i] = 0;
   }

   for (int i = 0; i < MaxBasketsPerSideSell; i++) {
      G_SellActive[i] = false; G_SellLevel[i] = -1;  G_SellFirstPrice[i] = 0;
      G_SellTrough[i] = 0;     G_SellPeakProfit[i] = 0; G_SellTrailing[i] = false;
      G_SellLastClosed[i] = 0;
   }

   Print(G_Name + " EA initialized v1.15 multi-basket. Magic: " + IntegerToString(G_Magic));
   Print(G_Name + " Config: BUY StartLot=" + DoubleToString(StartLotBuy, 2) + " GridStep=" + GridStepBuy +
         " MaxLvl=" + MaxGridLevelBuy + " GenTP=" + GeneralTPBuy + " | SELL StartLot=" + DoubleToString(StartLotSell, 2) +
         " GridStep=" + GridStepSell + " MaxLvl=" + MaxGridLevelSell + " GenTP=" + GeneralTPSell +
         " | Risk: MaxDD=" + DoubleToString(MaxDrawdown, 2) + "% MinMargin=" + DoubleToString(MinMarginLevel, 2) + "%");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print(G_Name + " EA deinitialized.");
}

//+------------------------------------------------------------------+
//| MAIN TICK FUNCTION                                               |
//+------------------------------------------------------------------+
void OnTick() {
   CheckReset();

   // Fetch news data periodically (Layer 6)
   FetchNewsViaWeb();

   // Risk and exit always run — positions must be managed even when stopped
   ManagePendingOrders();
   CheckRisk();
   CheckTrailing();
   CheckGeneralTP();

   // Entries and grid expansion (guard inside CheckMA)
   CheckMA();            // Layer 1: Entry signal (per tick)
   CheckGridLevels();    // Layer 2: Grid management (per basket)
}
