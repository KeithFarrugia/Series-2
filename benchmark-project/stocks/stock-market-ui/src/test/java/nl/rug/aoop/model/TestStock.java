package nl.rug.aoop.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class TestStock {

    private Stock stock;

    @BeforeEach
    public void setUp() {
        stock = new Stock("AAPL", "Apple Inc.", 1000, 150.0);
    }

    @Test
    public void testGetSymbol() {
        assertEquals("AAPL", stock.getSymbol());
    }

    @Test
    public void testGetName() {
        assertEquals("Apple Inc.", stock.getName());
    }

    @Test
    public void testGetSharesOutstanding() {
        assertEquals(1000, stock.getSharesOutstanding());
    }

    @Test
    public void testGetPrice() {
        assertEquals(150.0, stock.getPrice());
    }

    @Test
    public void testCalculateMarketCap() {
        assertEquals(150000, stock.getMarketCap());
    }

    @Test
    public void testUpdatePrice() {
        stock.updatePrice(155.0);
        assertEquals(155.0, stock.getPrice());
    }

    @Test
    public void testSetSharesOutstanding() {
        stock.setSharesOutstanding(1200);
        assertEquals(1200, stock.getSharesOutstanding());
    }
}
