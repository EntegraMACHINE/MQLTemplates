#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "\..\..\Experts\Templates\PremiumDiscount.mqh"
CPremiumDiscount PremiumDiscount;

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

struct Swing
{
   datetime SwingTime;
   double SwingValue;
   double SwingBound;
   ENUM_SWING_TYPE SwingType;
   ENUM_SWING_SUBTYPE SwingSubtype;
   string SwingLabel;
   
   bool IsBroken;
   string BOSLine;
   
   Swing(){}
   
   Swing(datetime time, double value, double bound, ENUM_SWING_TYPE type, ENUM_SWING_SUBTYPE subtype, string label)
   {
      SwingTime = time;
      SwingValue = value;
      SwingBound = bound;
      SwingType = type;
      SwingSubtype = subtype;
      SwingLabel = label;
      IsBroken = false;
   }
};

struct IndexData
{
   datetime Time;
   double PrevHigh;
   double CurrHigh;
   double NextHigh;
   double PrevLow;
   double CurrLow;
   double NextLow;
   double PrevMax;
   double CurrMax;
   double NextMax;
   double PrevMin;
   double CurrMin;
   double NextMin;
};

datetime _lastBarTime = -1;
ENUM_SWING_TYPE _lastSwingType = SWING_NONE;
bool _isFirstCalculation = true;

Swing _tempHighs[];
Swing _tempLows[];
Swing _swingsArray[];

int OnInit()
{
   _isFirstCalculation = true;
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
      
      int limit = _isFirstCalculation ? iBars(Symbol(), PERIOD_CURRENT) - 2 : 2;     
      for(int i = limit; i >= 2; i--)
      {
         IndexData data = GetIndexData(i);
         if(IsSwingHigh(data)) 
         {
            bool isOutOfBounds = ArraySize(_swingsArray) - 1 < 0 ? true : (data.CurrHigh > _swingsArray[ArraySize(_swingsArray) - 1].SwingBound);
            if(isOutOfBounds)
            {
               if(_lastSwingType == SWING_NONE || _lastSwingType == SWING_LOW) 
               {
                  ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 2 < 0 ? SWING_HH : (data.CurrHigh > _swingsArray[ArraySize(_swingsArray) - 2].SwingValue ? SWING_HH : SWING_LH);
                  
                  if(IsAllowedBySwingSpace(i, data.CurrHigh))
                  {
                     string label = DrawSwingLabel("High-", subtype, data.Time, data.CurrHigh, ANCHOR_LOWER, 10, "Britannic Bold", clrOrange);
                     ArrayAdd(_swingsArray, Swing(data.Time, data.CurrHigh, data.CurrLow, SWING_HIGH, subtype, label));
                     
                     if(ArraySize(_swingsArray) - 2 >= 0 && _swingsArray[ArraySize(_swingsArray) - 2].SwingSubtype == SWING_HL && _swingsArray[ArraySize(_swingsArray) - 1].SwingSubtype == SWING_HH) 
                        PremiumDiscount.Update(
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingTime,
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingValue,
                           _swingsArray[ArraySize(_swingsArray) - 1].SwingValue);               
                     else PremiumDiscount.Delete();
                           
                     _lastSwingType = SWING_HIGH;
                  }
               }
               else if(_lastSwingType == SWING_HIGH && data.CurrHigh > _swingsArray[ArraySize(_swingsArray) - 1].SwingValue)
               {
                  ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 3 < 0 ? SWING_HH : (data.CurrHigh > _swingsArray[ArraySize(_swingsArray) - 3].SwingValue ? SWING_HH : SWING_LH);
                  
                  if(IsAllowedBySwingSpace(i, data.CurrHigh))
                  {
                     ObjectDelete(ChartID(), _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel);
                     string label = DrawSwingLabel("High-", subtype, data.Time, data.CurrHigh, ANCHOR_LOWER, 10, "Britannic Bold", clrOrange);
                     
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingTime = data.Time;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingValue = data.CurrHigh;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingBound = data.CurrLow;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingSubtype = subtype;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel = label;
                     
                     if(ArraySize(_swingsArray) - 2 >= 0 && _swingsArray[ArraySize(_swingsArray) - 2].SwingSubtype == SWING_HL && _swingsArray[ArraySize(_swingsArray) - 1].SwingSubtype == SWING_HH) 
                        PremiumDiscount.Update(
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingTime,
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingValue,
                           _swingsArray[ArraySize(_swingsArray) - 1].SwingValue);               
                     else PremiumDiscount.Delete();
                     
                     _lastSwingType = SWING_HIGH;
                  }
               }
            }
         }
         if(IsSwingLow(data)) 
         {
            bool isOutOfBounds = ArraySize(_swingsArray) - 1 < 0 ? true : (data.CurrLow < _swingsArray[ArraySize(_swingsArray) - 1].SwingBound);
            if(isOutOfBounds)
            {
               if(_lastSwingType == SWING_NONE || _lastSwingType == SWING_HIGH) 
               {
                  ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 2 < 0 ? SWING_LL : (data.CurrLow < _swingsArray[ArraySize(_swingsArray) - 2].SwingValue ? SWING_LL : SWING_HL);
                     
                  if(IsAllowedBySwingSpace(i, data.CurrLow))
                  {
                     string label = DrawSwingLabel("Low-", subtype, data.Time, data.CurrLow, ANCHOR_UPPER, 10, "Britannic Bold", clrOrange);
                     ArrayAdd(_swingsArray, Swing(data.Time, data.CurrLow, data.CurrHigh, SWING_LOW, subtype, label));
                     
                     if(ArraySize(_swingsArray) - 2 >= 0 && _swingsArray[ArraySize(_swingsArray) - 2].SwingSubtype == SWING_LH && _swingsArray[ArraySize(_swingsArray) - 1].SwingSubtype == SWING_LL) 
                        PremiumDiscount.Update(
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingTime,
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingValue,
                           _swingsArray[ArraySize(_swingsArray) - 1].SwingValue);               
                     else PremiumDiscount.Delete();
                        
                     _lastSwingType = SWING_LOW;
                  }
               }
               else if(_lastSwingType == SWING_LOW && data.CurrLow < _swingsArray[ArraySize(_swingsArray) - 1].SwingValue)
               {
                  ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 3 < 0 ? SWING_LL : (data.CurrLow < _swingsArray[ArraySize(_swingsArray) - 3].SwingValue ? SWING_LL : SWING_HL);
                     
                  if(IsAllowedBySwingSpace(i, data.CurrLow))
                  {
                     ObjectDelete(ChartID(), _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel);
                     string label = DrawSwingLabel("Low-", subtype, data.Time, data.CurrLow, ANCHOR_UPPER, 10, "Britannic Bold", clrOrange);
                     
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingTime = data.Time;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingValue = data.CurrLow;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingBound = data.CurrHigh;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingSubtype = subtype;
                     _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel = label;
                     
                     if(ArraySize(_swingsArray) - 2 >= 0 && _swingsArray[ArraySize(_swingsArray) - 2].SwingSubtype == SWING_LH && _swingsArray[ArraySize(_swingsArray) - 1].SwingSubtype == SWING_LL) 
                        PremiumDiscount.Update(
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingTime,
                           _swingsArray[ArraySize(_swingsArray) - 2].SwingValue,
                           _swingsArray[ArraySize(_swingsArray) - 1].SwingValue);               
                     else PremiumDiscount.Delete();
                                          
                     _lastSwingType = SWING_LOW;
                  }
               }
            }
         }
      }
      
      _isFirstCalculation = false;
      _lastBarTime = currBarTime;
   }
}

bool IsAllowedBySwingSpace(int index, double value)
{
   int endIndex = index + 3 > iBars(Symbol(), PERIOD_CURRENT) - 1 ? iBars(Symbol(), PERIOD_CURRENT) - 1 : index + 10;
   for(int i = index + 1; i <= endIndex; i++)
   {
      double high = iHigh(Symbol(), PERIOD_CURRENT, i);
      double low = iLow(Symbol(), PERIOD_CURRENT, i);
      if(high > value && low < value) return false;
   }
   
   return true;
}

bool IsSwingHigh(IndexData &data)
{
   return (data.PrevHigh < data.CurrHigh && data.CurrHigh > data.NextHigh) ||
          ((data.PrevHigh == data.CurrHigh || data.CurrHigh == data.NextHigh) && data.PrevMax < data.CurrMax && data.CurrMax > data.NextMax) ||
          ((data.PrevHigh == data.CurrHigh || data.CurrHigh == data.NextHigh) && (data.PrevMax == data.CurrMax || data.CurrMax == data.NextMax) && data.PrevMin < data.CurrMin && data.CurrMin > data.NextMin);
}

bool IsSwingLow(IndexData &data)
{
   return (data.PrevLow > data.CurrLow && data.CurrLow < data.NextLow) ||
          ((data.PrevLow == data.CurrLow || data.CurrLow == data.NextLow) && data.PrevMin > data.CurrMin && data.CurrMin < data.NextMin) ||
          ((data.PrevLow == data.CurrLow || data.CurrLow == data.NextLow) && (data.PrevMin == data.CurrMin || data.CurrMin == data.NextMin) && data.PrevMax > data.CurrMax && data.CurrMax < data.NextMax);
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

IndexData GetIndexData(int index)
{
   IndexData data;
   data.Time = iTime(Symbol(), PERIOD_CURRENT, index);
   data.PrevHigh = iHigh(Symbol(), PERIOD_CURRENT, index + 1);
   data.CurrHigh = iHigh(Symbol(), PERIOD_CURRENT, index);
   data.NextHigh = iHigh(Symbol(), PERIOD_CURRENT, index - 1);
   data.PrevLow = iLow(Symbol(), PERIOD_CURRENT, index + 1);
   data.CurrLow = iLow(Symbol(), PERIOD_CURRENT, index);
   data.NextLow = iLow(Symbol(), PERIOD_CURRENT, index - 1);
   data.PrevMax = MathMax(iOpen(Symbol(), PERIOD_CURRENT, index + 1), iClose(Symbol(), PERIOD_CURRENT, index + 1));
   data.CurrMax = MathMax(iOpen(Symbol(), PERIOD_CURRENT, index), iClose(Symbol(), PERIOD_CURRENT, index));
   data.NextMax = MathMax(iOpen(Symbol(), PERIOD_CURRENT, index - 1), iClose(Symbol(), PERIOD_CURRENT, index - 1));
   data.PrevMin = MathMin(iOpen(Symbol(), PERIOD_CURRENT, index + 1), iClose(Symbol(), PERIOD_CURRENT, index + 1));
   data.CurrMin = MathMin(iOpen(Symbol(), PERIOD_CURRENT, index), iClose(Symbol(), PERIOD_CURRENT, index));
   data.NextMin = MathMin(iOpen(Symbol(), PERIOD_CURRENT, index - 1), iClose(Symbol(), PERIOD_CURRENT, index - 1));
   return data;
}

template <typename T> void ArrayAdd(T &array[], T &value)
{
   int size = ArrayResize(array, ArraySize(array) + 1);
   if (size != -1) array[size - 1] = value;
}