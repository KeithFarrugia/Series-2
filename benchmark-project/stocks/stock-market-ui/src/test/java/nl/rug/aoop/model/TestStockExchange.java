package nl.rug.aoop.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class TestStockExchange {

    private StockExchange stockExchange;
    private List<Stock> stocks;
    private List<Trader> traders;

    @BeforeEach
    public void setUp() {
        stocks = new ArrayList<>();
        traders = new ArrayList<>();

        stocks.add(new Stock("AAPL", "Apple Inc.", 1000, 150.0));
        stocks.add(new Stock("GOOGL", "Google LLC", 1000, 2800.0));

        traders.add(new Trader("1", "Jason Derulo", 5000.0, null));
        traders.add(new Trader("2", "Jeremy Jammerson", 6000.0, null));

        stockExchange = new StockExchange(stocks, traders);
    }

    @Test
    public void testGetStockByIndex() {
        assertEquals("AAPL", stockExchange.getStockByIndex(0).getSymbol());
        assertEquals("GOOGL", stockExchange.getStockByIndex(1).getSymbol());
    }

    @Test
    public void testGetTraderByIndex() {
        assertEquals("1", stockExchange.getTraderByIndex(0).getId());
        assertEquals("2", stockExchange.getTraderByIndex(1).getId());
    }

    @Test
    public void testGetNumberOfStocks() {
        assertEquals(2, stockExchange.getNumberOfStocks());
    }

    @Test
    public void testGetNumberOfTraders() {
        assertEquals(2, stockExchange.getNumberOfTraders());
    }

    @Test
    public void testFindStockBySymbol() {
        assertNotNull(stockExchange.findStockBySymbol("AAPL"));
        assertNull(stockExchange.findStockBySymbol("MSFT"));
    }

    @Test
    public void testFindTraderById() {
        assertNotNull(stockExchange.findTraderById("1"));
        assertNull(stockExchange.findTraderById("5"));
    }

    @Test
    public void testAddAndRetrieveBids() {
        LimitOrder bid1 = new LimitOrder("1", "AAPL", 10, 145.0, "buy");
        LimitOrder bid2 = new LimitOrder("2", "AAPL", 15, 148.0, "buy");
        LimitOrder bid3 = new LimitOrder("1", "AAPL", 20, 143.0, "buy");

        stockExchange.addBid(bid1);
        stockExchange.addBid(bid2);
        stockExchange.addBid(bid3);

        List<LimitOrder> bids = stockExchange.getBidsForSymbol("AAPL");

        assertEquals(3, bids.size());
        assertEquals(148.0, bids.get(0).getPrice());
        assertEquals(145.0, bids.get(1).getPrice());
        assertEquals(143.0, bids.get(2).getPrice());
    }

    @Test
    public void testAddAndRetrieveAsks() {
        LimitOrder ask1 = new LimitOrder("1", "GOOGL", 10, 2820.0, "sell");
        LimitOrder ask2 = new LimitOrder("2", "GOOGL", 15, 2805.0, "sell");
        LimitOrder ask3 = new LimitOrder("1", "GOOGL", 20, 2830.0, "sell");

        stockExchange.addAsk(ask1);
        stockExchange.addAsk(ask2);
        stockExchange.addAsk(ask3);

        List<LimitOrder> asks = stockExchange.getAsksForSymbol("GOOGL");

        assertEquals(3, asks.size());
        assertEquals(2805.0, asks.get(0).getPrice());
        assertEquals(2820.0, asks.get(1).getPrice());
        assertEquals(2830.0, asks.get(2).getPrice());
    }
}
