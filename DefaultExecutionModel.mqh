#include "ExecutionModel.mqh";

class DefaultExecutionModel : public ExecutionModel
{
   private:
      int P;
      
      void OpenOrder(Trade * trade, double lotsNeeded)
      {
         double openPrice = (trade.GetOperation() == OP_SELL ? Bid : Ask);
         OrderSend(Symbol(), trade.GetOperation(), lotsNeeded, openPrice, trade.GetSlippage(), trade.GetStopLoss(), trade.GetTakeProfit());
      }

      void ModifyOrder(Trade * trade)
      {
         OrderModify(trade.GetTicket(), trade.GetOpenPrice(), trade.GetStopLoss(), trade.GetTakeProfit(), 0);
      }
      void CloseOrder(Trade * trade, double lotsToSell)
      {
         double closePrice = (trade.GetOperation() == OP_SELL ? Ask : Bid);
         OrderClose(trade.GetTicket(), lotsToSell, closePrice, trade.GetSlippage());
      }
      
   public:
      DefaultExecutionModel()
      {
         if(Digits == 5 || Digits == 3 || Digits == 1)
         {
            P = 10;
         }
         else
         {
            P = 1; 
         }
      }

      void Execute(Portfolio * currentPortfolio, Portfolio * newPortfolio)
      {
         for(int i = 0; i < newPortfolio.Size(); i++)
         {
            bool orderExists = False;
            Trade * newTrade = newPortfolio.GetTrade(i);
            Trade * currentTrade;
            if(currentPortfolio.TryGetTrade(newTrade.GetSymbol(), newTrade.GetOperation(), currentTrade))
            {
               orderExists = True;
               double lotsNeeded = newTrade.GetVolume() - currentTrade.GetVolume();
               if(lotsNeeded < 0)
               {
                  CloseOrder(newTrade, -lotsNeeded);
                  continue;
               }
               if(lotsNeeded > 0)
               {
                  OpenOrder(newTrade, lotsNeeded);
                  continue;
               }
               if(newTrade.GetStopLoss() != currentTrade.GetStopLoss() || newTrade.GetTakeProfit() != currentTrade.GetTakeProfit())
               {
                  ModifyOrder(newTrade);
                  continue;
               }
            }
            
            if(!orderExists && newTrade.GetVolume() > 0)
            {
               OpenOrder(newTrade, newTrade.GetVolume());
            }
         }
      }
};