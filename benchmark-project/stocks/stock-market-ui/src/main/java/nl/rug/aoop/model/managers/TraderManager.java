package nl.rug.aoop.model.managers;

import nl.rug.aoop.model.Trader;

import java.util.List;

/**
 * Provides utility functions for StockExchange that relate to Trader.
 */
public class TraderManager {
    private final List<Trader> traders;

    /**
     * The constructor is given the traders to manage.
     *
     * @param traders said traders as a list
     */
    public TraderManager(List<Trader> traders) {
        this.traders = traders;
    }

    /**
     * returns a trader by its index in the list.
     *
     * @param index the index
     * @return the trader
     */
    public Trader getTraderByIndex(int index) {
        if (index >= 0 && index < traders.size()) {
            return traders.get(index);
        }
        return null;
    }

    public int getNumberOfTraders() {
        return traders.size();
    }

    /**
     * This method returns the trader corresponding to an id.
     *
     * @param id the id of the trader
     * @return the trader
     */
    public Trader findTraderById(String id) {
        for (Trader t : traders) {
            if (t.getId().equals(id)) {
                return t;
            }
        }
        return null;
    }
}
