package nl.rug.aoop.model;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Encoder to send trader and stock info over the network.
 */
public class Encoder {
    private final Trader trader;
    private final List<Stock> stocks;

    /**
     * Constructor to intialize the trader and stocks info.
     *
     * @param trader the trader in question.
     * @param stocks the stocks in question.
     */
    public Encoder(Trader trader, List<Stock> stocks) {
        this.trader = trader;
        this.stocks = stocks;
    }

    /**
     * Converts the trader to a string.
     *
     * @return returns the trader as a string.
     */
    public String traderString() {
        return "Trader{" +
                "name='" + trader.getName() + '\'' +
                ", id=" + trader.getId() + '\'' +
                ", funds=" + trader.getFunds() + '\'' +
                ", ownedShares=" + trader.getOwnedShares() + '\'' +
                '}';
    }

    /**
     * turns the List of stocks into one string.
     *
     * @return the list of stocks as a string.
     */
    public String stocksString() {
        return stocks.stream()
                .map(this::singleStockString)
                .collect(Collectors.joining(",\n"));
    }

    /**
     * Converts the stock to a string.
     *
     * @param stock the stock to be encoded.
     * @return returns the stock as a string.
     */
    private String singleStockString(Stock stock) {
        return "Stock{" +
                "name='" + stock.getName() + '\'' +
                ", symbol='" + stock.getSymbol() + '\'' +
                ", price=" + stock.getPrice() +
                ", sharesOutstanding=" + stock.getSharesOutstanding() +
                '}';
    }
}
