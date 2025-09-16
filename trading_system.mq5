//+------------------------------------------------------------------+
//|                             OPR_NQ.mq5                           |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "2.14"
#property strict

#include <Trade\Trade.mqh>
#include <Files\FileTxt.mqh>

//--- inputs
input double          InpRiskPercent       = 1.0;      // risque par trade (% du solde)
input ulong           InpMagic             = 20250516; // magic number
input ENUM_TIMEFRAMES InpTF                = PERIOD_M15;// timeframe détection
input int             InpSlippage          = 5;        // slippage max (points)
input int             InpTPRatio           = 1;        // TP = SL × ratio

input bool            InpUseBreakeven      = true;     // activer Break-Even
input int             InpBEPercent         = 50;       // % du TP pour BE

input bool            InpUsePartialTP      = true;     // activer prise partielle
input double          InpPartialTriggerPct = 50.0;     // % du chemin TP déclenche partial
input double          InpPartialVolumePct  = 50.0;     // % du volume à fermer

//--- globals
CTrade    trade;
bool      g_opr_ready     = false;
bool      g_trade_allowed = false;
bool      g_trade_done    = false;
bool      g_be_applied    = false;
bool      g_partial_done  = false;
bool      g_closed_eod    = false;
double    g_opr_high      = 0.0;
double    g_opr_low       = 0.0;
datetime  g_last_bar_time = 0;
int       g_last_calc_day = -1;

//+------------------------------------------------------------------+
//| Calcule le lot selon le risque                                  |
//+------------------------------------------------------------------+
double CalcDynamicLot(double entry,double sl)
{
  double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
  double riskAmount = balance * InpRiskPercent/100.0;
  double tickValue  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
  double tickSize   = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
  double dist       = MathAbs(entry-sl);
  double riskLot    = (dist/tickSize)*tickValue;
  if(riskLot<=0.0) return(0.0);

  double rawLots = riskAmount/riskLot;
  double minLot  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
  double stepLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
  double lots    = MathFloor(rawLots/stepLot)*stepLot;
  if(lots<minLot) lots=minLot;
  return NormalizeDouble(lots,2);
}

int OnInit()
{
  Print("\U0001F5D5 Initialisation de l’EA...");
  Print("\U0001F5A5 Heure locale   : ", TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS));
  Print("\U0001F4E1 Heure serveur : ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
  Print("⏳ Décalage (sec): ", (int)(TimeLocal() - TimeCurrent()));

  string objs[6] = {"OPR_High","OPR_Low","BE_Level","PT_Level","BE_Label","PT_Label"};
  for(int i=0;i<6;i++) ObjectDelete(0, objs[i]);
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
  string objs[6] = {"OPR_High","OPR_Low","BE_Level","PT_Level","BE_Label","PT_Label"};
  for(int i=0;i<6;i++) ObjectDelete(0, objs[i]);
}

void WriteLogToCSV(string symbol, double price, double tp, double sl, double ptL, double progress, bool pt_done, bool be_done)
{
  if(tp == sl) return;
  string filename = StringFormat("OPR_LOG_%s.csv", symbol);
  int file_handle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI);

  if(file_handle == INVALID_HANDLE)
  {
    Print("Erreur d'ouverture du fichier : ", filename);
    return;
  }

  if(FileSize(file_handle) == 0)
    FileWrite(file_handle, "timestamp,symbol,price,tp,sl,ptL,progress_pct,partial_done,be_done");

  string line = StringFormat("%s,%s,%.2f,%.2f,%.2f,%.2f,%.1f,%d,%d",
                    TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS),
                    symbol, price, tp, sl, ptL, progress,
                    (int)pt_done, (int)be_done);

  FileSeek(file_handle, 0, SEEK_END);
  FileWrite(file_handle, line);
  FileClose(file_handle);
  Print("📁 Log enregistré dans le fichier : ", filename);
}

void OnTick()
{
  datetime lastOpen = iTime(_Symbol, InpTF, 1);
  if(lastOpen != g_last_bar_time)
  {
    g_last_bar_time = lastOpen;
    MqlDateTime dt; TimeToStruct(lastOpen, dt);
    if(dt.day != g_last_calc_day)
    {
      g_last_calc_day    = dt.day;
      g_opr_ready        = false;
      g_trade_allowed    = false;
      g_trade_done       = false;
      g_be_applied       = false;
      g_partial_done     = false;
      g_closed_eod       = false;
      string objs[6] = {"OPR_High","OPR_Low","BE_Level","PT_Level","BE_Label","PT_Label"};
      for(int i=0;i<6;i++) ObjectDelete(0, objs[i]);
    }

    MqlDateTime loc; TimeToStruct(TimeLocal(), loc);
    if(loc.hour >= 21)
    {
      if(!g_closed_eod)
      {
        for(int i=PositionsTotal()-1; i>=0; i--)
        {
          ulong tk = PositionGetTicket(i);
          if(PositionSelectByTicket(tk) && PositionGetInteger(POSITION_MAGIC)==(long)InpMagic)
            trade.PositionClose(tk);
        }
        g_closed_eod = true;
        PrintFormat("\U0001F514 EOD Close: toutes les positions Magic=%d fermées", InpMagic);
      }
    }
    else g_closed_eod = false;

    if(!g_opr_ready && loc.hour == 15 && loc.min == 45)
    {
      g_opr_high = iHigh(_Symbol, InpTF, 1);
      g_opr_low  = iLow (_Symbol, InpTF, 1);
      ObjectCreate(0,"OPR_High",OBJ_HLINE,0,0,g_opr_high);
      ObjectSetInteger(0,"OPR_High",OBJPROP_COLOR,clrRed);
      ObjectSetInteger(0,"OPR_High",OBJPROP_WIDTH,2);
      ObjectCreate(0,"OPR_Low", OBJ_HLINE,0,0,g_opr_low);
      ObjectSetInteger(0,"OPR_Low", OBJPROP_COLOR,clrRed);
      ObjectSetInteger(0,"OPR_Low", OBJPROP_WIDTH,2);
      g_opr_ready = true;
    }

    if(g_opr_ready && !g_trade_allowed && loc.hour == 15 && loc.min == 45)
      g_trade_allowed = true;
  }

  if(g_trade_allowed && !g_trade_done)
  {
    for(int i=0;i<PositionsTotal();i++)
    {
      ulong tk = PositionGetTicket(i);
      if(PositionSelectByTicket(tk) && PositionGetInteger(POSITION_MAGIC)==(long)InpMagic)
        return;
    }

    double prevClose = iClose(_Symbol, InpTF, 1);
    if(prevClose > g_opr_high)
    {
      double entry = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double sl    = g_opr_low;
      double tp    = entry + MathAbs(entry - sl) * InpTPRatio;
      double lots  = CalcDynamicLot(entry, sl);

      trade.SetExpertMagicNumber(InpMagic);
      if(trade.Buy(lots, _Symbol, entry, sl, tp))
        g_trade_done = true;
    }
    else if(prevClose < g_opr_low)
    {
      double entry = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double sl    = g_opr_high;
      double tp    = entry - MathAbs(entry - sl) * InpTPRatio;
      double lots  = CalcDynamicLot(entry, sl);

      trade.SetExpertMagicNumber(InpMagic);
      if(trade.Sell(lots, _Symbol, entry, sl, tp))
        g_trade_done = true;
    }
  }

  if(PositionSelect(_Symbol) && PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
  {
    ulong  ticket = (ulong)PositionGetInteger(POSITION_TICKET);
    long   type   = PositionGetInteger(POSITION_TYPE);
    double entry  = PositionGetDouble(POSITION_PRICE_OPEN);
    double tp     = PositionGetDouble(POSITION_TP);
    double sl     = PositionGetDouble(POSITION_SL);
    double price  = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    if(InpUsePartialTP && !g_partial_done)
    {
      double ptL = (type == POSITION_TYPE_BUY)
                   ? entry + (tp - entry) * InpPartialTriggerPct / 100.0
                   : entry - (entry - tp) * InpPartialTriggerPct / 100.0;

      double totalRange     = MathAbs(tp - entry);
      double currentProgress = (type == POSITION_TYPE_BUY) ? (price - entry) : (entry - price);
      double progressPct     = (totalRange > 0) ? (currentProgress / totalRange * 100.0) : 0.0;

      PrintFormat("|||--- 🔍 [Debug (%s)] : Prix : %.2f | Parcours : %.1f%% | TP : %.2f | SL : %.2f | Partial : %.2f ---|||",
                  _Symbol, price, progressPct, tp, sl, ptL);

      WriteLogToCSV(_Symbol, price, tp, sl, ptL, progressPct, g_partial_done, g_be_applied);

      bool triggerPT = (type == POSITION_TYPE_BUY && price >= ptL) ||
                       (type == POSITION_TYPE_SELL && price <= ptL);

      double safetyL = (type == POSITION_TYPE_BUY)
                       ? entry + (tp - entry) * 0.9
                       : entry - (entry - tp) * 0.9;

      if(!triggerPT && ((type == POSITION_TYPE_BUY && price >= safetyL) ||
                        (type == POSITION_TYPE_SELL && price <= safetyL)))
      {
        triggerPT = true;
        Print("[Sécurité] PT déclenchée car proche TP");
      }

      if(triggerPT)
      {
        double closeVol = PositionGetDouble(POSITION_VOLUME) * InpPartialVolumePct / 100.0;
        double step     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

        closeVol = MathFloor(closeVol / step) * step;
        if(closeVol >= minLot)
        {
          if(trade.PositionClosePartial(ticket, closeVol))
          {
            g_partial_done = true;
            PrintFormat("Prise partielle effectuée : %.2f lots", closeVol);
          }
        }
        else
        {
          PrintFormat("Volume partiel trop petit : %.4f < %.2f", closeVol, minLot);
        }
      }
    }

    if(InpUseBreakeven && !g_be_applied)
    {
      double beL = (type == POSITION_TYPE_BUY)
                   ? entry + (tp - entry) * InpBEPercent / 100.0
                   : entry - (entry - tp) * InpBEPercent / 100.0;

      if((type == POSITION_TYPE_BUY && price >= beL) ||
         (type == POSITION_TYPE_SELL && price <= beL))
      {
        if(trade.PositionModify(ticket, entry, tp))
        {
          g_be_applied = true;
          PrintFormat("Break Even activé : SL à l'entrée (%.2f)", entry);
        }
      }
    }
  }
}
