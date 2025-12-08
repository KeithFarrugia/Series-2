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
 * Represents a sell limit command that processes a limit order to sell stocks.
 */
@Slf4j
public class SellLimit implements Command {
    private final StockExchange stockExchange;
    private final LimitSupport limitSupport;

    /**
     * Constructor that initializes a new instance of the SellLimit command.
     *
     * @param stockExchange The stock exchange where trading occurs.
     */
    public SellLimit(StockExchange stockExchange) {
        this.stockExchange = stockExchange;
        this.limitSupport = new LimitSupport(stockExchange);
    }

    /**
     * Executes the sell limit command.
     *
     * @param params A map containing order details.
     */
    @Override
    public void execute(Map<String, Object> params) {
        LimitOrder limitOrder = LimitOrder.fromJson((String) params.get("Order"));
        Trader trader = stockExchange.findTraderById(limitOrder.getTraderId());
        String symbol = limitOrder.getSymbol();

        List<LimitOrder> bidsList = stockExchange.getBidsForSymbol(symbol);
        List<LimitOrder> askList = stockExchange.getAsksForSymbol(symbol);

        processSellOrder(limitOrder, trader, symbol, askList, bidsList);
    }

    /**
     * Processes a sell order.
     *
     * @param limitOrder The order to be processed.
     * @param trader     The trader issuing the order.
     * @param symbol     The stock symbol.
     * @param askList    The list of existing ask orders.
     * @param bidsList   The list of existing bid orders.
     */
    private void processSellOrder(LimitOrder limitOrder, Trader trader, String symbol, List<LimitOrder> askList,
                                  List<LimitOrder> bidsList) {
        if (bidsList == null) {
            return;
        }
        if(trader.getStockQuantity(symbol) < limitOrder.getQuantity()) {
            log.warn("Trader" + trader.getId() + " attempted to place a sell order without the necessary stock amount");
            return;
        }
        List<LimitOrder> ordersToRemove = new ArrayList<>();
        for (LimitOrder bid : bidsList) {
            if (limitOrder.getQuantity() == 0 || limitOrder.getPrice() > bid.getPrice()) {
                break;
            }

            calculateQuantities(limitOrder, bid, trader, symbol);

            if (bid.getQuantity() == 0) {
                ordersToRemove.add(bid);
            }
        }

        limitSupport.updateOrderLists(limitOrder, bidsList, askList, ordersToRemove, false);
    }

    /**
     * Calculates quantities for a sell order based on the current ask orders.
     *
     * @param limitOrder The order to be processed.
     * @param bid        The bid order to be matched.
     * @param trader     The trader issuing the order.
     * @param symbol     The stock symbol.
     */
    private void calculateQuantities(LimitOrder limitOrder, LimitOrder bid, Trader trader, String symbol) {
        int amountToSell;

        if (limitOrder.getQuantity() <= bid.getQuantity()) {
            amountToSell = limitOrder.getQuantity();
            bid.setQuantity(bid.getQuantity() - amountToSell);
            limitOrder.setQuantity(0);
        } else {
            amountToSell = bid.getQuantity();
            bid.setQuantity(0);
            limitOrder.setQuantity(limitOrder.getQuantity() - amountToSell);
        }

        updateTrader(trader, symbol, limitOrder.getPrice(), amountToSell);
        addTransactionToTrader(trader, symbol, amountToSell, limitOrder.getPrice());

        Stock stock = stockExchange.findStockBySymbol(symbol);
        updateStockPrice(stock, limitOrder.getPrice());
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
        limitSupport.updateTrader(trader, symbol, price, amount, false);
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
        limitSupport.addTransactionToTrader(trader, symbol, amount, price, "SellLimit");
    }
}
