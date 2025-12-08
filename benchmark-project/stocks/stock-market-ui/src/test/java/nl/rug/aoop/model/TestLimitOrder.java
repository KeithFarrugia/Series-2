package nl.rug.aoop.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class TestLimitOrder {
    @Test
    public void testOrderCreation() {
        LimitOrder limitOrder = new LimitOrder("1", "AAPL", 10, 150.0, "buy");

        assertEquals("1", limitOrder.getTraderId());
        assertEquals("AAPL", limitOrder.getSymbol());
        assertEquals(10, limitOrder.getQuantity());
        assertEquals(150.0, limitOrder.getPrice());
        assertEquals("buy", limitOrder.getOrderType());
    }

    @Test
    public void testSerializationAndDeserialization() {
        LimitOrder originalLimitOrder = new LimitOrder("1", "AAPL", 10, 150.0, "buy");
        String json = originalLimitOrder.toJson();

        LimitOrder deserializedLimitOrder = LimitOrder.fromJson(json);

        assertEquals(originalLimitOrder.getTraderId(), deserializedLimitOrder.getTraderId());
        assertEquals(originalLimitOrder.getSymbol(), deserializedLimitOrder.getSymbol());
        assertEquals(originalLimitOrder.getQuantity(), deserializedLimitOrder.getQuantity());
        assertEquals(originalLimitOrder.getPrice(), deserializedLimitOrder.getPrice());
        assertEquals(originalLimitOrder.getOrderType(), deserializedLimitOrder.getOrderType());
    }

    @Test
    public void testComparePrices() {
        LimitOrder limitOrder1 = new LimitOrder("1", "AAPL", 10, 150.0, "buy");
        LimitOrder limitOrder2 = new LimitOrder("1", "AAPL", 10, 155.0, "buy");
        LimitOrder limitOrder3 = new LimitOrder("1", "AAPL", 10, 145.0, "buy");

        assertTrue(LimitOrder.comparePrices(limitOrder1, limitOrder2) < 0);
        assertTrue(LimitOrder.comparePrices(limitOrder1, limitOrder3) > 0);
        assertEquals(0, LimitOrder.comparePrices(limitOrder1, limitOrder1));
    }

}
