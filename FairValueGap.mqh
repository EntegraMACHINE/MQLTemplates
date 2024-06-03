#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"

const string FillPrefix = "FairValueGapFill-";
const string BorderPrefix = "FairValueGapBorder-";

struct FVGData
{
   datetime StartTime;
   double TopValue;
   double BotValue;
   string FillRectangle;
   string BorderRectangle;
   
   FVGData(){}
   
   FVGData(datetime time, double top, double bot, string fillrect, string borderrect)
   {
      StartTime = time;
      TopValue = top;
      BotValue = bot;
      FillRectangle = fillrect;
      BorderRectangle = borderrect;
   }
};

class CFairValueGap
{
   public: void Define(datetime time1, double price1, datetime time2, double price2, ENUM_TIMEFRAMES period)
   {
      int startIndex = iBarShift(Symbol(), period, time1);
      int endIndex = iBarShift(Symbol(), period, time2);
      
      double upperPrice = MathMax(price1, price2);
      double lowerPrice = MathMin(price1, price2);
      double midPrice = lowerPrice + (upperPrice - lowerPrice) / 2;
      
      FVGData fvgs[];
      for(int i = startIndex; i >= endIndex; i--)
      {
         if(price1 < price2 && IsBullFVG(i, midPrice, period)) 
         {
            double prevHigh = iHigh(Symbol(), period, i + 1);
            double nextLow = iLow(Symbol(), period, i - 1);
            datetime time = iTime(Symbol(), period, i);
            DrawFVGRectangle(time, nextLow, time + PeriodSeconds(period) * (period == PERIOD_M15 ? 20 : 5), prevHigh, (period == PERIOD_M15 ? clrGray : clrDeepSkyBlue), clrPaleTurquoise, period);
            ArrayAdd(fvgs, FVGData(iTime(Symbol(), period, i), nextLow, prevHigh, "", ""));
         }
         if(price1 > price2 && IsBearFVG(i, midPrice, period)) 
         {
            double prevLow = iLow(Symbol(), period, i + 1);
            double nextHigh = iHigh(Symbol(), period, i - 1);
            datetime time = iTime(Symbol(), period, i);
            DrawFVGRectangle(time, prevLow, time + PeriodSeconds(period) * (period == PERIOD_M15 ? 20 : 5), nextHigh, (period == PERIOD_M15 ? clrGray : clrDeepSkyBlue), clrPaleTurquoise, period);
            ArrayAdd(fvgs, FVGData(iTime(Symbol(), period, i), prevLow, nextHigh, "", ""));
         }
      }
      
      //FVGData validFVG = GetHighestFVG(fvgs);
      //DrawFVGRectangle(validFVG.StartTime, validFVG.TopValue, validFVG.StartTime + PeriodSeconds(period) * (period == PERIOD_M15 ? 20 : 5), validFVG.BotValue, (period == PERIOD_M15 ? clrGray : clrDeepSkyBlue), clrPaleTurquoise, period);
   }
   
   private: FVGData GetHighestFVG(FVGData &array[])
   {
      double height = INT_MIN;
      FVGData result;
      for(int i = 0; i < ArraySize(array); i++)
      {
         if(MathAbs(array[i].TopValue - array[i].BotValue) > height)
         {
            result = array[i];
            height = MathAbs(array[i].TopValue - array[i].BotValue);
         }
      }
      
      return result;
   }

   private: bool IsBullFVG(int index, double threshold, ENUM_TIMEFRAMES period)
   {
      double prevHigh = iHigh(Symbol(), period, index + 1);
      double nextLow = iLow(Symbol(), period, index - 1);
      
      return nextLow > prevHigh /*&& nextLow <= threshold*/ && (nextLow - prevHigh) / Point() > 35;
   }
   
   private: bool IsBearFVG(int index, double threshold, ENUM_TIMEFRAMES period)
   {
      double prevLow = iLow(Symbol(), period, index + 1);
      double nextHigh = iHigh(Symbol(), period, index - 1);
      
      return prevLow > nextHigh /*&& nextHigh >= threshold*/ && (prevLow - nextHigh) / Point() > 35;
   }
   
   private: void DrawFVGRectangle(datetime time1, double price1, datetime time2, double price2, color fillcolor, color bordercolor, ENUM_TIMEFRAMES period)
   {
      string fillName = FillPrefix + TimeToString(time1);
      DrawRectangle(fillName, time1, price1, time2, price2, fillcolor, 1, true);
      
      string borderName = BorderPrefix + TimeToString(time1);
      DrawRectangle(borderName, time1, price1, time2, price2, bordercolor, 2, false);
      
      string textName = "FVG Text-" + TimeToString(time1);
      double price = MathMin(price1, price2) + MathAbs(price1 - price2) / 2;
      datetime time = time1 + (time2 - time1) / 2;
      ObjectCreate(ChartID(), textName, OBJ_TEXT, 0, time, price);
      ObjectSetInteger(ChartID(), textName, OBJPROP_COLOR, bordercolor);
      ObjectSetString(ChartID(), textName, OBJPROP_FONT, "Britannic Bold");
      ObjectSetInteger(ChartID(), textName, OBJPROP_FONTSIZE, (period == PERIOD_M15 ? 8 : 14));
      ObjectSetInteger(ChartID(), textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetString(ChartID(), textName, OBJPROP_TEXT, GetFVGText(period));
   }
   
   private: void DrawRectangle(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, bool fill)
   {
      ObjectCreate(ChartID(), name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
      ObjectSetInteger(ChartID(), name, OBJPROP_FILL, fill);
      ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, width);
      ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
   }
   
   private: string GetFVGText(ENUM_TIMEFRAMES period)
   {
      return TimeframeToString(period) + " FVG";
   }
   
   private: string TimeframeToString(ENUM_TIMEFRAMES period)
   {
      if(period == PERIOD_CURRENT) period = (ENUM_TIMEFRAMES)Period();
   
      switch(period)
         {
         case PERIOD_M1:
            return("1M");
         case PERIOD_M2:
            return("2M");
         case PERIOD_M3:
            return("3M");
         case PERIOD_M4:
            return("4M");
         case PERIOD_M5:
            return("5M");
         case PERIOD_M6:
            return("6M");
         case PERIOD_M10:
            return("10M");
         case PERIOD_M12:
            return("12M");
         case PERIOD_M15:
            return("15M");
         case PERIOD_M20:
            return("20M");
         case PERIOD_M30:
            return("30M");
         case PERIOD_H1:
            return("1H");
         case PERIOD_H2:
            return("2H");
         case PERIOD_H3:
            return("3H");
         case PERIOD_H4:
            return("4H");
         case PERIOD_H6:
            return("6H");
         case PERIOD_H8:
            return("8H");
         case PERIOD_H12:
            return("12H");
         case PERIOD_D1:
            return("Daily");
         case PERIOD_W1:
            return("Weekly");
         case PERIOD_MN1:
            return("Monthly");
      }
      
      return("Unknown timeframe");
   }
   
   private: template <typename T> void ArrayAdd(T &array[], T &value)
   {
      int size = ArrayResize(array, ArraySize(array) + 1);
      if (size != -1) array[size - 1] = value;
   }
};