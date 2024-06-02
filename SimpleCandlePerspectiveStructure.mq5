#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"
#property version   "1.00"

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

Swing _swingsArray[];
ENUM_SWING_TYPE _lastSwingType = SWING_NONE;

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
      int limit = _isFirstCalculation ? iBars(Symbol(), PERIOD_CURRENT) : 2;
      for(int i = limit; i >= 2; i--)
      {
         if(IsSwingHigh(i))
         {
            datetime time = iTime(Symbol(), PERIOD_CURRENT, i);
            double value = iHigh(Symbol(), PERIOD_CURRENT, i);
            
            if(_lastSwingType == SWING_NONE || _lastSwingType == SWING_LOW)
            {
               ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 2 < 0 ? SWING_HH : (value > _swingsArray[ArraySize(_swingsArray) - 2].SwingValue ? SWING_HH : SWING_LH);
               string label = DrawLabels ? DrawSwingLabel("Swing-", subtype, time, value, ANCHOR_LOWER, 8, "Arial", clrOrange) : "";
               ArrayAdd(_swingsArray, Swing(time, value, SWING_HIGH, subtype, label));
               if(subtype == SWING_HH && DrawBOS) DrawBOSLine(i, "HighBOS-", clrRed, STYLE_DOT, 3);
            }
            else if(_lastSwingType == SWING_HIGH && value > _swingsArray[ArraySize(_swingsArray) - 1].SwingValue)
            {
               ObjectDelete(ChartID(), _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel);
               ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 3 < 0 ? SWING_HH : (value > _swingsArray[ArraySize(_swingsArray) - 3].SwingValue ? SWING_HH : SWING_LH);
               string label = DrawLabels ? DrawSwingLabel("Swing-", subtype, time, value, ANCHOR_LOWER, 8, "Arial", clrOrange) : "";
               _swingsArray[ArraySize(_swingsArray) - 1].SwingTime = time;
               _swingsArray[ArraySize(_swingsArray) - 1].SwingValue = value;
               _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel = label;
               if(subtype == SWING_HH && DrawBOS) DrawBOSLine(i, "HighBOS-", clrRed, STYLE_DOT, 3);
            }
            
            _lastSwingType = SWING_HIGH;
         }
         if(IsSwingLow(i))
         {
            datetime time = iTime(Symbol(), PERIOD_CURRENT, i);
            double value = iLow(Symbol(), PERIOD_CURRENT, i);
            
            if(_lastSwingType == SWING_NONE || _lastSwingType == SWING_HIGH)
            {
               ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 2 < 0 ? SWING_LL : (value < _swingsArray[ArraySize(_swingsArray) - 2].SwingValue ? SWING_LL : SWING_HL);
               string label = DrawLabels ? DrawSwingLabel("Swing-", subtype, time, value, ANCHOR_UPPER, 8, "Arial", clrOrange) : "";
               ArrayAdd(_swingsArray, Swing(time, value, SWING_LOW, subtype, label));
               if(subtype == SWING_LL && DrawBOS) DrawBOSLine(i, "LowBOS-", clrRed, STYLE_DOT, 3);
            }
            else if(_lastSwingType == SWING_LOW && value < _swingsArray[ArraySize(_swingsArray) - 1].SwingValue)
            {
               ObjectDelete(ChartID(), _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel);
               ENUM_SWING_SUBTYPE subtype = ArraySize(_swingsArray) - 3 < 0 ? SWING_LL : (value < _swingsArray[ArraySize(_swingsArray) - 3].SwingValue ? SWING_LL : SWING_HL);
               string label = DrawLabels ? DrawSwingLabel("Swing-", subtype, time, value, ANCHOR_UPPER, 8, "Arial", clrOrange) : "";
               _swingsArray[ArraySize(_swingsArray) - 1].SwingTime = time;
               _swingsArray[ArraySize(_swingsArray) - 1].SwingValue = value;
               _swingsArray[ArraySize(_swingsArray) - 1].SwingLabel = label;
               if(subtype == SWING_LL && DrawBOS) DrawBOSLine(i, "LowBOS-", clrRed, STYLE_DOT, 3);
            }
            
            _lastSwingType = SWING_LOW;
         }
      }
      
      _isFirstCalculation = false;
      _lastBarTime = currBarTime;
   }
}

bool DrawBOSLine(int i, string prefix, color clr, ENUM_LINE_STYLE style, int shift)
{
   if(ArraySize(_swingsArray) - shift < 0) return false;
   if(_swingsArray[ArraySize(_swingsArray) - shift].IsBroken) return false;
   
   datetime startTime = _swingsArray[ArraySize(_swingsArray) - shift].SwingTime;
   datetime endTime = _swingsArray[ArraySize(_swingsArray) - (shift - 2)].SwingTime;
   double value =  _swingsArray[ArraySize(_swingsArray) - shift].SwingValue;
   datetime bosTime = GetBOSEndTime(value, startTime, endTime);
   
   if(endTime == -1) return false;

   string name = DrawTrendLine(prefix, value, startTime, bosTime, clr, style);     
   _swingsArray[ArraySize(_swingsArray) - shift].IsBroken = true;
   _swingsArray[ArraySize(_swingsArray) - shift].SwingBOSLine = name;
   
   return true;
}

datetime GetBOSEndTime(double value, datetime starttime, datetime endtime)
{
   datetime endTime = -1;
   int startIndex = iBarShift(Symbol(), PERIOD_CURRENT, starttime);
   int endIndex = iBarShift(Symbol(), PERIOD_CURRENT, endtime);
   for(int i = startIndex; i >= endIndex; i--)
   {
      double high = iHigh(Symbol(), PERIOD_CURRENT, i);
      double low = iLow(Symbol(), PERIOD_CURRENT, i);
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
   string name = prefix + TimeToString(endtime);
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