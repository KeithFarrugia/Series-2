package nl.rug.aoop.model;

import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * This class represents the traders which put buy and sell orders.
 */
public class Trader implements TraderDataModel {
    private final List<Transaction> transactions = new ArrayList<>();
    @Getter
    @Setter
    private String id;
    @Setter
    @Getter
    private String name;
    @Setter
    @Getter
    private double funds;
    @Setter
    @Getter
    private Map<String, Integer> ownedShares;

    /**
     * Constructor for the trader class.
     *
     * @param id          of the Trader.
     * @param name        of Trader.
     * @param funds       of Trader.
     * @param ownedShares of Trader.
     */
    public Trader(String id, String name, double funds, Map<String, Integer> ownedShares) {
        this.id = id;
        this.name = name;
        this.funds = funds;
        this.ownedShares = ownedShares;
    }

    /**
     * Empty Constructor for the trader class.
     */
    public Trader() {

    }

    /**
     * adds a transaction record to the trader.
     *
     * @param transaction the transaction.
     */
    public void addTransaction(Transaction transaction) {
        this.transactions.add(transaction);
    }

    public List<Transaction> getTransactions() {
        return Collections.unmodifiableList(transactions);
    }

    /**
     * Returns the amount of shares a stock has.
     *
     * @param symbol the stock identifying symbol
     * @return the amount
     */
    public int getStockQuantity(String symbol) {
        return this.ownedShares.getOrDefault(symbol, 0);
    }

    @Override
    public List<String> getOwnedStocks() {
        return new ArrayList<>(ownedShares.keySet());
    }

    @Override
    public int getNumberOfOwnedShares(String stockSymbol) {
        return ownedShares.get(stockSymbol);
    }

}
