//+------------------------------------------------------------------+
//|                                      Copyright 2020, Mehmet ÖZEN |
//|                                          ozenmehmet.92@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Mehmet ÖZEN"
#property link ""
#property version   "8.0"
#property description "Grid Pro"
#include <Trade\Trade.mqh>
CTrade mytrade;
#define S                  _Symbol
#define P                  _Point
#define D                  _Digits
#define lot_stepD          (int) - MathLog10(SymbolInfoDouble(S, SYMBOL_VOLUME_STEP))
#define lot_min            SymbolInfoDouble(S,SYMBOL_VOLUME_MIN)
#define lot_max            SymbolInfoDouble(S,SYMBOL_VOLUME_MAX)
#define Ask                SymbolInfoDouble(S,SYMBOL_ASK)
#define Bid                SymbolInfoDouble(S,SYMBOL_BID)
#define Spread             SymbolInfoInteger(S,SYMBOL_SPREAD)
#define Equity             AccountInfoDouble(ACCOUNT_EQUITY)
#define FreeMargin         AccountInfoDouble(ACCOUNT_MARGIN_FREE)
#define volumelimit        SymbolInfoDouble(S,SYMBOL_VOLUME_LIMIT)

input group    "---BASIC SETTINGS---";
input int EA               = 123252;   // EA Magic Number
input double ProfitRate    = 10;       //Average TP
input double LotMultiplier = 1.3579;   //LotMultiplier
input double gap_divider   = 25;       //Gap Divider
input double FirstLot      = 0.01;     //First Lot
input bool  autolot        = true;    //Auto Lot Activation
input double autolot_e     = 2000;    //First Lot Value for This Equity 
input int maxorder         = 8   ;    //The Number of Max Order for per direction

input group "--------Trailing Stop--------"
input bool trail           = true; //Trailing Stop Activation
input double trailingdistance = 5;    //Trailing Distance
input double trailingstart    = 5;  //Trailing Start Rate
input int pos_sayisi          = 3;  //The Number of Positions

input group "--------No Loss Close--------"
input bool noloss           = true; //No Loss Activation
input int nolosssayi        = 5;//Pos Number for close Positions

int sellsayisi(){
   int      count     = 0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){                    
               count++;
            }
   }
   return count;
}

int buysayisi(){
   int      count     = 0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){                    
               count++;
            }
   }
   return count;
}

double sellvol(){
   double   count = 0.0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){                    
               count += PositionGetDouble(POSITION_VOLUME);
            }
   }
   return count;
}

double buyvol(){
   double   count = 0.0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){                    
               count += PositionGetDouble(POSITION_VOLUME);
            }
   }
   return count;
}

datetime FirstSellTime(){
   datetime     Time   = TimeCurrent();
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){                    
               if(PositionGetInteger(POSITION_TIME_MSC) < Time){
                  Time = (datetime)PositionGetInteger(POSITION_TIME_MSC);
               }
            }
   }
   return Time;
}

datetime FirstBuyTime(){
   datetime     Time   = TimeCurrent();
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){                    
               if(PositionGetInteger(POSITION_TIME_MSC) < Time){
                  Time = (datetime)PositionGetInteger(POSITION_TIME_MSC);
               }
            }
   }
   return Time;
}

double LastSellPrice(){
   double   Price  = 0.0;
   long     Time   = 0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){                    
               if(PositionGetInteger(POSITION_TIME_MSC) > Time){
                  Time = PositionGetInteger(POSITION_TIME_MSC);
                  Price = PositionGetDouble(POSITION_PRICE_OPEN);
               }
            }
   }
   return Price;
}

double LastBuyPrice(){
   double   Price  = 0.0;
   long     Time   = 0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){                    
               if(PositionGetInteger(POSITION_TIME_MSC) > Time){
                  Time = PositionGetInteger(POSITION_TIME_MSC);
                  Price = PositionGetDouble(POSITION_PRICE_OPEN);
               }
            }
   }
   return Price;
}

double sellprofit(){
   double   profit     = 0.0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){                    
               profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
            }
   }
   return profit;
}

double buyprofit(){
   double   profit     = 0.0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){                    
               profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
            }
   }
   return profit;
}

void hedefayarla(ENUM_POSITION_TYPE type){
   double vol = 0;
   double profit = 0;
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==type){
               vol += PositionGetDouble(POSITION_VOLUME);
               profit += PositionGetDouble(POSITION_PROFIT);
            }
   }
     
   double TP      = profit/vol/MathPow(10,D)-ProfitRate/MathPow(10,D-1);
   double buy_TP  = NormalizeDouble(SymbolInfoDouble(S,SYMBOL_ASK)-TP,D);
   double sell_TP = NormalizeDouble(SymbolInfoDouble(S,SYMBOL_BID)+TP,D);
   //TP calculation to Modify
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==type)
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
               {
                  mytrade.PositionModify(PositionGetTicket(i),NULL,buy_TP);
                  Sleep(1000);
               }
               else
               {
                  mytrade.PositionModify(PositionGetTicket(i),NULL,sell_TP);
                  Sleep(1000);
               }
   }
}

void TP(){

   double buy_TP = NULL;
   double sell_TP = NULL;
   for(int i=0;i<PositionsTotal();i++){
   if(PositionSelectByTicket(PositionGetTicket(i)))
      if(EA==PositionGetInteger(POSITION_MAGIC) && NULL!=PositionGetDouble(POSITION_TP) && S ==PositionGetSymbol(i))
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
               buy_TP =PositionGetDouble(POSITION_TP);
            else
               sell_TP =PositionGetDouble(POSITION_TP);
   }
   
   //TP calculation to Modify
   for(int i=0;i<PositionsTotal();i++){
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(EA==PositionGetInteger(POSITION_MAGIC) && NULL==PositionGetDouble(POSITION_TP) && S ==PositionGetSymbol(i))
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
               {
                  mytrade.PositionModify(PositionGetTicket(i),NULL,buy_TP);
                  Sleep(1000);
               }
               else
               {
                  mytrade.PositionModify(PositionGetTicket(i),NULL,sell_TP);
                  Sleep(1000);
               }
   }
}
 
 bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
   
   string dec; 
   if(!CheckVolumeValue(lots,dec))
      return(false);
//--- checking successful
   return(true);
  }
  
  bool CheckVolumeValue(double volume,string &description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                               volume_step,ratio*volume_step);
      return(false);
     }
      
   description="Correct volume value";
   return(true);
  }

void trailingBuyStop()
{
   double SL1 = NormalizeDouble(Ask-trailingdistance*10*_Point,_Digits);
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
    if(_Symbol==PositionGetSymbol(i) && EA==PositionGetInteger(POSITION_MAGIC))
      {
      double currentSL = PositionGetDouble(POSITION_SL);
      if(currentSL<SL1)
         mytrade.PositionModify(PositionGetInteger(POSITION_TICKET),SL1,PositionGetDouble(POSITION_TP));
      }
   }
}

void trailingSellStop()
{  
   double SL1 = NormalizeDouble(Bid+trailingdistance*10*_Point,_Digits);
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
    if(_Symbol==PositionGetSymbol(i) && EA==PositionGetInteger(POSITION_MAGIC))
      {
      
      double currentSL = PositionGetDouble(POSITION_SL);
      if(PositionGetDouble(POSITION_SL)==NULL)
         currentSL = Bid*2;
      if(currentSL>SL1)
         mytrade.PositionModify(PositionGetInteger(POSITION_TICKET),SL1,PositionGetDouble(POSITION_TP));
      }
   }
}

bool isNewBar()
{
    static datetime prevTime = 0;
    datetime lastTime[1];
    if(CopyTime(Symbol(), Period(), 0, 1, lastTime) == 1 && prevTime != lastTime[0])
       {
        prevTime = lastTime[0];
        return(true);
       }
    return(false);
}

void closeallsell()
{
   int d = 0;
   while(sellsayisi()>0 && d<10)
   {
      for(int i=0;i<PositionsTotal();i++){
         if(PositionSelectByTicket(PositionGetTicket(i)))
            if(EA==PositionGetInteger(POSITION_MAGIC) && _Symbol ==PositionGetSymbol(i))
               if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL)
                  mytrade.PositionClose(PositionGetTicket(i));
      }
      Sleep(100);
      d++;
    }
}

void closeallbuy()
{
   int d = 0;
   while(buysayisi()>0 && d<10)
   {
      for(int i=0;i<PositionsTotal();i++){
         if(PositionSelectByTicket(PositionGetTicket(i)))
            if(EA==PositionGetInteger(POSITION_MAGIC) && _Symbol ==PositionGetSymbol(i))
               if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY)
                  mytrade.PositionClose(PositionGetTicket(i));
      }
            Sleep(100);
      d++;
    }
}

int OnInit()
  {
   mytrade.SetExpertMagicNumber(EA);
   mytrade.SetDeviationInPoints(10);
   mytrade.SetTypeFilling(ORDER_FILLING_RETURN);
   mytrade.LogLevel(1);
   mytrade.SetAsyncMode(true);
   
   return(INIT_SUCCEEDED);
  }

void OnTick()
{  
   double FirstLot_ = FirstLot;
   
   if(autolot)
   {
      FirstLot_ = Equity*FirstLot/autolot_e;
      if(FirstLot_< lot_min)
         FirstLot_ = lot_min;
   }
   
   if(buysayisi()>0 && maxorder>buysayisi() && lot_max>buyvol()+FirstLot_*MathPow(LotMultiplier,buysayisi()) )
      if(LastBuyPrice() - gap() > Ask && CheckMoneyForTrade(S,NormalizeDouble(FirstLot_*MathPow(LotMultiplier,buysayisi()),lot_stepD),ORDER_TYPE_BUY))
         if(mytrade.Buy(NormalizeDouble(FirstLot_*MathPow(LotMultiplier,buysayisi()),lot_stepD),S,Ask,NULL,NULL,""))
            hedefayarla(POSITION_TYPE_BUY);
            
   if((signal()==1 || signal()==3) && buysayisi()==0 && CheckMoneyForTrade(S,NormalizeDouble(FirstLot_,lot_stepD),ORDER_TYPE_BUY))
         mytrade.Buy(NormalizeDouble(FirstLot_,lot_stepD),S,Ask,NULL,Ask+10*ProfitRate*P,"");

   if(sellsayisi()>0 && maxorder>sellsayisi() && lot_max>sellvol()+FirstLot_*MathPow(LotMultiplier,sellsayisi()) )
      if(LastSellPrice() + gap() < Bid  && CheckMoneyForTrade(S,NormalizeDouble(FirstLot_*MathPow(LotMultiplier,sellsayisi()),lot_stepD),ORDER_TYPE_SELL))
         if(mytrade.Sell(NormalizeDouble(FirstLot_*MathPow(LotMultiplier,sellsayisi()),lot_stepD),S,Bid,NULL,NULL,""))
            hedefayarla(POSITION_TYPE_SELL);
     
   if((signal()==2 || signal()==3) && sellsayisi()==0 && CheckMoneyForTrade(S,NormalizeDouble(FirstLot_,lot_stepD),ORDER_TYPE_SELL))
         mytrade.Sell(NormalizeDouble(FirstLot_,lot_stepD),S,Bid,NULL,Bid-10*ProfitRate*P,"");

   TP();//TP'si eksik olanı ayarlar
   Comment("                                                                    TNoBuy:",buysayisi(), "   Vol :",buyvol(), "   Profit:",buyprofit(),
         "\n                                                                    TNoSell :",sellsayisi(),"   Vol :",sellvol(),"   Profit :",sellprofit());        
   
   if(trail)
   {
      if(buysayisi()>pos_sayisi)
         if(buyprofit()/buyvol() >= 10*trailingstart)
         trailingBuyStop();
      if(sellsayisi()>pos_sayisi)
         if(sellprofit()/sellvol() >= 10*trailingstart)
         trailingSellStop();
   }
   
   if(noloss)
   {
      if(buysayisi()>=nolosssayi && buyprofit()>=0)
         closeallbuy();
      if(sellsayisi()>=nolosssayi && sellprofit()>=0) 
         closeallsell();
   }
}

double gap()
{
   double montly_high[],montly_low[];
   CopyHigh (   Symbol(),PERIOD_MN1,0,2,montly_high );
   CopyLow  (   Symbol(),PERIOD_MN1,0,2,montly_low  );
   return((montly_high[1]-montly_low[1])/gap_divider);
}

int signal()
{
   int sonuc = 0;
   double daily_High[],daily_Low[],High_Graph[],Low_Graph[],mid_point[],daily_midpoint[];   
   CopyHigh (   Symbol(),PERIOD_D1,iTime(NULL,PERIOD_MN1,0),TimeCurrent(),daily_High    );
   CopyLow  (   Symbol(),PERIOD_D1,iTime(NULL,PERIOD_MN1,0),TimeCurrent(),daily_Low     );
   
   int size = ArraySize(daily_High);
   ArrayResize(High_Graph,size);
   ArrayResize(Low_Graph,size);
   ArrayResize(mid_point,size);
   ArrayResize(daily_midpoint,size);
   High_Graph[0]  =  daily_High[0];
   Low_Graph[0]   =  daily_Low[0];
   mid_point[0]   = (High_Graph[0]+Low_Graph[0])/2;
   daily_midpoint[0] = (daily_High[0]+daily_Low[0])/2;
   
   for(int i=1;i<size;i++)
   {
      if(High_Graph[i-1]>daily_High[i])
         High_Graph[i] = High_Graph[i-1];
      else
         High_Graph[i]=daily_High[i];
         
      if(Low_Graph[i-1]<daily_Low[i])
         Low_Graph[i] = Low_Graph[i-1];
      else
         Low_Graph[i]=daily_Low[i];
         
      mid_point[i] = (High_Graph[i]+Low_Graph[i])/2;
      daily_midpoint[i] = (daily_High[i]+daily_Low[i])/2;
   }
   
   bool buy    = false;
   bool sell   = false;
   
   if(size >= 2)
   {
      double daily_mid = daily_midpoint[size-1];
      double long_mid  = mid_point[size-1];
      double High      = High_Graph[size-1];
      double Low       = Low_Graph[size-1];
      
      double rsi[];
      ArraySetAsSeries(rsi,true);
      CopyBuffer(iRSI(S,PERIOD_D1,14,PRICE_CLOSE),0,0,2,rsi);
   
      if(daily_mid > long_mid)
      {
         //buy = (Bid > long_mid && Bid < High);
         sell = (Bid >= High) && /* rsi[0]>70 &&*/ rsi[0]<70;
      }else if(daily_mid < long_mid)
      {
         //sell = (Bid < long_mid && Bid > Low);
         buy = (Bid <= Low) && /*  rsi[0]<30 &&*/ rsi[0]>30;
      }
   }
   
   if(buy && sell)
      sonuc = 3;
   else if(buy)
      sonuc = 1;
   else if(sell)
      sonuc = 2;

   return(sonuc);
}