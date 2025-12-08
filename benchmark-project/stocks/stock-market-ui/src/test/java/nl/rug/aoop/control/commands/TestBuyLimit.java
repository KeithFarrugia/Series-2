package nl.rug.aoop.control.commands;

import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

public class TestBuyLimit {
    private StockExchange stockExchange;
    private Trader trader;

    @BeforeEach
    public void setup() {
        Stock stock = new Stock("AAPL", "Apple Inc.", 1000, 150);
        trader = new Trader("1", "Jason", 100000, new HashMap<>());

        List<Stock> stocks = new ArrayList<>();
        stocks.add(stock);

        List<Trader> traders = new ArrayList<>();
        traders.add(trader);

        stockExchange = new StockExchange(stocks, traders);
    }

    @Test
    public void testBuyLimit_PriceHigherThanAllAsks() {
        stockExchange.addAsk(new LimitOrder("1", "AAPL", 100, 145, "SellLimit"));
        stockExchange.addAsk(new LimitOrder("1", "AAPL", 100, 146, "SellLimit"));

        BuyLimit buyLimit = new BuyLimit(stockExchange);
        Map<String, Object> params = new HashMap<>();
        LimitOrder limitOrder = new LimitOrder("1", "AAPL", 150, 155, "BuyLimit");
        params.put("Order", limitOrder.toJson());

        buyLimit.execute(params);

        assertEquals(100000 - (145 * 100 + 146 * 50), trader.getFunds(), 0.01);
        assertEquals(150, trader.getOwnedShares().get("AAPL").intValue());
        assertEquals(146, stockExchange.findStockBySymbol("AAPL").getPrice());
    }

    @Test
    public void testBuyLimit_PriceLowerThanAllAsks() {
        stockExchange.addAsk(new LimitOrder("1", "AAPL", 100, 155, "SellLimit"));
        stockExchange.addAsk(new LimitOrder("1", "AAPL", 100, 156, "SellLimit"));

        BuyLimit buyLimit = new BuyLimit(stockExchange);
        Map<String, Object> params = new HashMap<>();
        LimitOrder limitOrder = new LimitOrder("1", "AAPL", 150, 150, "BuyLimit");
        params.put("Order", limitOrder.toJson());

        buyLimit.execute(params);

        assertEquals(100000, trader.getFunds(), 0.01);
        assertNull(trader.getOwnedShares().get("AAPL"));
        assertEquals(2, stockExchange.getAsksForSymbol("AAPL").size());
    }

    @Test
    public void testBuyLimit_PriceInBetween() {
        stockExchange.addAsk(new LimitOrder("1", "AAPL", 100, 148, "SellLimit"));
        stockExchange.addAsk(new LimitOrder("1", "AAPL", 100, 155, "SellLimit"));

        BuyLimit buyLimit = new BuyLimit(stockExchange);
        Map<String, Object> params = new HashMap<>();
        LimitOrder limitOrder = new LimitOrder("1", "AAPL", 150, 150, "BuyLimit");
        params.put("Order", limitOrder.toJson());

        buyLimit.execute(params);

        assertEquals(100000 - (148 * 100), trader.getFunds(), 0.01);
        assertEquals(100, trader.getOwnedShares().get("AAPL").intValue());
        assertEquals(1, stockExchange.getAsksForSymbol("AAPL").size());
        assertEquals(155, stockExchange.getAsksForSymbol("AAPL").get(0).getPrice(), 0.01);
    }
}
