package nl.rug.aoop.control.commands;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.command.Command;
import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Represents a buy limit command that processes a limit order to buy stocks.
 */
@Slf4j
public class BuyLimit implements Command {
    private final StockExchange stockExchange;
    private final LimitSupport limitSupport;

    /**
     * Initializes a new instance of the BuyLimit command.
     *
     * @param stockExchange The stock exchange where trading occurs.
     */
    public BuyLimit(StockExchange stockExchange) {
        this.stockExchange = stockExchange;
        this.limitSupport = new LimitSupport(stockExchange);
    }

    /**
     * Executes the buy limit command.
     *
     * @param params A map containing order details.
     */
    @Override
    public void execute(Map<String, Object> params) {
        LimitOrder limitOrder = LimitOrder.fromJson((String) params.get("Order"));
        Trader trader = stockExchange.findTraderById(limitOrder.getTraderId());
        String symbol = limitOrder.getSymbol();

        List<LimitOrder> askList = stockExchange.getAsksForSymbol(symbol);
        List<LimitOrder> bidsList = stockExchange.getBidsForSymbol(symbol);

        processBuyOrder(limitOrder, trader, symbol, askList, bidsList);
    }

    /**
     * Processes a buy order.
     *
     * @param limitOrder The order to be processed.
     * @param trader     The trader issuing the order.
     * @param symbol     The stock symbol.
     * @param askList    The list of existing ask orders.
     * @param bidsList   The list of existing bid orders.
     */
    private void processBuyOrder(LimitOrder limitOrder, Trader trader, String symbol, List<LimitOrder> askList,
                                 List<LimitOrder> bidsList) {
        if (askList == null) {
            return;
        }
        double potentialCost = limitOrder.getPrice() * limitOrder.getQuantity();
        if(trader.getFunds() < potentialCost) {
            log.warn("Trader" + trader.getId() + " attempted to place an Order without the necessary funds");
            return;
        }
        List<LimitOrder> ordersToRemove = new ArrayList<>();
        for (LimitOrder ask : askList) {
            if (limitOrder.getQuantity() == 0 || limitOrder.getPrice() < ask.getPrice()) {
                break;
            }

            calculateQuantities(limitOrder, ask, trader, symbol);

            if (ask.getQuantity() == 0) {
                ordersToRemove.add(ask);
            }
        }

        limitSupport.updateOrderLists(limitOrder, bidsList, askList, ordersToRemove, true);
    }

    /**
     * Calculates quantities for a buy order based on the current ask orders.
     *
     * @param limitOrder The order to be processed.
     * @param ask        The ask order to be matched.
     * @param trader     The trader issuing the order.
     * @param symbol     The stock symbol.
     */
    private void calculateQuantities(LimitOrder limitOrder, LimitOrder ask, Trader trader, String symbol) {
        int amountToBuy;

        if (limitOrder.getQuantity() <= ask.getQuantity()) {
            amountToBuy = limitOrder.getQuantity();
            ask.setQuantity(ask.getQuantity() - amountToBuy);
            limitOrder.setQuantity(0);
        } else {
            amountToBuy = ask.getQuantity();
            ask.setQuantity(0);
            limitOrder.setQuantity(limitOrder.getQuantity() - amountToBuy);
        }

        updateTrader(trader, symbol, ask.getPrice(), amountToBuy);
        addTransactionToTrader(trader, symbol, amountToBuy, limitOrder.getPrice());

        Stock stock = stockExchange.findStockBySymbol(symbol);
        updateStockPrice(stock, ask.getPrice());
    }

    /**
     * Updates the price of a stock.
     *
     * @param stock The stock whose price needs updating.
     * @param price The new price to update.
     */
    private void updateStockPrice(Stock stock, double price) {
        stock.updatePrice(price);
    }

    /**
     * Updates the trader's holdings.
     *
     * @param trader The trader to be updated.
     * @param symbol The stock symbol.
     * @param price  The executed order price.
     * @param amount The amount of stock traded.
     */
    private void updateTrader(Trader trader, String symbol, double price, int amount) {
        limitSupport.updateTrader(trader, symbol, price, amount, true);
    }

    /**
     * Adds a transaction to a trader's history.
     *
     * @param trader The trader to whom the transaction will be added.
     * @param symbol The stock symbol.
     * @param amount The amount of stock traded.
     * @param price  The executed order price.
     */
    private void addTransactionToTrader(Trader trader, String symbol, int amount, double price) {
        limitSupport.addTransactionToTrader(trader, symbol, amount, price, "BuyLimit");
    }
}
