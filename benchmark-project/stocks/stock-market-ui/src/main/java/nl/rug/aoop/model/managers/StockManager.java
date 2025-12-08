package nl.rug.aoop.model.managers;

import nl.rug.aoop.model.Stock;

import java.util.List;

/**
 * Provides utility functions for StockExchange that relate to Stock.
 */
public class StockManager {
    private final List<Stock> stocks;

    /**
     * The constructor is given the stocks to manage.
     *
     * @param stocks said stocks as a list
     */
    public StockManager(List<Stock> stocks) {
        this.stocks = stocks;
    }

    /**
     * The requested stocks are returned depending on their index.
     *
     * @param index index of the stock
     * @return the stock itself
     */
    public Stock getStockByIndex(int index) {
        if (index >= 0 && index < stocks.size()) {
            return stocks.get(index);
        }
        return null;
    }

    public List<Stock> getAllStocks() {
        return stocks;
    }

    public int getNumberOfStocks() {
        return stocks.size();
    }

    /**
     * The stock is returned by using its symbol.
     *
     * @param symbol the symbol of the stock
     * @return the stock itself
     */
    public Stock findStockBySymbol(String symbol) {
        for (Stock s : stocks) {
            if (s.getSymbol().equals(symbol)) {
                return s;
            }
        }
        return null;
    }
}
