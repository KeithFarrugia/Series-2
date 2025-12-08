package nl.rug.aoop.control.commands;

import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import nl.rug.aoop.model.Transaction;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Provides utility functions to support the handling of limit orders.
 */
public class LimitSupport {

    private final StockExchange stockExchange;

    /**
     * Initializes a new instance of the LimitSupport class.
     *
     * @param stockExchange The stock exchange in which the operations will be performed.
     */
    public LimitSupport(StockExchange stockExchange) {
        this.stockExchange = stockExchange;
    }

    /**
     * Updates the order lists based on the provided details.
     *
     * @param order          The limit order to be processed.
     * @param oppositeList   The list of orders opposite to the type of the provided order.
     * @param ownList        The list of orders of the same type as the provided order.
     * @param ordersToRemove List of orders that need to be removed.
     * @param isBuy          A flag to check if the order is a buy order.
     */
    public void updateOrderLists(LimitOrder order, List<LimitOrder> oppositeList, List<LimitOrder> ownList,
                                 List<LimitOrder> ordersToRemove, boolean isBuy) {
        ownList.removeAll(ordersToRemove);
        if (order.getQuantity() == 0) {
            oppositeList.remove(order);
        } else if (!oppositeList.contains(order)) {
            if (isBuy) {
                stockExchange.addBid(order);
            } else {
                stockExchange.addAsk(order);
            }
        }
    }

    /**
     * Updates the trader's funds and shares based on the transaction details.
     *
     * @param trader The trader involved in the transaction.
     * @param symbol The stock symbol related to the transaction.
     * @param price  The executed price of the order.
     * @param amount The amount of stock traded.
     * @param isBuy  A flag to check if the transaction is a buy transaction.
     */
    public void updateTrader(Trader trader, String symbol, double price, int amount, boolean isBuy) {
        if (isBuy) {
            trader.setFunds(trader.getFunds() - amount * price);
            trader.getOwnedShares().put(symbol, trader.getOwnedShares().getOrDefault(symbol, 0) + amount);
        } else {
            trader.setFunds(trader.getFunds() + amount * price);
            trader.getOwnedShares().put(symbol, trader.getOwnedShares().getOrDefault(symbol, 0) - amount);
        }
    }

    /**
     * Creates and adds a transaction to a trader's transaction history.
     *
     * @param trader The trader involved in the transaction.
     * @param symbol The stock symbol related to the transaction.
     * @param amount The amount of stock traded.
     * @param price  The executed price of the order.
     * @param type   The type of the transaction (e.g., "BuyLimit", "SellLimit").
     */
    public void addTransactionToTrader(Trader trader, String symbol, int amount, double price, String type) {
        Transaction transaction = new Transaction(
                trader.getId(),
                symbol,
                amount,
                price,
                type,
                LocalDateTime.now()
        );
        trader.addTransaction(transaction);
    }
}
