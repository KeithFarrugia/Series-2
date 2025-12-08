package nl.rug.aoop.model;

import lombok.Getter;
import lombok.Setter;

/**
 * Stock data class.
 */
public class Stock implements StockDataModel {
    @Getter
    @Setter
    private String symbol;
    @Getter
    @Setter
    private String name;
    @Getter
    @Setter
    private long sharesOutstanding;
    @Getter
    @Setter
    private double initialPrice;

    /**
     * Constructor for Stock.
     *
     * @param symbol            of stock.
     * @param name              of stock.
     * @param sharesOutstanding of stock.
     * @param initialPrice      of stock.
     */
    public Stock(String symbol, String name, long sharesOutstanding, double initialPrice) {
        this.symbol = symbol;
        this.name = name;
        this.sharesOutstanding = sharesOutstanding;
        this.initialPrice = initialPrice;
    }

    /**
     * Empty constructor used by yamlLoaders.
     */
    public Stock() {

    }

    @Override
    public double getMarketCap() {
        return calculateMarketCap();
    }

    @Override
    public double getPrice() {
        return initialPrice;
    }

    /**
     * calculates the market cap for a stock.
     *
     * @return market cap.
     */
    public double calculateMarketCap() {
        return sharesOutstanding * initialPrice;
    }

    /**
     * Updates the lsat transaction's price.
     *
     * @param transactionPrice the new price to set.
     */
    public void updatePrice(double transactionPrice) {
        this.initialPrice = transactionPrice;
    }
}
