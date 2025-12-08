package nl.rug.aoop.strategy;

import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.Trader;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
public class RandomStrategyTest {

    private RandomStrategy randomStrategy;

    @Before
    public void setUp() {
        Map<String, Integer> ownedShares = new HashMap<>();
        ownedShares.put("AAPL", 10);
        Trader trader = new Trader("1", "Jason Derulo", 5000.0, ownedShares);
        randomStrategy = new RandomStrategy(trader, generateStocks());
    }

    @Test
    public void testGenerateOrder() {
        for (int i = 0; i < 100; i++) {
            LimitOrder order = randomStrategy.generateOrder();
            assertNotNull(order);
            assertTrue(order.getPrice() > 0);
            assertTrue(order.getQuantity() > 0 && order.getQuantity() <= 1000);
            assertTrue(order.getOrderType().equals("BuyLimit") || order.getOrderType().equals("SellLimit"));
        }
    }
    public List<Stock> generateStocks(){
        List<Stock> stocks = new ArrayList<>();
        stocks.add(new Stock("AAPL", "Apple Inc.", 1000, 150.0));
        return stocks;
    }

}
