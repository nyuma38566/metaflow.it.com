#property strict

#include <Trade/Trade.mqh>

input int FastMAPeriod = 21;
input int SlowMAPeriod = 55;
input int AtrPeriod = 14;
input double LotSize = 0.10;
input double StopAtrMultiplier = 2.0;
input double TakeAtrMultiplier = 3.2;
input int MaxSpreadPoints = 35;
input ulong MagicNumber = 2026050801;

CTrade trade;
int fastHandle = INVALID_HANDLE;
int slowHandle = INVALID_HANDLE;
int atrHandle = INVALID_HANDLE;

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

bool HasOpenPosition(long &positionType)
{
  if(!PositionSelect(_Symbol))
  {
    positionType = -1;
    return false;
  }

  if((ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
  {
    positionType = -1;
    return false;
  }

  positionType = PositionGetInteger(POSITION_TYPE);
  return true;
}

void CloseCurrentPosition()
{
  if(PositionSelect(_Symbol) && (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
  {
    trade.PositionClose(_Symbol);
  }
}

void OpenTrade(ENUM_ORDER_TYPE orderType, double atrValue)
{
  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
  int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

  double price = orderType == ORDER_TYPE_BUY ? ask : bid;
  double stopDistance = atrValue * StopAtrMultiplier;
  double takeDistance = atrValue * TakeAtrMultiplier;

  double sl = orderType == ORDER_TYPE_BUY ? price - stopDistance : price + stopDistance;
  double tp = orderType == ORDER_TYPE_BUY ? price + takeDistance : price - takeDistance;

  sl = NormalizeDouble(sl, digits);
  tp = NormalizeDouble(tp, digits);

  trade.SetExpertMagicNumber(MagicNumber);

  if(orderType == ORDER_TYPE_BUY)
  {
    trade.Buy(LotSize, _Symbol, 0.0, sl, tp, "EMA ATR long");
  }
  else
  {
    trade.Sell(LotSize, _Symbol, 0.0, sl, tp, "EMA ATR short");
  }
}

int OnInit()
{
  fastHandle = iMA(_Symbol, PERIOD_CURRENT, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
  slowHandle = iMA(_Symbol, PERIOD_CURRENT, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
  atrHandle = iATR(_Symbol, PERIOD_CURRENT, AtrPeriod);

  if(fastHandle == INVALID_HANDLE || slowHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
  {
    return INIT_FAILED;
  }

  return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
  if(fastHandle != INVALID_HANDLE)
  {
    IndicatorRelease(fastHandle);
  }

  if(slowHandle != INVALID_HANDLE)
  {
    IndicatorRelease(slowHandle);
  }

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

  if((int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPoints)
  {
    return;
  }

  double fastValues[3];
  double slowValues[3];
  double atrValues[2];

  if(CopyBuffer(fastHandle, 0, 0, 3, fastValues) < 3)
  {
    return;
  }

  if(CopyBuffer(slowHandle, 0, 0, 3, slowValues) < 3)
  {
    return;
  }

  if(CopyBuffer(atrHandle, 0, 0, 2, atrValues) < 2)
  {
    return;
  }

  bool crossedUp = fastValues[1] <= slowValues[1] && fastValues[0] > slowValues[0];
  bool crossedDown = fastValues[1] >= slowValues[1] && fastValues[0] < slowValues[0];

  long currentType = -1;
  bool hasPosition = HasOpenPosition(currentType);

  if(crossedUp)
  {
    if(hasPosition && currentType == POSITION_TYPE_SELL)
    {
      CloseCurrentPosition();
      hasPosition = false;
    }

    if(!hasPosition)
    {
      OpenTrade(ORDER_TYPE_BUY, atrValues[0]);
    }
  }

  if(crossedDown)
  {
    if(hasPosition && currentType == POSITION_TYPE_BUY)
    {
      CloseCurrentPosition();
      hasPosition = false;
    }

    if(!hasPosition)
    {
      OpenTrade(ORDER_TYPE_SELL, atrValues[0]);
    }
  }
}
