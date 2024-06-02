#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"

const string PremiumRectName = "PremiumRect";
const string DiscountRectName = "DiscountRect";
const string FibonacciName = "Fibonacci";     

class CPremiumDiscount
{
   public: void UpdatePremiumDiscount(datetime time1, double price1, double price2)
   {
      datetime time2 = TimeCurrent();
   
      ObjectDelete(ChartID(), FibonacciName);
      ObjectCreate(ChartID(), FibonacciName, OBJ_FIBO, 0, time1, price1, time2, price2);
   
      double upperPrice = MathMax(price1, price2);
      double lowerPrice = MathMin(price1, price2);
      double midPrice = lowerPrice + (upperPrice - lowerPrice) / 2;
      
      ObjectDelete(ChartID(), DiscountRectName);
      ObjectCreate(ChartID(), DiscountRectName, OBJ_RECTANGLE, 0, time1, upperPrice, time2, midPrice);
      ObjectSetInteger(ChartID(), DiscountRectName, OBJPROP_COLOR, clrTomato);
      ObjectSetInteger(ChartID(), DiscountRectName, OBJPROP_FILL, true);
      
      ObjectDelete(ChartID(), PremiumRectName);
      ObjectCreate(ChartID(), PremiumRectName, OBJ_RECTANGLE, 0, time1, midPrice, time2, lowerPrice);
      ObjectSetInteger(ChartID(), PremiumRectName, OBJPROP_COLOR, clrPaleGreen);
      ObjectSetInteger(ChartID(), PremiumRectName, OBJPROP_FILL, true);
      
      ChartRedraw();
   }
   
   public: void ExpandPremiumDiscount()
   {
      double fibPrice2 = ObjectGetDouble(ChartID(), FibonacciName, OBJPROP_PRICE, 1);
      double premPrice2 = ObjectGetDouble(ChartID(), PremiumRectName, OBJPROP_PRICE, 1);
      double discPrice2 = ObjectGetDouble(ChartID(), DiscountRectName, OBJPROP_PRICE, 1);
      ObjectMove(ChartID(), FibonacciName, 1, TimeCurrent(), fibPrice2);
      ObjectMove(ChartID(), PremiumRectName, 1, TimeCurrent(), premPrice2);
      ObjectMove(ChartID(), DiscountRectName, 1, TimeCurrent(), discPrice2);
   }
};