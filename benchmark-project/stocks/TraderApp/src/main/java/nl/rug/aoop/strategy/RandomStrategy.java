package nl.rug.aoop.strategy;

import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.Trader;

import java.util.List;
import java.util.Random;

/**
 * Class to create a Random Order for the Trader Bot.
 */
public class RandomStrategy implements Strategy{
    private final Trader trader;
    private final List<Stock> availableStocks;
    private final Random random = new Random();

    /**
     * Constructor for class.
     * @param trader the trader that makes the order.
     * @param availableStocks available stocks for the trader to choose from.
     */
    public RandomStrategy(Trader trader, List<Stock> availableStocks) {
        this.trader = trader;
        this.availableStocks = availableStocks;
    }

    /**
     * Generates a random LimitOrder using the helper classes.
     * @return the LimitOrder.
     */
    @Override
    public LimitOrder generateOrder() {
        int quantity = Integer.MAX_VALUE;
        String orderType = decideOrderType();
        Stock chosenStock = chooseStock();
        while(quantity > trader.getFunds() / chosenStock.getPrice()){
            quantity = determineAmount();
        }
        double price;
        if ("BUY".equalsIgnoreCase(orderType)) {
            price = chosenStock.getPrice() * (1 + 0.01); // 1% more than stockprice
        } else {
            price = chosenStock.getPrice() * (1 - 0.01);
        }
        return new LimitOrder(trader.getId(), chosenStock.getSymbol(), quantity, price, orderType);
    }

    /**
     * Decides the order type using random.
     * @return the order type as a string.
     */
    private String decideOrderType() {
        return random.nextBoolean() ? "BuyLimit" : "SellLimit";
    }

    /**
     * Chooses a random available stock.
     * @return the chosen stock.
     */
    private Stock chooseStock() {
        int randomIndex = random.nextInt(availableStocks.size());
        return availableStocks.get(randomIndex);
    }

    private int determineAmount() {
        return random.nextInt(1000) + 1;
    }
}
