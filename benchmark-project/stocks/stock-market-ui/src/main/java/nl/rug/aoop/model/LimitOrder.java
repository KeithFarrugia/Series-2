package nl.rug.aoop.model;

import com.google.gson.Gson;
import lombok.Getter;
import lombok.Setter;

/**
 * This class refers to any kind of Limit Order creatod.
 */
public class LimitOrder {
    private static final Gson GSON = new Gson();
    @Getter
    private final String traderId;
    @Getter
    private final String symbol;
    @Getter
    private final double price;
    @Getter
    private final String orderType;
    @Getter
    @Setter
    private int quantity;

    /**
     * All the necessary info to be able to used inside an order instance.
     *
     * @param traderId  Identifier of the traders
     * @param symbol    the symbol referring to a stock
     * @param quantity  quantity that will be bought/sold
     * @param price     the offered prise (buy and sell)
     * @param orderType Whether the order is a buy or sell order
     */
    public LimitOrder(String traderId, String symbol, int quantity, double price, String orderType) {
        this.traderId = traderId;
        this.symbol = symbol;
        this.quantity = quantity;
        this.price = price;
        this.orderType = orderType;
    }

    /**
     * Turn an order from JSON to an order instance.
     *
     * @param json the string that will be converted from
     * @return the order
     */
    public static LimitOrder fromJson(String json) {
        return GSON.fromJson(json, LimitOrder.class);
    }

    /**
     * Compares the prices of two LimitOrders.
     *
     * @param o1 the first LimitOrder to be compared.
     * @param o2 the second LimitOrder to be compared.
     * @return the difference of the two orders (can be negative or 0)
     */
    public static int comparePrices(LimitOrder o1, LimitOrder o2) {
        return Double.compare(o1.getPrice(), o2.getPrice());
    }

    /**
     * Turn the order into a JSON string.
     *
     * @return the json string
     */
    public String toJson() {
        return GSON.toJson(this);
    }
}
