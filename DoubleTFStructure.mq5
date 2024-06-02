#property copyright "Entegra_MACHINE"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

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

// Inputs ////////////////////////////////////////////////////////////////////////////////////////////////////////
input int BarsBack = 1000; // Bars Back
input color HTFSwingLabelColor = clrDeepPink; // HTF Swing Label Color
input color LTFSwingLabelColor = clrDeepSkyBlue; // LTF Swing Label Color
input color HTFBOSLineColor = clrOrange; // HTF BOS Line Color
input color LTFBOSLineColor = clrTurquoise; // LTF BOS Line Color

input ENUM_TIMEFRAMES HTFTimeframe = PERIOD_H4;  // Structure Major Timeframe
input ENUM_TIMEFRAMES LTFTimeframe = PERIOD_M15; // Structure Minor Timeframe
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// HTF Struct Data ///////////////////////////////////////////////////////////////////////////////////////////////
Swing _tempHTFHighsArray[];
Swing _tempHTFLowsArray[];

Swing _significantHTFHighsArray[];
Swing _significantHTFLowsArray[];

datetime _lastHTFBarTime = -1;
ENUM_SWING_TYPE _lastTempHTFSwingType = SWING_NONE;
ENUM_SWING_TYPE _lastSignificantHTFSwingType = SWING_NONE;
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// LTF Struct Data ///////////////////////////////////////////////////////////////////////////////////////////////
Swing _tempLTFHighsArray[];
Swing _tempLTFLowsArray[];

Swing _significantLTFHighsArray[];
Swing _significantLTFLowsArray[];

datetime _lastLTFBarTime = -1;
ENUM_SWING_TYPE _lastTempLTFSwingType = SWING_NONE;
ENUM_SWING_TYPE _lastSignificantLTFSwingType = SWING_NONE;
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////


bool _isFirstCalculation = true;

int OnInit()
{
   ChartSetSymbolPeriod(ChartID(), Symbol(), LTFTimeframe);
   
   _isFirstCalculation = true;
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   
}

void OnTick()
{
   if(_lastLTFBarTime != iTime(Symbol(), PERIOD_CURRENT, 0))
   {
      int limit = _isFirstCalculation ? iBars(Symbol(), PERIOD_CURRENT) - 2 : 2;
      for(int i = limit; i >= 2; i--)
      {
         datetime currHTFTime = iTime(Symbol(), HTFTimeframe, i);
         if(_lastHTFBarTime != currHTFTime)
         {
            if(IsSwingHigh(i, HTFTimeframe)) OnSwingHigh(i, _lastTempHTFSwingType, _lastSignificantHTFSwingType, _tempHTFHighsArray, _significantHTFHighsArray, HTFTimeframe);
            if(IsSwingLow(i, HTFTimeframe)) OnSwingLow(i, _lastTempHTFSwingType, _lastSignificantHTFSwingType, _tempHTFLowsArray, _significantHTFLowsArray, HTFTimeframe);
         
            _lastHTFBarTime = currHTFTime;
         }
         
         if(IsSwingHigh(i, PERIOD_CURRENT)) OnSwingHigh(i, _lastTempLTFSwingType, _lastSignificantLTFSwingType, _tempLTFHighsArray, _significantLTFHighsArray, PERIOD_CURRENT);
         if(IsSwingLow(i, PERIOD_CURRENT)) OnSwingLow(i, _lastTempLTFSwingType, _lastSignificantLTFSwingType, _tempLTFLowsArray, _significantLTFLowsArray, PERIOD_CURRENT);
      }
   
      _isFirstCalculation = false;
      _lastLTFBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
   }
}

void OnSwingHigh(int i, ENUM_SWING_TYPE &lasttemptype, ENUM_SWING_TYPE &lastsignificanttype, Swing &temparray[], Swing &significantarray[], ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
   double value = iHigh(Symbol(), period, i);
   datetime time = iTime(Symbol(), period, i);
   datetime currTFTime = HTFValueToLTFTime(value, time, HTFTimeframe, SWING_HIGH);
   ENUM_SWING_SUBTYPE subtype = SWING_DB;
   
   if(lasttemptype == SWING_NONE || lasttemptype == SWING_LOW)
   {
      subtype = GetSwingHighSubtype(value, temparray);
      ArrayAdd(temparray, Swing(currTFTime, value, SWING_HIGH, subtype, ""));
   }
   else if(lasttemptype == SWING_HIGH && value > temparray[ArraySize(temparray) - 1].SwingValue)
   {      
      subtype = GetSwingHighSubtype(value, temparray, 2);        
      UpdateSwingData(value, currTFTime, subtype, "", temparray);
   }
   
   if(subtype == SWING_HH)
   {
      ENUM_SWING_SUBTYPE significantSubtype = SWING_DB;
      if(lastsignificanttype == SWING_NONE || lastsignificanttype == SWING_LOW)
      {
         significantSubtype = GetSwingHighSubtype(value, significantarray);
         string label = DrawSwingLabel(GetSwingPrefix(period), significantSubtype, currTFTime, value, ANCHOR_LOWER, GetSwingFontSize(period), GetSwingFont(period), GetSwingColor(period));
         ArrayAdd(significantarray, Swing(currTFTime, value, SWING_HIGH, significantSubtype, label));
      }
      else if(lastsignificanttype == SWING_HIGH && value > significantarray[ArraySize(significantarray) - 1].SwingValue)
      {  
         significantSubtype = GetSwingHighSubtype(value, significantarray);
         ObjectDelete(ChartID(), significantarray[ArraySize(significantarray) - 1].SwingLabel);
         string label = DrawSwingLabel(GetSwingPrefix(period), significantSubtype, currTFTime, value, ANCHOR_LOWER, GetSwingFontSize(period), GetSwingFont(period), GetSwingColor(period));
         UpdateSwingData(value, currTFTime, significantSubtype, label, significantarray);
      }   
    
      if(significantSubtype == SWING_HH) DrawBOSLine(i, "HighBOS-", significantarray, (period == PERIOD_CURRENT ? LTFBOSLineColor : HTFBOSLineColor), STYLE_DOT);
      
      lastsignificanttype = SWING_HIGH;
   }
   
   lasttemptype = SWING_HIGH;
}

void OnSwingLow(int i, ENUM_SWING_TYPE &lasttemptype, ENUM_SWING_TYPE &lastsignificanttype, Swing &temparray[], Swing &significantarray[], ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
   double value = iLow(Symbol(), period, i);
   datetime time = iTime(Symbol(), period, i);
   datetime currTFTime = HTFValueToLTFTime(value, time, HTFTimeframe, SWING_LOW);
   ENUM_SWING_SUBTYPE subtype = SWING_DB;
   
   if(lasttemptype == SWING_NONE || lasttemptype == SWING_HIGH)
   {
      subtype = GetSwingLowSubtype(value, temparray);
      ArrayAdd(temparray, Swing(currTFTime, value, SWING_LOW, subtype, ""));
   }
   else if(lasttemptype == SWING_LOW && value < temparray[ArraySize(temparray) - 1].SwingValue)
   {      
      subtype = GetSwingLowSubtype(value, temparray, 2); 
      UpdateSwingData(value, currTFTime, subtype, "", temparray);
   }
   
   if(subtype == SWING_LL)
   {
      ENUM_SWING_SUBTYPE significantSubtype = SWING_DB;
      if(lastsignificanttype == SWING_NONE || lastsignificanttype == SWING_HIGH)
      {
         significantSubtype = GetSwingLowSubtype(value, significantarray);
         string label = DrawSwingLabel(GetSwingPrefix(period), significantSubtype, currTFTime, value, ANCHOR_UPPER, GetSwingFontSize(period), GetSwingFont(period), GetSwingColor(period));
         ArrayAdd(significantarray, Swing(currTFTime, value, SWING_LOW, significantSubtype, label));
      }
      else if(lastsignificanttype == SWING_LOW && value < significantarray[ArraySize(significantarray) - 1].SwingValue)
      {
         significantSubtype = GetSwingLowSubtype(value, significantarray, 2);
         ObjectDelete(ChartID(), significantarray[ArraySize(significantarray) - 1].SwingLabel);
         string label = DrawSwingLabel(GetSwingPrefix(period), significantSubtype, currTFTime, value, ANCHOR_UPPER, GetSwingFontSize(period), GetSwingFont(period), GetSwingColor(period));
         UpdateSwingData(value, currTFTime, significantSubtype, label, significantarray);
      }
    
      if(significantSubtype == SWING_LL) DrawBOSLine(i, "LowBOS-", significantarray, (period == PERIOD_CURRENT ? LTFBOSLineColor : HTFBOSLineColor), STYLE_DOT);
      
      lastsignificanttype = SWING_LOW;
   }
   
   lasttemptype = SWING_LOW;
}

void UpdateSwingData(double value, datetime time, ENUM_SWING_SUBTYPE subtype, string label, Swing &source[], int shift = 1)
{
   source[ArraySize(source) - shift].SwingValue = value;
   source[ArraySize(source) - shift].SwingTime = time;  
   source[ArraySize(source) - shift].SwingSubtype = subtype;
   source[ArraySize(source) - shift].SwingLabel = label;
}

bool DrawBOSLine(int i, string prefix, Swing &source[], color clr, ENUM_LINE_STYLE style, int shift = 2)
{
   if(ArraySize(source) - shift < 0) return false;
   if(source[ArraySize(source) - shift].IsBroken) return false;
   
   datetime startTime = source[ArraySize(source) - shift].SwingTime;
   datetime endTime = source[ArraySize(source) - (shift - 1)].SwingTime;
   double value =  source[ArraySize(source) - shift].SwingValue;
   datetime bosTime = GetBOSEndTime(value, startTime, endTime);
   
   if(endTime == -1) return false;

   string name = DrawTrendLine(prefix, value, startTime, bosTime, clr, style);     
   source[ArraySize(source) - shift].IsBroken = true;
   source[ArraySize(source) - shift].SwingBOSLine = name;
   
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
   string name = prefix + TimeToString(endtime);
   ObjectCreate(ChartID(), name, OBJ_TREND, 0, starttime, value, endtime, value);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
   ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, style);  
   
   return name;
}

datetime HTFValueToLTFTime(double value, datetime startTime, ENUM_TIMEFRAMES period, ENUM_SWING_TYPE type)
{
   datetime endTime = startTime + PeriodSeconds(period);
   int startIndex = iBarShift(Symbol(), PERIOD_CURRENT, startTime);
   int endIndex = iBarShift(Symbol(), PERIOD_CURRENT, endTime);

   for(int i = startIndex; i >= endIndex; i--)
   {
      double currTFValue = type == SWING_HIGH ? iHigh(Symbol(), PERIOD_CURRENT, i) : iLow(Symbol(), PERIOD_CURRENT, i);
      if(currTFValue == value) return iTime(Symbol(), PERIOD_CURRENT, i);
   }
   
   return startTime;
}

ENUM_SWING_SUBTYPE GetSwingHighSubtype(double value, Swing &source[], int shift = 1)
{
   if(ArraySize(source) - shift < 0) return SWING_HH;
   if(value > source[ArraySize(source) - shift].SwingValue) return SWING_HH;
   else return SWING_LH;
}

ENUM_SWING_SUBTYPE GetSwingLowSubtype(double value, Swing &source[], int shift = 1)
{
   if(ArraySize(source) - shift < 0) return SWING_LL;
   if(value < source[ArraySize(source) - shift].SwingValue) return SWING_LL;
   else return SWING_HL;
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

bool IsSwingHigh(int index, ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
   double prevHigh = iHigh(Symbol(), period, index + 1);
   double currHigh = iHigh(Symbol(), period, index);
   double nextHigh = iHigh(Symbol(), period, index - 1);
   
   return prevHigh < currHigh && currHigh > nextHigh;
}

bool IsSwingLow(int index, ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
   double prevLow = iLow(Symbol(), period, index + 1);
   double currLow = iLow(Symbol(), period, index);
   double nextLow = iLow(Symbol(), period, index - 1);
   
   return prevLow > currLow && currLow < nextLow;
}

bool IsBullFVG(int index, ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
   double prevHigh = iHigh(Symbol(), period, index + 1);
   double nextLow = iLow(Symbol(), period, index - 1);
   
   return nextLow > prevHigh;
}

bool IsBearFVG(int index, ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
   double prevLow = iLow(Symbol(), period, index + 1);
   double nextHigh = iHigh(Symbol(), period, index - 1);
   
   return prevLow > nextHigh;
}

void DrawFVGRectangle(datetime time1, double price1, datetime time2, double price2, color fillcolor, color bordercolor)
{
   string fillName = "FairValueGapFill-" + TimeToString(time1);
   DrawRectangle(fillName, time1, price1, time2, price2, fillcolor, 1, true);
   
   string borderName = "FairValueGapBorder-" + TimeToString(time1);
   DrawRectangle(borderName, time1, price1, time2, price2, bordercolor, 1, false);
}

void DrawRectangle(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, bool fill)
{
   ObjectCreate(ChartID(), name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   ObjectSetInteger(ChartID(), name, OBJPROP_FILL, fill);
   ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, width);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
}

string GetSwingPrefix(ENUM_TIMEFRAMES period)
{
   return period == PERIOD_CURRENT ? "LTF-" : "HTF-";
}

int GetSwingFontSize(ENUM_TIMEFRAMES period)
{
   return period == PERIOD_CURRENT ? 8 : 14;
}

string GetSwingFont(ENUM_TIMEFRAMES period)
{
   return period == PERIOD_CURRENT ? "Arial" : "Britannic Bold";
}

color GetSwingColor(ENUM_TIMEFRAMES period)
{
   return period == PERIOD_CURRENT ? LTFSwingLabelColor : HTFSwingLabelColor;
}

template <typename T> void ArrayAdd(T &array[], T &value)
{
   int size = ArrayResize(array, ArraySize(array) + 1);
   if (size != -1) array[size - 1] = value;
}