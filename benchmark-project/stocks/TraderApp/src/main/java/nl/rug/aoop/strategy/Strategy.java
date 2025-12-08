package nl.rug.aoop.strategy;

import nl.rug.aoop.model.LimitOrder;

/**
 * Trading strategy.
 */
public interface Strategy {
    /**
     * Generates the order.
     * @return the generated LimitOrder.
     */
    LimitOrder generateOrder();
}
