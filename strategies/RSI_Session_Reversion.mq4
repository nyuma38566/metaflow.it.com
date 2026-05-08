#property strict

extern int RsiPeriod = 14;
extern double OversoldLevel = 28.0;
extern double OverboughtLevel = 72.0;
extern double Lots = 0.10;
extern int StopLossPoints = 450;
extern int TakeProfitPoints = 700;
extern int MaxSpreadPoints = 35;
extern int StartHour = 7;
extern int EndHour = 20;
extern int Slippage = 5;
extern int MagicNumber = 2026050802;

bool IsNewBar()
{
  static datetime lastBarTime = 0;
  if(Time[0] == lastBarTime)
  {
    return false;
  }

  lastBarTime = Time[0];
  return true;
}

bool InSession()
{
  int currentHour = TimeHour(TimeCurrent());
  return currentHour >= StartHour && currentHour < EndHour;
}

bool HasOpenOrder()
{
  for(int i = OrdersTotal() - 1; i >= 0; i--)
  {
    if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }

    if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
    {
      return true;
    }
  }

  return false;
}

void OpenBuy()
{
  RefreshRates();
  double point = MarketInfo(Symbol(), MODE_POINT);
  int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
  double ask = NormalizeDouble(Ask, digits);
  double sl = NormalizeDouble(ask - StopLossPoints * point, digits);
  double tp = NormalizeDouble(ask + TakeProfitPoints * point, digits);

  OrderSend(Symbol(), OP_BUY, Lots, ask, Slippage, sl, tp, "RSI reversion buy", MagicNumber, 0, clrBlue);
}

void OpenSell()
{
  RefreshRates();
  double point = MarketInfo(Symbol(), MODE_POINT);
  int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
  double bid = NormalizeDouble(Bid, digits);
  double sl = NormalizeDouble(bid + StopLossPoints * point, digits);
  double tp = NormalizeDouble(bid - TakeProfitPoints * point, digits);

  OrderSend(Symbol(), OP_SELL, Lots, bid, Slippage, sl, tp, "RSI reversion sell", MagicNumber, 0, clrRed);
}

int start()
{
  if(!IsNewBar())
  {
    return 0;
  }

  if(!InSession())
  {
    return 0;
  }

  if((int)MarketInfo(Symbol(), MODE_SPREAD) > MaxSpreadPoints)
  {
    return 0;
  }

  if(HasOpenOrder())
  {
    return 0;
  }

  double currentRsi = iRSI(Symbol(), 0, RsiPeriod, PRICE_CLOSE, 0);
  double previousRsi = iRSI(Symbol(), 0, RsiPeriod, PRICE_CLOSE, 1);

  if(previousRsi < OversoldLevel && currentRsi > OversoldLevel)
  {
    OpenBuy();
  }

  if(previousRsi > OverboughtLevel && currentRsi < OverboughtLevel)
  {
    OpenSell();
  }

  return 0;
}
