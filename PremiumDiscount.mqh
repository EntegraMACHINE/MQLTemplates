#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"

const string PremiumRectName = "PremiumRect";
const string DiscountRectName = "DiscountRect";
const string FibonacciName = "Fibonacci";     

double Levels[10] = { 0, 0.5, 0.618, 0.786, 1 };
string LevelsDescription[13] = { "0", "50%", "61.8%", "78.6%", "100%" };

class CPremiumDiscount
{
   public: bool IsActive;

   protected: bool showBackground;
   protected: bool showFibonacci;
   
   public: CPremiumDiscount()
   {
      IsActive = false;
      showBackground = true;
      showFibonacci = true;
   }
   
   public: void ShowBackground(bool value)
   {
      showBackground = value;
   }
   
   public: void ShowFibonacci(bool value)
   {
      showFibonacci = value;
   }

   public: void Update(datetime time1, double price1, double price2)
   {
      datetime time2 = TimeCurrent();   
      double upperPrice = MathMax(price1, price2);
      double lowerPrice = MathMin(price1, price2);
      double midPrice = lowerPrice + (upperPrice - lowerPrice) / 2;

      if(showBackground)
      {
         DrawRectangle(DiscountRectName, time1, upperPrice, time2, midPrice, clrTomato);
         DrawRectangle(PremiumRectName, time1, midPrice, time2, lowerPrice, clrPaleGreen);
      }
      
      if(showFibonacci)
      {
         ObjectDelete(ChartID(), FibonacciName);
         ObjectCreate(ChartID(), FibonacciName, OBJ_FIBO, 0, time1, price1, time2, price2);
         ObjectSetInteger(ChartID(), FibonacciName, OBJPROP_LEVELS, ArraySize(Levels));  
         for(int i = 0; i < ArraySize(Levels); i++) 
         { 
            ObjectSetDouble(ChartID(), FibonacciName, OBJPROP_LEVELVALUE, i, Levels[i]); 
            ObjectSetString(ChartID(), FibonacciName, OBJPROP_LEVELTEXT, i, LevelsDescription[i]);
            ObjectSetInteger(ChartID(), FibonacciName, OBJPROP_LEVELSTYLE, i, STYLE_DOT);
         } 
      }
      
      IsActive = true;
      ChartRedraw();
   }
   
   public: void Delete()
   {
      ObjectDelete(ChartID(), FibonacciName);
      ObjectDelete(ChartID(), PremiumRectName);
      ObjectDelete(ChartID(), DiscountRectName);
      
      IsActive = false;
   }
   
   public: void Expand()
   {
      ExpandRectangle(FibonacciName);
      ExpandRectangle(DiscountRectName);
      ExpandRectangle(PremiumRectName);
   }
   
   private: void DrawRectangle(string name, datetime time1, double price1, datetime time2, double price2, color clr)
   {
      ObjectDelete(ChartID(), name);
      ObjectCreate(ChartID(), name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
      ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
      ObjectSetInteger(ChartID(), name, OBJPROP_FILL, true);
   }
   
   private: void ExpandRectangle(string name)
   {
      double price2 = ObjectGetDouble(ChartID(), name, OBJPROP_PRICE, 1);
      ObjectMove(ChartID(), name, 1, TimeCurrent(), price2);
   }
};