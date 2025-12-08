package nl.rug.aoop.control.commands;

import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class TestSellLimit {

    private StockExchange stockExchange;
    private SellLimit sellLimit;
    private Trader trader;
    private Stock stock;
    private LimitOrder limitOrder;

    @BeforeEach
    void setUp() {
        stock = new Stock("AAPL", "Apple Inc.", 1000, 150.0);
        trader = new Trader("1", "Bob Ross", 1000000.0, new HashMap<>() {{
            put(stock.getSymbol(), 5);
        }});

        stockExchange = new StockExchange(List.of(stock), List.of(trader));
        sellLimit = new SellLimit(stockExchange);

        limitOrder = new LimitOrder(trader.getId(), stock.getSymbol(), 5, 149.0, "SellLimit");
    }

    @Test
    void testExecuteWithoutMatchingBids() {
        limitOrder = new LimitOrder(trader.getId(), stock.getSymbol(), 5, 200.0, "SellLimit");

        Map<String, Object> params = new HashMap<>();
        params.put("Order", limitOrder.toJson());

        sellLimit.execute(params);

        assertEquals(0, stockExchange.getBidsForSymbol(stock.getSymbol()).size()); // No bids should be present
        assertEquals(1, stockExchange.getAsksForSymbol(stock.getSymbol()).size()); // The sell order should be added to the asks

    }


    @Test
    void testExecuteWithPartialMatchingBids() {
        LimitOrder buyLimitOrder = new LimitOrder("2", stock.getSymbol(), 2, 149.0, "BuyLimit");
        stockExchange.addBid(buyLimitOrder);

        limitOrder = new LimitOrder(trader.getId(), stock.getSymbol(), 5, 149.0, "SellLimit");

        Map<String, Object> params = new HashMap<>();
        params.put("Order", limitOrder.toJson());

        sellLimit.execute(params);
        assertEquals(5, limitOrder.getQuantity());
        assertFalse(stockExchange.getAsksForSymbol(stock.getSymbol()).contains(limitOrder));
    }


    @Test
    void testExecuteWithFullMatchingBids() {
        stockExchange.addBid(new LimitOrder("2", stock.getSymbol(), 5, 149.0, "BuyLimit"));
        limitOrder = new LimitOrder(trader.getId(), stock.getSymbol(), 5, 149.0, "SellLimit");
        Map<String, Object> params = new HashMap<>();
        params.put("Order", limitOrder.toJson());

        sellLimit.execute(params);

        assertEquals(1000000 + 149 * 5, trader.getFunds());
        assertEquals(0, trader.getOwnedShares().get(stock.getSymbol()).intValue());
        assertFalse(stockExchange.getAsksForSymbol(stock.getSymbol()).contains(limitOrder));
    }

    @Test
    void testTraderTransactionsUpdate() {
        LimitOrder buyLimitOrder = new LimitOrder("2", stock.getSymbol(), 5, 149.0, "BuyLimit");
        stockExchange.addBid(buyLimitOrder);

        limitOrder = new LimitOrder(trader.getId(), stock.getSymbol(), 5, 149.0, "SellLimit");

        Map<String, Object> params = new HashMap<>();
        params.put("Order", limitOrder.toJson());

        sellLimit.execute(params);

        assertFalse(trader.getTransactions().isEmpty());
        assertEquals(stock.getSymbol(), trader.getTransactions().get(0).stockSymbol());
        assertEquals(5, trader.getTransactions().get(0).sharesTraded());
    }
}

