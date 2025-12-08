package nl.rug.aoop.model.managers;

import nl.rug.aoop.model.LimitOrder;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Provides utility functions for StockExchange that relate to Order.
 */
public class OrderManager {
    private final Map<String, List<LimitOrder>> bids;
    private final Map<String, List<LimitOrder>> asks;

    /**
     * Constructor that initializes the bids and asks.
     *
     */
    public OrderManager() {
        bids = new HashMap<>();
        asks = new HashMap<>();
    }

    /**
     * Adds a bid to the List of LimitOrders that are bids.
     *
     * @param bid the bid to add.
     */
    public void addBid(LimitOrder bid) {
        bids.computeIfAbsent(bid.getSymbol(), k -> new ArrayList<>()).add(bid);
        bids.get(bid.getSymbol()).sort((o1, o2) -> Double.compare(o2.getPrice(), o1.getPrice()));
    }

    /**
     * Adds an ask to the List of LimitOrders that are asks.
     *
     * @param ask the ask to add.
     */
    public void addAsk(LimitOrder ask) {
        asks.computeIfAbsent(ask.getSymbol(), k -> new ArrayList<>()).add(ask);
        asks.get(ask.getSymbol()).sort(LimitOrder::comparePrices);
    }

    /**
     * This method returns the list of bids for a specific symbol.
     *
     * @param symbol the symbol
     * @return list of bid orders
     */
    public List<LimitOrder> getBidsForSymbol(String symbol) {
        return bids.getOrDefault(symbol, new ArrayList<>());
    }

    /**
     * This method returns the list of asks for a specific symbol.
     *
     * @param symbol the symbol
     * @return list of ask orders
     */
    public List<LimitOrder> getAsksForSymbol(String symbol) {
        return asks.getOrDefault(symbol, new ArrayList<>());
    }
}
