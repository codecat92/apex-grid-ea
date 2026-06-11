//+------------------------------------------------------------------+
//|                                               ApexGrid.mq4       |
//|                                   Apex Grid EA - Grid+Martingale |
//|                          Inspired by Yetti Classic v3.03_fix     |
//+------------------------------------------------------------------+
#property copyright "codecat92"
#property link      ""
#property version   "1.01"
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

//+------------------------------------------------------------------+
//| MA ENTRY SIGNAL PARAMETERS                                       |
//+------------------------------------------------------------------+
extern int    MAFastPeriod      = 5;      // Periode MA cepat
extern int    MASlowPeriod      = 40;     // Periode MA lambat
extern int    MAMethod          = 0;      // 0=SMA,1=EMA,2=SMMA,3=LWMA
extern int    MAPrice           = 0;      // 0=Close,1=Open,2=High,3=Low,4=Median,5=Typical,6=Weighted

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
//| GRID MANAGER (Layer 2)                                           |
//| Open a full grid level (OrdersPerStep orders)                    |
//+------------------------------------------------------------------+
void OpenGridLevel(string side) {
   int level;
   int cmd, slip = 3;
   double sl, tp;

   if (side == "BUY") {
      G_BuyActive = true;
      G_BuyLevel++;
      level = G_BuyLevel;
      cmd = OP_BUY;
   } else {
      G_SellActive = true;
      G_SellLevel++;
      level = G_SellLevel;
      cmd = OP_SELL;
   }

   double lot = LotByLevel(level);
   string cmt = MakeComment(side, level);

   if (level == 0) {
      if (!RefreshRates()) {
         Print(G_Name + " RefreshRates failed at level 0");
         if (side == "BUY") { G_BuyActive = false; G_BuyLevel = -1; }
         else               { G_SellActive = false; G_SellLevel = -1; }
         return;
      }
      if (side == "BUY") {
         G_BuyFirstPrice = Ask;
         G_BuyPeak       = Ask;
      } else {
         G_SellFirstPrice = Bid;
         G_SellTrough     = Bid;
      }
   }

   sl = 0;
   tp = 0;

   bool anySucceeded = false;
   for (int j = 0; j < OrdersPerStep; j++) {
      if (!RefreshRates()) {
         Print(G_Name + " RefreshRates failed at level ", level);
         continue;
      }
      double price = (side == "BUY") ? Ask : Bid;
      int ticket = OrderSend(Symbol(), cmd, lot, price, slip, sl, tp, cmt, G_Magic, 0, CLR_NONE);
      if (ticket >= 0) {
         anySucceeded = true;
      } else {
         Print(G_Name + " OrderSend error ", GetLastError(), " side=", side, " level=", level);
      }
   }

   if (!anySucceeded) {
      if (side == "BUY") {
         G_BuyLevel--;
         if (G_BuyLevel < 0) {
            G_BuyActive = false;
            G_BuyLevel = -1;
            G_BuyFirstPrice = 0;
            G_BuyPeak = 0;
            G_BuyTrailing = false;
         }
      } else {
         G_SellLevel--;
         if (G_SellLevel < 0) {
            G_SellActive = false;
            G_SellLevel = -1;
            G_SellFirstPrice = 0;
            G_SellTrough = 0;
            G_SellTrailing = false;
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

   if (side == "BUY") {
      G_BuyActive    = false;
      G_BuyLevel     = -1;
      G_BuyFirstPrice= 0;
      G_BuyPeak      = 0;
      G_BuyTrailing  = false;
   } else {
      G_SellActive    = false;
      G_SellLevel     = -1;
      G_SellFirstPrice= 0;
      G_SellTrough    = 0;
      G_SellTrailing  = false;
   }
}

//+------------------------------------------------------------------+
//| TRAILING STOP (Layer 3)                                          |
//| Trailing aktif setelah harga bergerak TriggerDistance dari entry |
//| pertama. Basket close jika harga pullback FixedDistance.         |
//+------------------------------------------------------------------+
void CheckTrailing() {
   if (!UseTrailingStop) return;

   double pip = PipSize();

   // --- BUY trailing ---
   if (G_BuyActive) {
      double dist = (Bid - G_BuyFirstPrice) / pip;
      if (dist >= TriggerDistance) {
         G_BuyTrailing = true;
      }
      if (G_BuyTrailing) {
         if (Bid > G_BuyPeak) G_BuyPeak = Bid;
         double pullback = (G_BuyPeak - Bid) / pip;
         if (pullback >= FixedDistance) {
            BasketClose("BUY");
         }
      }
   }

   // --- SELL trailing ---
   if (G_SellActive) {
      double dist = (G_SellFirstPrice - Ask) / pip;
      if (dist >= TriggerDistance) {
         G_SellTrailing = true;
      }
      if (G_SellTrailing) {
         if (Ask < G_SellTrough) G_SellTrough = Ask;
         double pullback = (Ask - G_SellTrough) / pip;
         if (pullback >= FixedDistance) {
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
      if (dist >= step) OpenGridLevel("BUY");
   }

   // SELL: price rises GridStep from deepest entry
   if (G_SellActive) {
      double highest = HighestSellPrice();
      if (highest == 0) highest = G_SellFirstPrice;
      dist = (Ask - highest) / pip;
      if (dist >= step) OpenGridLevel("SELL");
   }
}

//+------------------------------------------------------------------+
//| MA ENTRY SIGNAL (Layer 1)                                        |
//| Golden Cross -> BUY grid, Death Cross -> SELL grid               |
//+------------------------------------------------------------------+
void CheckMA() {
   double fast1 = iMA(Symbol(), 0, MAFastPeriod, 0, MAMethod, MAPrice, 1);
   double slow1 = iMA(Symbol(), 0, MASlowPeriod, 0, MAMethod, MAPrice, 1);
   double fast2 = iMA(Symbol(), 0, MAFastPeriod, 0, MAMethod, MAPrice, 2);
   double slow2 = iMA(Symbol(), 0, MASlowPeriod, 0, MAMethod, MAPrice, 2);

   if (fast1 <= 0 || slow1 <= 0 || fast2 <= 0 || slow2 <= 0) return;

   // Golden Cross: fast crosses ABOVE slow
   if (!G_BuyActive && fast2 <= slow2 && fast1 > slow1) {
      OpenGridLevel("BUY");
   }

   // Death Cross: fast crosses BELOW slow
   if (!G_SellActive && fast2 >= slow2 && fast1 < slow1) {
      OpenGridLevel("SELL");
   }
}

//+------------------------------------------------------------------+
//| GENERAL TP CHECK                                                 |
//| Basket close when price moves favorably by GeneralTP from entry  |
//+------------------------------------------------------------------+
void CheckGeneralTP() {
   if (GeneralTP <= 0) return;
   double pip = PipSize();

   if (G_BuyActive && G_BuyFirstPrice > 0) {
      if ((Bid - G_BuyFirstPrice) / pip >= GeneralTP) {
         BasketClose("BUY");
         return;
      }
   }
   if (G_SellActive && G_SellFirstPrice > 0) {
      if ((G_SellFirstPrice - Ask) / pip >= GeneralTP) {
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
   double mrgLv = (AccountMargin() > 0) ? (eq / AccountMargin()) * 100 : 0;

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
//| Reset daily/weekly equity tracking                               |
//+------------------------------------------------------------------+
void CheckReset() {
   datetime today  = iTime(Symbol(), PERIOD_D1, 0);
   datetime thisWk = iTime(Symbol(), PERIOD_W1, 0);

   if (today != G_DayStart) {
      G_DayStart = today;
      G_DayEquity = AccountEquity();
      if (G_StopReason != STOP_DRAWDOWN) {
         G_Stopped = false;
         G_StopReason = STOP_NONE;
      }
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

   if (!IsTradingAllowed()) {
      // Risk tetap berjalan meski trading dilarang
      CheckRisk();
      return;
   }

   CheckRisk();
   if (G_Stopped) return;

   CheckMA();            // Layer 1: Entry signal
   CheckGridLevels();    // Layer 2: Grid management
   CheckGeneralTP();     // General take-profit
   CheckTrailing();      // Layer 3: Exit / trailing stop
}
