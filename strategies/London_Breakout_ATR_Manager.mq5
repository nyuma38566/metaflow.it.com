#property strict

#include <Trade/Trade.mqh>

input int RangeStartHour = 7;
input int RangeEndHour = 9;
input double LotSize = 0.10;
input int AtrPeriod = 14;
input double StopAtrMultiplier = 1.5;
input double TakeAtrMultiplier = 2.4;
input int MaxSpreadPoints = 40;
input ulong MagicNumber = 2026050803;

CTrade trade;
int atrHandle = INVALID_HANDLE;
datetime rangeDay = 0;
bool rangeReady = false;
bool tradedToday = false;
double rangeHigh = 0.0;
double rangeLow = 0.0;

bool IsNewBar()
{
  static datetime lastBarTime = 0;
  datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
  if(currentBarTime == lastBarTime)
  {
    return false;
  }

  lastBarTime = currentBarTime;
  return true;
}

datetime DayAnchor(datetime value)
{
  MqlDateTime parts;
  TimeToStruct(value, parts);
  parts.hour = 0;
  parts.min = 0;
  parts.sec = 0;
  return StructToTime(parts);
}

void ResetRange(datetime currentTime)
{
  rangeDay = DayAnchor(currentTime);
  rangeReady = false;
  tradedToday = false;
  rangeHigh = 0.0;
  rangeLow = 0.0;
}

bool InRangeWindow(datetime currentTime)
{
  MqlDateTime parts;
  TimeToStruct(currentTime, parts);
  return parts.hour >= RangeStartHour && parts.hour < RangeEndHour;
}

bool RangeWindowFinished(datetime currentTime)
{
  MqlDateTime parts;
  TimeToStruct(currentTime, parts);
  return parts.hour >= RangeEndHour;
}

bool HasManagedPosition()
{
  if(!PositionSelect(_Symbol))
  {
    return false;
  }

  return (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber;
}

void UpdateRange()
{
  double barHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
  double barLow = iLow(_Symbol, PERIOD_CURRENT, 1);

  if(rangeHigh == 0.0 || barHigh > rangeHigh)
  {
    rangeHigh = barHigh;
  }

  if(rangeLow == 0.0 || barLow < rangeLow)
  {
    rangeLow = barLow;
  }
}

void OpenBreakoutTrade(ENUM_ORDER_TYPE orderType, double atrValue)
{
  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

  double price = orderType == ORDER_TYPE_BUY ? ask : bid;
  double slDistance = atrValue * StopAtrMultiplier;
  double tpDistance = atrValue * TakeAtrMultiplier;

  double sl = orderType == ORDER_TYPE_BUY ? price - slDistance : price + slDistance;
  double tp = orderType == ORDER_TYPE_BUY ? price + tpDistance : price - tpDistance;

  trade.SetExpertMagicNumber(MagicNumber);

  if(orderType == ORDER_TYPE_BUY)
  {
    trade.Buy(LotSize, _Symbol, 0.0, NormalizeDouble(sl, digits), NormalizeDouble(tp, digits), "London breakout long");
  }
  else
  {
    trade.Sell(LotSize, _Symbol, 0.0, NormalizeDouble(sl, digits), NormalizeDouble(tp, digits), "London breakout short");
  }

  tradedToday = true;
}

int OnInit()
{
  atrHandle = iATR(_Symbol, PERIOD_CURRENT, AtrPeriod);
  if(atrHandle == INVALID_HANDLE)
  {
    return INIT_FAILED;
  }

  ResetRange(TimeCurrent());
  return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
  if(atrHandle != INVALID_HANDLE)
  {
    IndicatorRelease(atrHandle);
  }
}

void OnTick()
{
  if(!IsNewBar())
  {
    return;
  }

  datetime now = TimeCurrent();
  datetime today = DayAnchor(now);

  if(today != rangeDay)
  {
    ResetRange(now);
  }

  if((int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPoints)
  {
    return;
  }

  if(InRangeWindow(now))
  {
    UpdateRange();
    return;
  }

  if(!rangeReady && RangeWindowFinished(now) && rangeHigh > 0.0 && rangeLow > 0.0)
  {
    rangeReady = true;
  }

  if(!rangeReady || tradedToday || HasManagedPosition())
  {
    return;
  }

  double atrValues[2];
  if(CopyBuffer(atrHandle, 0, 0, 2, atrValues) < 2)
  {
    return;
  }

  double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

  if(closePrice > rangeHigh)
  {
    OpenBreakoutTrade(ORDER_TYPE_BUY, atrValues[0]);
  }
  else if(closePrice < rangeLow)
  {
    OpenBreakoutTrade(ORDER_TYPE_SELL, atrValues[0]);
  }
}
