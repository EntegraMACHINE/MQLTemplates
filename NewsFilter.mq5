#property version   "1.00"
#property strict

const string NEWS_URL = "https://www.forexfactory.com/calendar";

const string JSON_LINK_START = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";
const string JSON_LINK_END = ">JSON</a>";

enum ENUM_NEWS_IMPACT
{
   IMPACT_ALL,
   IMPACT_HOLIDAY,
   IMPACT_LOW,
   IMPACT_MEDIUM,
   IMPACT_HIGH
};

struct News
{
   string Title;
   string Country;
   datetime Date;
   ENUM_NEWS_IMPACT Impact;
   string Forecast;
   string Previous;
   string Url;
};

input int MinutesBeforeNews = 15;
input int MinutesAfterNews = 5;

News news[];

int OnInit()
{   
   GetNewsArray(NEWS_URL, news, IMPACT_ALL);
   
   for(int i = 0; i < ArraySize(news); i++)
   {
      color clr = clrLightGray;
      if(news[i].Impact == IMPACT_LOW) clr = clrYellow;
      if(news[i].Impact == IMPACT_MEDIUM) clr = clrOrange;
      if(news[i].Impact == IMPACT_HIGH) clr = clrRed;
      
      ObjectCreate(ChartID(), "News-" + TimeToString(news[i].Date), OBJ_EVENT, 0, news[i].Date, 0);
      ObjectSetString(ChartID(), "News-" + TimeToString(news[i].Date), OBJPROP_TEXT, news[i].Title + ". Impact: " + EnumImpactToString(news[i].Impact));
      ObjectSetInteger(ChartID(), "News-" + TimeToString(news[i].Date), OBJPROP_COLOR, clr);
   }
   
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   UpdateNewsArray(NEWS_URL, 60, news, IMPACT_ALL);
   
   if(IsTradeAllowedByNewsFilter(MinutesBeforeNews * 60, MinutesAfterNews * 60, IMPACT_HIGH))
   {
      // TODO:
   }
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(ChartID());
}

bool IsTradeAllowedByNewsFilter(int secondsbefore, int secondsafter, ENUM_NEWS_IMPACT impact = IMPACT_ALL)
{
   for(int i = 0; i < ArraySize(news); i++)
   {
      if(impact == IMPACT_ALL || news[i].Impact == impact)
      {
         datetime startTime = (datetime)((int)news[i].Date - secondsbefore);
         datetime endTime = (datetime)((int)news[i].Date + secondsafter);
         
         if(TimeCurrent() >= startTime && TimeCurrent() < endTime) return false;
      }
   }

   return true;
}

datetime _lastNewsUpdateTime = -1;
void UpdateNewsArray(string url, int intervalseconds, News &result[], ENUM_NEWS_IMPACT impact = IMPACT_ALL)
{
   if((long)TimeCurrent() - (long)_lastNewsUpdateTime < intervalseconds) return;
   
   GetNewsArray(url, result, impact);
   _lastNewsUpdateTime = TimeCurrent();
}

void GetNewsArray(string url, News &result[], ENUM_NEWS_IMPACT impact = IMPACT_ALL)
{
   if(MQLInfoInteger(MQL_TESTER) == 1) return;
   
   ArrayFree(result);
   ArrayResize(result, 0);

   string pageData = GetUrlData(NEWS_URL);
   string newsUrl = GetNewsUrl(pageData);
   string jsonData = GetUrlData(newsUrl);

   StringReplace(jsonData, "[{", "");
   StringReplace(jsonData, "}]", "");
   StringReplace(jsonData, "},", "");
   StringReplace(jsonData, "\"", "");
   
   string newsArray[];
   StringSplit(jsonData, '{', newsArray);
   
   for(int i = 0; i < ArraySize(newsArray); i++)
   {
      News data = GetNewsData(newsArray[i]);
      if(impact == IMPACT_ALL || data.Impact == impact) ArrayAdd(result, data);
   }
}

News GetNewsData(string newsdatastring)
{
   News result;

   string params[];
   StringSplit(newsdatastring, ',', params);
   
   for(int i = 0; i < ArraySize(params); i++)
   {
      string keyValue[];
      StringSplit(params[i], ':', keyValue);
      
      if(keyValue[0] == "title") result.Title = keyValue[1];
      if(keyValue[0] == "country") result.Country = keyValue[1];
      if(keyValue[0] == "date") result.Date = ConvertToDateTime(keyValue);
      if(keyValue[0] == "impact") result.Impact = StringToEnumImpact(keyValue[1]);
      if(keyValue[0] == "forecast") result.Forecast = keyValue[1];
      if(keyValue[0] == "previous") result.Previous = keyValue[1];
      if(keyValue[0] == "url") result.Url = keyValue[1] + ":" + keyValue[2];
      
      StringReplace(result.Title, "\\", "");
      StringReplace(result.Url, "\\", "");
   }
   
   return result;
}

ENUM_NEWS_IMPACT StringToEnumImpact(string impact)
{
   if(impact == "Holiday") return IMPACT_HOLIDAY;
   if(impact == "Low") return IMPACT_LOW;
   if(impact == "Medium") return IMPACT_MEDIUM;
   if(impact == "High") return IMPACT_HIGH;
      
   return IMPACT_ALL;
}

string EnumImpactToString(ENUM_NEWS_IMPACT impact)
{
   if(impact == IMPACT_HOLIDAY) return "Holiday";
   if(impact == IMPACT_LOW) return "Low";
   if(impact == IMPACT_MEDIUM) return "Medium";
   if(impact == IMPACT_HIGH) return "High";
      
   return "All";
}

datetime ConvertToDateTime(string &source[]) 
{
   string datestring;
   for(int i = 1; i < ArraySize(source); i++)
   {
      if(i == 1) datestring += source[i];
      else datestring += ":" + source[i];
   }
   
   string date = StringSubstr(datestring, 0, 10); 
   string time = StringSubstr(datestring, 11, 8);
   string timezone = StringSubstr(datestring, 19, 6);
 
   string reformatted = StringFormat("%s %s", date, time);
   StringReplace(reformatted, "-", ".");
   return StringToTime(reformatted);
}

string GetNewsUrl(string pagedata)
{
   int startIndex = StringFind(pagedata, JSON_LINK_START, 0);
   int endIndex = StringFind(pagedata, JSON_LINK_END, 0);
   return StringSubstr(pagedata, startIndex, endIndex - startIndex - 1);
}

string GetUrlData(string url)
{
   char data[];
   char result[];
   string headers;
   
   int response =  WebRequest("GET", url, "", 0, data, result, headers);
   if(response != 200) printf("Bad Request: " + url);
   
   return CharArrayToString(result);
}

template <typename T> void ArrayAdd(T &array[], T &value)
{
   int size = ArrayResize(array, ArraySize(array) + 1);
   if (size != -1) array[size - 1] = value;
}