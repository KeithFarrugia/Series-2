package nl.rug.aoop.model;

/**
 * An interface for orders.
 *
 */
public interface Order {
    /**
     * returns the ID of the trader who made the order.
     *
     * @return the id
     */
    String getTraderId();

    /**
     * returns the symbol of the stock related to the order.
     *
     * @return the stock symbol
     */
    String getSymbol();

    /**
     * returns the price offered/asked of the stock related to the order.
     *
     * @return the price
     */
    double getPrice();

    /**
     * returns the type of the order.
     *
     * @return the order type
     */
    String getOrderType();

    /**
     * returns the amount of the order being asked/offered.
     *
     * @return the quantity
     */
    int getQuantity();

}
