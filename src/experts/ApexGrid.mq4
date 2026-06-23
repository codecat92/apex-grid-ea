//+------------------------------------------------------------------+
//|                                               ApexGrid.mq4       |
//|                                   Apex Grid EA - Grid+Martingale |
//|                          Inspired by Yetti Classic v3.03_fix     |
//+------------------------------------------------------------------+
#property copyright "codecat92"
#property link      ""
#property version   "1.07"
#property strict

//+------------------------------------------------------------------+
//| CORE TRADING PARAMETERS                                          |
//+------------------------------------------------------------------+
extern int    MagicNumber       = 1888;   // ID unik bot
extern double StartLot          = 0.10;   // Lot pertama setiap grid
extern double Multiplier        = 1.5;    // Pengali lot tiap level
extern int    GridStep          = 250;    // Jarak antar level (pips)
extern int    GeneralTP         = 200;    // TP keseluruhan (pips)
extern int    OrdersPerStep     = 2;      // Jumlah order per level
extern int    MaxGridLevel      = 10;     // Batas maksimum level grid
extern int    StopLossPips      = 375;    // Jarak Stop Loss per level (pips)

//+------------------------------------------------------------------+
//| MA ENTRY SIGNAL PARAMETERS                                       |
//+------------------------------------------------------------------+
extern int    MAFastPeriod      = 5;      // Periode MA cepat
extern int    MASlowPeriod      = 40;     // Periode MA lambat
extern int    MAMethod          = 0;      // 0=SMA,1=EMA,2=SMMA,3=LWMA
extern int    MAPrice           = 0;      // 0=Close,1=Open,2=High,3=Low,4=Median,5=Typical,6=Weighted
extern int    BBPeriod          = 20;     // Periode Bollinger Bands
extern double BBDeviation       = 2.0;    // Deviasi Bollinger Bands

//+------------------------------------------------------------------+
//| TRAILING EXIT PARAMETERS                                         |
//+------------------------------------------------------------------+
extern bool   UseTrailingStop   = true;   // Aktifkan trailing stop
extern int    FixedDistance     = 50;     // Jarak trailing (pips)
extern int    TriggerDistance   = 160;    // Jarak minimal sebelum trailing aktif

//+------------------------------------------------------------------+
//| TIME FILTER PARAMETERS                                           |
//+------------------------------------------------------------------+
extern string StartTime         = "01:00";// Jam mulai trading
extern string EndTime           = "22:00";// Jam berhenti trading
extern bool   FridayTrade       = true;   // Trading hari Jumat
extern string FridayStop        = "14:00";// Jam stop Jumat
extern bool   UseExtraTime      = true;   // Window tambahan
extern string ExtraStart        = "01:06";// Mulai extra window
extern string ExtraEnd          = "01:07";// Akhir extra window
extern int    AdditionalGridStep = 100;   // Grid step extra window

//+------------------------------------------------------------------+
//| RISK MANAGEMENT PARAMETERS                                       |
//+------------------------------------------------------------------+
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
extern bool   NewsFilter         = false;   // Aktifkan news filter
extern int    NewsMinutesBefore  = 30;      // Menit sebelum news (no entry)
extern int    NewsMinutesAfter   = 60;      // Menit setelah news (no entry)
extern int    NewsRefreshMin     = 15;      // Interval refresh file news (menit)
extern string NewsCurrencies     = "USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY"; // Filter mata uang
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
//| GRID STATE                                                       |
//+------------------------------------------------------------------+
bool     G_BuyActive       = false;
bool     G_SellActive      = false;
int      G_BuyLevel        = -1;
int      G_SellLevel       = -1;
double   G_BuyFirstPrice   = 0;
double   G_SellFirstPrice  = 0;
double   G_BuyPeak         = 0;
double   G_SellTrough      = 0;
bool     G_BuyTrailing     = false;
bool     G_SellTrailing    = false;
double   G_BuyPeakProfit    = 0;
double   G_SellPeakProfit   = 0;
datetime G_BuyLastClosed    = 0;
datetime G_SellLastClosed   = 0;

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
//| Helper: Normalize lot to broker rules                             |
//+------------------------------------------------------------------+
double NormalizeLot(double lot) {
   double min  = MarketInfo(Symbol(), MODE_MINLOT);
   double max  = MarketInfo(Symbol(), MODE_MAXLOT);
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   int digits = (step >= 0.1) ? 1 : 2;
   lot = MathFloor(lot / step) * step;
   if (lot < min) lot = min;
   if (lot > max) lot = max;
   return NormalizeDouble(lot, digits);
}

//+------------------------------------------------------------------+
//| Calculate lot for a grid level: StartLot * Multiplier^level      |
//+------------------------------------------------------------------+
double LotByLevel(int level) {
   return NormalizeLot(StartLot * MathPow(Multiplier, level));
}

//+------------------------------------------------------------------+
//| Build order comment for a side + level                           |
//+------------------------------------------------------------------+
string MakeComment(string side, int level) {
   if (level == 0) return G_Name + " " + side;
   return G_Name + " " + side + " " + IntegerToString(level);
}

//+------------------------------------------------------------------+
//| Helper: Convert "HH:MM" string to integer minutes                |
//+------------------------------------------------------------------+
int StrToMinutes(string t) {
   return StrToInteger(StringSubstr(t, 0, 2)) * 60 + StrToInteger(StringSubstr(t, 3, 2));
}

//+------------------------------------------------------------------+
//| Get current grid step (uses AdditionalGridStep during extra time)|
//+------------------------------------------------------------------+
int CurrentGridStep() {
   if (UseExtraTime) {
      int now = Hour() * 60 + Minute();
      if (now >= G_ExtraStartMin && now <= G_ExtraEndMin) return AdditionalGridStep;
   }
   return GridStep;
}

//+------------------------------------------------------------------+
//| TIME FILTER (Layer 4)                                            |
//+------------------------------------------------------------------+
bool IsTradingAllowed() {
   if (G_Stopped) return false;
   if (NewsFilter && IsNewsBlackout()) return false;
   int dow = DayOfWeek();
   if (dow == 0 || dow == 6) return false;
   int now = Hour() * 60 + Minute();
   if (now < G_StartMin || now > G_EndMin) return false;
   if (dow == 5) {
      if (!FridayTrade) return false;
      if (now >= G_FridayStopMin) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Find the lowest open price among BUY orders (deepest level)      |
//+------------------------------------------------------------------+
double LowestBuyPrice() {
   double low = DBL_MAX;
   string prefix = G_Name + " BUY";
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      if (OrderOpenPrice() < low) low = OrderOpenPrice();
   }
   return (low == DBL_MAX) ? 0 : low;
}

//+------------------------------------------------------------------+
//| Find the highest open price among SELL orders (deepest level)    |
//+------------------------------------------------------------------+
double HighestSellPrice() {
   double high = 0;
   string prefix = G_Name + " SELL";
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      if (OrderOpenPrice() > high) high = OrderOpenPrice();
   }
   return high;
}

//+------------------------------------------------------------------+
//| Get total profit + swap + commission for one side                |
//+------------------------------------------------------------------+
double SideProfit(string side) {
   double p = 0;
   string prefix = G_Name + " " + side;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      p += OrderProfit() + OrderSwap() + OrderCommission();
   }
    return p;
}

//+------------------------------------------------------------------+
//| Calculate lot-weighted average entry price for a side            |
//+------------------------------------------------------------------+
double BasketAvgPrice(string side) {
   double totalLots = 0, weightedPrice = 0;
   string prefix = G_Name + " " + side;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
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
double TotalSideLots(string side) {
   double lots = 0;
   string prefix = G_Name + " " + side;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
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
void OpenGridLevel(string side) {
   int level;
   int cmd, slip = 3;
   bool isPending;

   if (side == "BUY") {
      G_BuyActive = true;
      G_BuyLevel++;
      level = G_BuyLevel;
      isPending = (level > 0);
      cmd = isPending ? OP_BUYSTOP : OP_BUY;
   } else {
      G_SellActive = true;
      G_SellLevel++;
      level = G_SellLevel;
      isPending = (level > 0);
      cmd = isPending ? OP_SELLSTOP : OP_SELL;
   }

   double lot = LotByLevel(level);
   string cmt = MakeComment(side, level);

   if (level == 0) {
      RefreshRates();
      if (side == "BUY") {
         G_BuyFirstPrice = Ask;
         G_BuyPeak       = Ask;
         G_BuyPeakProfit = 0;
      } else {
         G_SellFirstPrice = Bid;
         G_SellTrough     = Bid;
         G_SellPeakProfit = 0;
      }
   }

   // Calculate entry price for pending orders (levels > 0)
   double pendingPrice = 0;
   if (isPending) {
      double stepPips = CurrentGridStep() * PipSize();
      if (side == "BUY") {
         double lowest = LowestBuyPrice();
         if (lowest == 0) lowest = G_BuyFirstPrice;
         pendingPrice = lowest - stepPips;
      } else {
         double highest = HighestSellPrice();
         if (highest == 0) highest = G_SellFirstPrice;
         pendingPrice = highest + stepPips;
      }
      // Ensure pending price is valid vs current market
      RefreshRates();
      double stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * PipSize();
      if (side == "BUY" && pendingPrice >= Ask - stoplevel) pendingPrice = Ask - stoplevel;
      if (side == "SELL" && pendingPrice <= Bid + stoplevel) pendingPrice = Bid + stoplevel;
   }

   Print(G_Name + " Grid ", side, " level ", level, " lot=", lot, " pending=", isPending);

   bool anySucceeded = false;
   for (int j = 0; j < OrdersPerStep; j++) {
      RefreshRates();
      double price = isPending ? pendingPrice : ((side == "BUY") ? Ask : Bid);
      double sl = 0;
      if (side == "BUY")
         sl = price - (StopLossPips * PipSize());
      else
         sl = price + (StopLossPips * PipSize());
      int ticket = OrderSend(Symbol(), cmd, lot, price, slip, sl, 0, cmt, G_Magic, 0, CLR_NONE);
      if (ticket >= 0) {
         anySucceeded = true;
         Print(G_Name + " Order opened ticket=", ticket);
      } else {
         int err = GetLastError();
         if (isPending && (err == 130)) {
            RefreshRates();
            double mktPrice = (cmd == OP_BUYSTOP) ? Ask : Bid;
            double sl2 = 0;
            if (side == "BUY")
               sl2 = mktPrice - (StopLossPips * PipSize());
            else
               sl2 = mktPrice + (StopLossPips * PipSize());
            ticket = OrderSend(Symbol(), (cmd == OP_BUYSTOP) ? OP_BUY : OP_SELL,
                               lot, mktPrice, slip, sl2, 0, cmt, G_Magic, 0, CLR_NONE);
            if (ticket >= 0) anySucceeded = true;
            else Print(G_Name + " Market fallback error ", GetLastError(), " side=", side, " level=", level);
         } else {
            Print(G_Name + " OrderSend error ", err, " side=", side, " level=", level);
         }
      }
   }

   if (!anySucceeded) {
      if (side == "BUY") {
         G_BuyLevel--;
         if (G_BuyLevel < 0) {
            G_BuyActive = false; G_BuyLevel = -1;
            G_BuyFirstPrice = 0; G_BuyPeak = 0;
            G_BuyPeakProfit = 0; G_BuyTrailing = false;
         }
      } else {
         G_SellLevel--;
         if (G_SellLevel < 0) {
            G_SellActive = false; G_SellLevel = -1;
            G_SellFirstPrice = 0; G_SellTrough = 0;
            G_SellPeakProfit = 0; G_SellTrailing = false;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| BASKET CLOSE (Layer 3)                                           |
//| Close ALL orders of a side, then reset grid state                |
//+------------------------------------------------------------------+
void BasketClose(string side) {
   int tickets[500];
   ArrayInitialize(tickets, 0);
   int n = 0;
   string prefix = G_Name + " " + side;

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (StringFind(OrderComment(), prefix) != 0) continue;
      tickets[n] = OrderTicket();
      n++;
   }

   if (n == 0) {
      Print(G_Name + " BasketClose: no orders to close for ", side);
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
      Print(G_Name + " BasketClose: ", failed, " orders failed to close for ", side);
      return;
   }

   Print(G_Name + " TRAL:::: close on the trawl ", side);

   if (side == "BUY") {
      G_BuyActive     = false;
      G_BuyLevel      = -1;
      G_BuyFirstPrice = 0;
      G_BuyPeak       = 0;
      G_BuyPeakProfit = 0;
      G_BuyTrailing   = false;
      G_BuyLastClosed = TimeCurrent();
   } else {
      G_SellActive     = false;
      G_SellLevel      = -1;
      G_SellFirstPrice = 0;
      G_SellTrough     = 0;
      G_SellPeakProfit = 0;
      G_SellTrailing   = false;
      G_SellLastClosed = TimeCurrent();
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

   // --- BUY trailing ---
   if (G_BuyActive) {
      double dist   = (Bid - G_BuyFirstPrice) / pip;
      double profit = SideProfit("BUY");
      if (dist >= TriggerDistance) {
         G_BuyTrailing = true;
      }
      if (G_BuyTrailing) {
         if (profit > G_BuyPeakProfit) G_BuyPeakProfit = profit;
         double drop      = G_BuyPeakProfit - profit;
         double threshold = FixedDistance * pipVal * TotalSideLots("BUY");
         if (drop >= threshold && drop > 0) {
            Print(G_Name + " TRAL:::: close on the trawl BUY");
            BasketClose("BUY");
         }
      }
   }

   // --- SELL trailing ---
   if (G_SellActive) {
      double dist   = (G_SellFirstPrice - Ask) / pip;
      double profit = SideProfit("SELL");
      if (dist >= TriggerDistance) {
         G_SellTrailing = true;
      }
      if (G_SellTrailing) {
         if (profit > G_SellPeakProfit) G_SellPeakProfit = profit;
         double drop      = G_SellPeakProfit - profit;
         double threshold = FixedDistance * pipVal * TotalSideLots("SELL");
         if (drop >= threshold && drop > 0) {
            Print(G_Name + " TRAL:::: close on the trawl SELL");
            BasketClose("SELL");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if a new grid level needs to be opened                     |
//| Harga bergerak GridStep berlawanan arah dari level sebelumnya   |
//+------------------------------------------------------------------+
void CheckGridLevels() {
   double pip  = PipSize();
   int step    = CurrentGridStep();
   double dist;

   // BUY: price drops GridStep from deepest entry
   if (G_BuyActive) {
      double lowest = LowestBuyPrice();
      if (lowest == 0) lowest = G_BuyFirstPrice;
      dist = (lowest - Bid) / pip;
      if (dist >= step && G_BuyLevel < MaxGridLevel) OpenGridLevel("BUY");
   }

   // SELL: price rises GridStep from deepest entry
   if (G_SellActive) {
      double highest = HighestSellPrice();
      if (highest == 0) highest = G_SellFirstPrice;
      dist = (Ask - highest) / pip;
      if (dist >= step && G_SellLevel < MaxGridLevel) OpenGridLevel("SELL");
   }
}

//+------------------------------------------------------------------+
//| MANAGE PENDING ORDERS                                            |
//| Gap-fill: if price passed a pending stop order without filling,  |
//| delete it and place a market order instead.                      |
//+------------------------------------------------------------------+
void ManagePendingOrders() {
   double pip = PipSize();
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != G_Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderType() != OP_BUYSTOP && OrderType() != OP_SELLSTOP) continue;

      RefreshRates();
      if (OrderType() == OP_BUYSTOP && Ask <= OrderOpenPrice() - 5 * pip) {
         double lots = OrderLots();
         string cmt  = OrderComment();
         int delTicket = OrderTicket();
         if (OrderDelete(delTicket)) {
            int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, 0, 0, cmt, G_Magic, 0, CLR_NONE);
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
            int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, 0, 0, cmt, G_Magic, 0, CLR_NONE);
            if (ticket >= 0) Print(G_Name + " Gap-filled SELL ticket=", ticket);
            else Print(G_Name + " Gap-fill SELL error ", GetLastError());
         } else {
            Print(G_Name + " Gap-fill: failed to delete SELLSTOP ticket=", delTicket, " err=", GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| MA ENTRY SIGNAL (Layer 1)                                        |
//| Golden Cross -> BUY grid, Death Cross -> SELL grid               |
//| Signal evaluated once per bar. 5-min cooldown after basket close.|
//+------------------------------------------------------------------+
void CheckMA() {
   static datetime lastBar = 0;
   datetime currentBar = Time[0];
   if (currentBar == lastBar) return;
   lastBar = currentBar;

   double fast1 = iMA(Symbol(), 0, MAFastPeriod, 0, MAMethod, MAPrice, 1);
   double slow1 = iMA(Symbol(), 0, MASlowPeriod, 0, MAMethod, MAPrice, 1);
   double fast2 = iMA(Symbol(), 0, MAFastPeriod, 0, MAMethod, MAPrice, 2);
   double slow2 = iMA(Symbol(), 0, MASlowPeriod, 0, MAMethod, MAPrice, 2);

   if (fast1 <= 0 || slow1 <= 0 || fast2 <= 0 || slow2 <= 0) return;

   int cooldownSec = 0;

   bool goldenCross = (!G_BuyActive && fast2 <= slow2 && fast1 > slow1);
   bool deathCross  = (!G_SellActive && fast2 >= slow2 && fast1 < slow1);

   double bbUpper = iBands(Symbol(), 0, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
   double bbLower = iBands(Symbol(), 0, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, 1);

   if (bbUpper <= 0 || bbLower <= 0) return;

   bool bbBuyOk  = (Low[1] <= bbLower || Close[1] <= bbLower);
   bool bbSellOk = (High[1] >= bbUpper || Close[1] >= bbUpper);

   if (goldenCross && bbBuyOk) {
      if (G_BuyLastClosed == 0 || TimeCurrent() - G_BuyLastClosed >= cooldownSec) {
         Print(G_Name + " MA signal: Golden Cross -> BUY grid");
         OpenGridLevel("BUY");
      }
   }

   if (deathCross && bbSellOk) {
      if (G_SellLastClosed == 0 || TimeCurrent() - G_SellLastClosed >= cooldownSec) {
         Print(G_Name + " MA signal: Death Cross -> SELL grid");
         OpenGridLevel("SELL");
      }
   }
}

//+------------------------------------------------------------------+
//| GENERAL TP CHECK                                                 |
//| Basket close when basket-weighted average price reaches TP       |
//+------------------------------------------------------------------+
void CheckGeneralTP() {
   if (GeneralTP <= 0) return;
   double pip = PipSize();

   if (G_BuyActive) {
      double avg = BasketAvgPrice("BUY");
      if (avg > 0 && (Bid - avg) / pip >= GeneralTP) {
         Print(G_Name + " GeneralTP hit BUY");
         BasketClose("BUY");
         return;
      }
   }
   if (G_SellActive) {
      double avg = BasketAvgPrice("SELL");
      if (avg > 0 && (avg - Ask) / pip >= GeneralTP) {
         Print(G_Name + " GeneralTP hit SELL");
         BasketClose("SELL");
      }
   }
}

//+------------------------------------------------------------------+
//| RISK SHUTDOWN (Layer 5)                                          |
//+------------------------------------------------------------------+
void CheckRisk() {
   double eq    = AccountEquity();
   double bal   = AccountBalance();
   double ddPct = (bal > 0) ? (bal - eq) / bal * 100 : 0;
   double mrgLv = (AccountMargin() > 0) ? (eq / AccountMargin()) * 100 : DBL_MAX;

   // Auto stop jika drawdown melebihi batas
   if (AutoStopTrading && ddPct >= MaxDrawdown) {
      G_Stopped = true;
      G_StopReason = STOP_DRAWDOWN;
      return;
   }

   // Close all jika drawdown kritis
   if (ddPct >= DrawdownCloseAll) {
      if (G_BuyActive)  BasketClose("BUY");
      if (G_SellActive) BasketClose("SELL");
      G_Stopped = true;
      G_StopReason = STOP_DRAWDOWN;
      return;
   }

   // Close all jika margin level kritis
   if (mrgLv < MarginCloseAll) {
      if (G_BuyActive)  BasketClose("BUY");
      if (G_SellActive) BasketClose("SELL");
      G_Stopped = true;
      G_StopReason = STOP_MARGIN;
      return;
   }

   // Stop trading jika margin level di bawah minimum
   if (mrgLv < MinMarginLevel) {
      G_Stopped = true;
      G_StopReason = STOP_MARGIN;
      return;
   }

   // Daily profit target
   double dayProfit = eq - G_DayEquity;
   double dayPct    = (G_DayEquity > 0) ? (dayProfit / G_DayEquity) * 100 : 0;
   if (dayPct >= DailyProfitPct) {
      G_Stopped = true;
      G_StopReason = STOP_PROFIT;
      return;
   }

   // Weekly profit target
   double weekProfit = eq - G_WeekEquity;
   double weekPct    = (G_WeekEquity > 0) ? (weekProfit / G_WeekEquity) * 100 : 0;
   if (weekPct >= WeeklyProfitPct) {
      G_Stopped = true;
      G_StopReason = STOP_PROFIT;
   }
}

//+------------------------------------------------------------------+
//| NEWS FETCHER — Read news_cache.txt pipe-delimited file           |
//| Format: 2026-06-23T14:00:00Z|USD|High                             |
//| Returns true if data was refreshed successfully                   |
//+------------------------------------------------------------------+
bool FetchNewsFromFile() {
   if (!NewsFilter) {
      G_NewsDataValid = false;
      return false;
   }

   // Throttle: only refresh every NewsRefreshMin minutes
   if (G_NewsLastFetch > 0 && TimeCurrent() - G_NewsLastFetch < NewsRefreshMin * 60) {
      return G_NewsDataValid;
   }

   int h = FileOpen("news_cache.txt", FILE_READ|FILE_TXT|FILE_COMMON);
   if (h == INVALID_HANDLE) {
      G_NewsLastFetch = TimeCurrent();
      G_NewsDataValid = false;
      if (G_NewsEventCount > 0) {
         Print(G_Name + " News: file not found, clearing cache");
      }
      G_NewsEventCount = 0;
      return false;
   }

   string line;
   int count = 0;
   int offsetSec = NewsTimezoneOffset * 3600;

   // First pass: count valid events
   int validCount = 0;
   while (!FileIsEnding(h)) {
      line = FileReadString(h);
      StringTrimLeft(line);
      StringTrimRight(line);
      if (line == "" || StringGetChar(line, 0) == '#') continue;

      string dtStr  = StringSubstr(line, 0, 20);
      string ccStr  = "";

      int sep1 = StringFind(line, "|", 20);
      if (sep1 < 0) continue;
      int sep2 = StringFind(line, "|", sep1 + 1);
      if (sep2 < 0) continue;

      ccStr = StringSubstr(line, sep1 + 1, sep2 - sep1 - 1);

      // Check currency filter
      if (StringLen(NewsCurrencies) > 0 && StringFind(NewsCurrencies, ccStr) < 0) continue;

      string dtFixed = StringSubstr(dtStr, 0, 4) + "." +
                       StringSubstr(dtStr, 5, 2) + "." +
                       StringSubstr(dtStr, 8, 2) + " " +
                       StringSubstr(dtStr, 11, 2) + ":" +
                       StringSubstr(dtStr, 14, 2) + ":" +
                       StringSubstr(dtStr, 17, 2);
      datetime utc = StrToTime(dtFixed);
      if (utc <= 0) continue;

      validCount++;
   }

   FileSeek(h, 0, SEEK_SET);
   ArrayResize(G_NewsBlackouts, validCount);
   count = 0;

   while (!FileIsEnding(h) && count < validCount) {
      line = FileReadString(h);
      StringTrimLeft(line);
      StringTrimRight(line);
      if (line == "" || StringGetChar(line, 0) == '#') continue;

      string dtStr = StringSubstr(line, 0, 20);
      string ccStr = "";

      int sep1 = StringFind(line, "|", 20);
      if (sep1 < 0) continue;
      int sep2 = StringFind(line, "|", sep1 + 1);
      if (sep2 < 0) continue;
      ccStr = StringSubstr(line, sep1 + 1, sep2 - sep1 - 1);

      if (StringLen(NewsCurrencies) > 0 && StringFind(NewsCurrencies, ccStr) < 0) continue;

      string dtFixed = StringSubstr(dtStr, 0, 4) + "." +
                       StringSubstr(dtStr, 5, 2) + "." +
                       StringSubstr(dtStr, 8, 2) + " " +
                       StringSubstr(dtStr, 11, 2) + ":" +
                       StringSubstr(dtStr, 14, 2) + ":" +
                       StringSubstr(dtStr, 17, 2);
      datetime utc = StrToTime(dtFixed);
      if (utc <= 0) continue;

      // Convert UTC to broker time via offset
      datetime brokerEvent = utc + offsetSec;

      G_NewsBlackouts[count][0] = brokerEvent - (NewsMinutesBefore * 60);
      G_NewsBlackouts[count][1] = brokerEvent + (NewsMinutesAfter  * 60);
      count++;
   }

   FileClose(h);
   G_NewsLastFetch  = TimeCurrent();
   G_NewsEventCount = count;
   G_NewsDataValid  = (count > 0);

   if (count > 0) {
      Print(G_Name + " News: loaded ", count, " events, blackouts active");
   }
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
      G_DayStart = today;
      G_DayEquity = AccountEquity();
      G_Stopped = false;
      G_StopReason = STOP_NONE;
   }

   if (thisWk != G_WeekStart) {
      G_WeekStart = thisWk;
      G_WeekEquity = AccountEquity();
      if (G_StopReason == STOP_PROFIT) {
         G_Stopped = false;
         G_StopReason = STOP_NONE;
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

   Print(G_Name + " EA initialized. Magic: " + IntegerToString(G_Magic));
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
   FetchNewsFromFile();

   // Risk and exit always run — positions must be managed even when stopped
   ManagePendingOrders();
   CheckRisk();
   CheckTrailing();
   CheckGeneralTP();

   // Entries and grid expansion only when trading allowed and bot active
   if (!IsTradingAllowed() || G_Stopped) return;

   CheckMA();            // Layer 1: Entry signal
   CheckGridLevels();    // Layer 2: Grid management
}
