package nl.rug.aoop.initialization.factories;

import nl.rug.aoop.command.Command;
import nl.rug.aoop.control.commands.BuyLimit;
import nl.rug.aoop.control.commands.SellLimit;
import nl.rug.aoop.model.StockExchange;

/**
 * This class is a factory to that returns the corresponding order.
 *
 */
public class OrderCommandFactory implements CommandFactory {
    private final StockExchange stockExchange;

    /**
     * New instance of the OrderCommandFactory class.
     *
     * @param stockExchange The stock exchange to operate upon.
     */
    public OrderCommandFactory(StockExchange stockExchange) {
        this.stockExchange = stockExchange;
    }

    /**
     * Creates command objects based on order type.
     *
     * @param orderType the type of the order.
     * @return the command object.
     */
    @Override
    public Command getCommand(String orderType) {
        return switch (orderType) {
            case "BuyLimit" -> new BuyLimit(stockExchange);
            case "SellLimit" -> new SellLimit(stockExchange);
            default -> throw new IllegalArgumentException("Invalid order type: " + orderType);
        };
    }
}
