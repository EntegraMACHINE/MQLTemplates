#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "\..\..\Experts\Templates\PremiumDiscount.mqh"

CPremiumDiscount PremiumDiscount;

// Enums /////////////////////////////////////////////////////////////////////////////////////////////////////////
enum ENUM_SWING_TYPE
{
   SWING_NONE,
   SWING_HIGH,
   SWING_LOW
};

enum ENUM_SWING_SUBTYPE
{
   SWING_DB,
   SWING_HH,
   SWING_LH,
   SWING_LL,
   SWING_HL
};
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Structs ///////////////////////////////////////////////////////////////////////////////////////////////////////
struct Swing
{
   datetime SwingTime;
   double SwingValue;
   ENUM_SWING_TYPE SwingType;
   ENUM_SWING_SUBTYPE SwingSubtype;
   bool IsBroken;
   string SwingLabel;
   string SwingBOSLine;
   
   Swing(){}
   
   Swing(datetime time, double value, ENUM_SWING_TYPE type, ENUM_SWING_SUBTYPE subtype, string label)
   {
      SwingTime = time;
      SwingValue = value;
      SwingType = type;
      SwingSubtype = subtype;
      SwingLabel = label;
      IsBroken = false;
   }
};
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

input bool DrawLabels = true;
input bool DrawBOS = true;

Swing _tempHighsArray[];
Swing _tempLowsArray[];
Swing _swingsHighArray[];
Swing _swingsLowArray[];
ENUM_SWING_TYPE _lastTempSwingType = SWING_NONE;
ENUM_SWING_TYPE _lastMarketSwingType = SWING_NONE;

datetime _lastBarTime = -1;
bool _isFirstCalculation = true;

int OnInit()
{

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(ChartID());
}

void OnTick()
{
   datetime currBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
   if(_lastBarTime != currBarTime)
   {
      PremiumDiscount.Expand();
      
      int limit = _isFirstCalculation ? iBars(Symbol(), PERIOD_CURRENT) : 2;
      for(int i = limit; i >= 2; i--)
      {
         if(IsSwingHigh(i))
         {
            datetime time = iTime(Symbol(), PERIOD_CURRENT, i);
            double value = iHigh(Symbol(), PERIOD_CURRENT, i);
            ENUM_SWING_SUBTYPE subtype = SWING_DB;
            
            if(_lastTempSwingType == SWING_NONE || _lastTempSwingType == SWING_LOW)
            {
               subtype = ArraySize(_tempHighsArray) - 1 < 0 ? SWING_HH : (value > _tempHighsArray[ArraySize(_tempHighsArray) - 1].SwingValue ? SWING_HH : SWING_LH);
               ArrayAdd(_tempHighsArray, Swing(time, value, SWING_HIGH, subtype, ""));
            }
            else if(_lastTempSwingType == SWING_HIGH && value > _tempHighsArray[ArraySize(_tempHighsArray) - 1].SwingValue)
            {
               subtype = ArraySize(_tempHighsArray) - 2 < 0 ? SWING_HH : (value > _tempHighsArray[ArraySize(_tempHighsArray) - 2].SwingValue ? SWING_HH : SWING_LH);
               _tempHighsArray[ArraySize(_tempHighsArray) - 1].SwingTime = time;
               _tempHighsArray[ArraySize(_tempHighsArray) - 1].SwingValue = value;
            }
            
            if(subtype == SWING_HH)
            {
               ENUM_SWING_SUBTYPE marketSubtype = SWING_DB;
               if(_lastMarketSwingType == SWING_NONE || _lastMarketSwingType == SWING_LOW)
               {
                  marketSubtype = ArraySize(_swingsHighArray) - 1 < 0 ? SWING_HH : (value > _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingValue ? SWING_HH : SWING_LH);
                  string label = DrawLabels ? DrawSwingLabel("Swing-", marketSubtype, time, value, ANCHOR_LOWER, 8, "Arial", clrOrange) : "";
                  ArrayAdd(_swingsHighArray, Swing(time, value, SWING_HIGH, subtype, label));
               }
               else if(_lastMarketSwingType == SWING_HIGH && value > _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingValue)
               {
                  marketSubtype = ArraySize(_swingsHighArray) - 2 < 0 ? SWING_HH : (value > _swingsHighArray[ArraySize(_swingsHighArray) - 2].SwingValue ? SWING_HH : SWING_LH);
                  ObjectDelete(ChartID(), _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingLabel);
                  string label = DrawLabels ? DrawSwingLabel("Swing-", marketSubtype, time, value, ANCHOR_LOWER, 8, "Arial", clrOrange) : "";
                  _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingTime = time;
                  _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingValue = value;
                  _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingSubtype = marketSubtype;
                  _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingLabel = label;
               }
               
               if(ArraySize(_swingsLowArray) > 0 && ArraySize(_swingsLowArray) > 0) PremiumDiscount.Update(
                     _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingTime,
                     _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingValue,
                     _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingValue);
               if(marketSubtype == SWING_HH && DrawBOS) DrawBOSLine(i, "HighBOS-", clrRed, STYLE_DOT, _swingsHighArray);
               
               _lastMarketSwingType = SWING_HIGH;
            }
            
            _lastTempSwingType = SWING_HIGH;
         }
         if(IsSwingLow(i))
         {
            datetime time = iTime(Symbol(), PERIOD_CURRENT, i);
            double value = iLow(Symbol(), PERIOD_CURRENT, i);
            ENUM_SWING_SUBTYPE subtype = SWING_DB;
            
            if(_lastTempSwingType == SWING_NONE || _lastTempSwingType == SWING_HIGH)
            {
               subtype = ArraySize(_tempLowsArray) - 1 < 0 ? SWING_LL : (value < _tempLowsArray[ArraySize(_tempLowsArray) - 1].SwingValue ? SWING_LL : SWING_HL);
               ArrayAdd(_tempLowsArray, Swing(time, value, SWING_LOW, subtype, ""));
            }
            else if(_lastTempSwingType == SWING_LOW && value < _tempLowsArray[ArraySize(_tempLowsArray) - 1].SwingValue)
            {
               subtype = ArraySize(_tempLowsArray) - 2 < 0 ? SWING_LL : (value < _tempLowsArray[ArraySize(_tempLowsArray) - 2].SwingValue ? SWING_LL : SWING_HL);
               _tempLowsArray[ArraySize(_tempLowsArray) - 1].SwingTime = time;
               _tempLowsArray[ArraySize(_tempLowsArray) - 1].SwingValue = value;
            }
            
            if(subtype == SWING_LL)
            {
               ENUM_SWING_SUBTYPE marketSubtype = SWING_DB;
               if(_lastMarketSwingType == SWING_NONE || _lastMarketSwingType == SWING_HIGH)
               {
                  marketSubtype = ArraySize(_swingsLowArray) - 1 < 0 ? SWING_LL : (value < _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingValue ? SWING_LL : SWING_HL);
                  string label = DrawLabels ? DrawSwingLabel("Swing-", marketSubtype, time, value, ANCHOR_UPPER, 8, "Arial", clrOrange) : "";
                  ArrayAdd(_swingsLowArray, Swing(time, value, SWING_LOW, subtype, label));
               }
               else if(_lastMarketSwingType == SWING_LOW && value < _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingValue)
               {
                  marketSubtype = ArraySize(_swingsLowArray) - 2 < 0 ? SWING_LL : (value < _swingsLowArray[ArraySize(_swingsLowArray) - 2].SwingValue ? SWING_LL : SWING_HL);
                  ObjectDelete(ChartID(), _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingLabel);
                  string label = DrawLabels ? DrawSwingLabel("Swing-", marketSubtype, time, value, ANCHOR_UPPER, 8, "Arial", clrOrange) : "";
                  _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingTime = time;
                  _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingValue = value;
                  _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingSubtype = marketSubtype;
                  _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingLabel = label;
               }
               
               if(ArraySize(_swingsLowArray) > 0 && ArraySize(_swingsLowArray) > 0) PremiumDiscount.Update(
                     _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingTime,
                     _swingsHighArray[ArraySize(_swingsHighArray) - 1].SwingValue,
                     _swingsLowArray[ArraySize(_swingsLowArray) - 1].SwingValue);
               if(marketSubtype == SWING_LL && DrawBOS) DrawBOSLine(i, "LowBOS-", clrRed, STYLE_DOT, _swingsLowArray);
               
               _lastMarketSwingType = SWING_LOW;
            }
            
            _lastTempSwingType = SWING_LOW;
         }
      }
      
      _isFirstCalculation = false;
      _lastBarTime = currBarTime;
   }
}

bool DrawBOSLine(int i, string prefix, color clr, ENUM_LINE_STYLE style, Swing &source[])
{
   if(ArraySize(source) - 2 < 0) return false;
   if(source[ArraySize(source) - 2].IsBroken) return false;
   
   datetime startTime = source[ArraySize(source) - 2].SwingTime;
   datetime endTime = source[ArraySize(source) - 1].SwingTime;
   double value =  source[ArraySize(source) - 2].SwingValue;
   datetime bosTime = GetBOSEndTime(value, startTime, endTime);
   
   if(bosTime == -1) return false;

   string name = DrawTrendLine(prefix, value, startTime, bosTime, clr, style);     
   source[ArraySize(source) - 2].IsBroken = true;
   source[ArraySize(source) - 2].SwingBOSLine = name;
   
   return true;
}

datetime GetBOSEndTime(double value, datetime starttime, datetime endtime)
{
   datetime endTime = -1;
   int startIndex = iBarShift(Symbol(), PERIOD_CURRENT, starttime);
   int endIndex = iBarShift(Symbol(), PERIOD_CURRENT, endtime);
   for(int i = startIndex; i >= endIndex; i--)
   {
      double high = MathMax(iOpen(Symbol(), PERIOD_CURRENT, i), iClose(Symbol(), PERIOD_CURRENT, i));
      double low = MathMin(iOpen(Symbol(), PERIOD_CURRENT, i), iClose(Symbol(), PERIOD_CURRENT, i));
      if(high > value && low < value) 
      {
         endTime = iTime(Symbol(), PERIOD_CURRENT, i);
         break;
      }
   }
   
   return endTime;
}

string DrawTrendLine(string prefix, double value, datetime starttime, datetime endtime, color clr, ENUM_LINE_STYLE style)
{
   string name = prefix + TimeToString(starttime) + "-" + TimeToString(endtime);
   ObjectCreate(ChartID(), name, OBJ_TREND, 0, starttime, value, endtime, value);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
   ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, style);  
   
   return name;
}

string DrawSwingLabel(string prefix, ENUM_SWING_SUBTYPE subtype, datetime time, double value, ENUM_ANCHOR_POINT anchor, int fontsize, string font, color clr)
{
   string text = GetSwingLabelText(subtype);
   string name = prefix + text + TimeToString(time);
   ObjectCreate(ChartID(), name, OBJ_TEXT, 0, time, value);
   ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, anchor);
   ObjectSetString(ChartID(), name, OBJPROP_FONT, font);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
   ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(ChartID(), name, OBJPROP_TEXT, text);
   return name;
}

string GetSwingLabelText(ENUM_SWING_SUBTYPE subtype)
{
   if(subtype == SWING_HH) return "HH";
   if(subtype == SWING_LH) return "LH";
   if(subtype == SWING_LL) return "LL";
   if(subtype == SWING_HL) return "HL";
   
   return "DB";
}

bool IsSwingHigh(int index)
{
   double prevHigh = iHigh(Symbol(), PERIOD_CURRENT, index + 1);
   double currHigh = iHigh(Symbol(), PERIOD_CURRENT, index);
   double nextHigh = iHigh(Symbol(), PERIOD_CURRENT, index - 1);
   
   return prevHigh < currHigh && currHigh > nextHigh;
}

bool IsSwingLow(int index)
{
   double prevLow = iLow(Symbol(), PERIOD_CURRENT, index + 1);
   double currLow = iLow(Symbol(), PERIOD_CURRENT, index);
   double nextLow = iLow(Symbol(), PERIOD_CURRENT, index - 1);
   
   return prevLow > currLow && currLow < nextLow;
}


template <typename T> void ArrayAdd(T &array[], T &value)
{
   int size = ArrayResize(array, ArraySize(array) + 1);
   if (size != -1) array[size - 1] = value;
}