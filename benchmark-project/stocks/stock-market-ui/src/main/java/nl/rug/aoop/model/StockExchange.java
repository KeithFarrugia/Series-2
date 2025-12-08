package nl.rug.aoop.model;

import nl.rug.aoop.model.managers.OrderManager;
import nl.rug.aoop.model.managers.StockManager;
import nl.rug.aoop.model.managers.TraderManager;

import java.util.List;

/**
 * Represents the stock exchange by managing stocks, traders, and orders.
 * Provides various operations to interact with the stocks, traders, and orders present.
 */
public class StockExchange implements StockExchangeDataModel {
    private final StockManager stockManager;
    private final TraderManager traderManager;
    private final OrderManager orderManager;

    /**
     * Constructs a new StockExchange.
     *
     * @param stocks  the initial list of stocks in the exchange.
     * @param traders the initial list of traders in the exchange.
     */
    public StockExchange(List<Stock> stocks, List<Trader> traders) {
        this.stockManager = new StockManager(stocks);
        this.traderManager = new TraderManager(traders);
        this.orderManager = new OrderManager();
    }

    /**
     * Retrieves the stock at a given index.
     *
     * @param index the index of the stock.
     * @return the stock at the specified index.
     */
    @Override
    public StockDataModel getStockByIndex(int index) {
        return stockManager.getStockByIndex(index);
    }

    /**
     * Gets the total number of stocks in the stock exchange.
     *
     * @return the number of stocks.
     */
    @Override
    public int getNumberOfStocks() {
        return stockManager.getNumberOfStocks();
    }

    /**
     * Retrieves the trader at a given index.
     *
     * @param index the index of the trader.
     * @return the trader at the specified index.
     */
    @Override
    public TraderDataModel getTraderByIndex(int index) {
        return traderManager.getTraderByIndex(index);
    }

    /**
     * Gets the total number of traders in the stock exchange.
     *
     * @return the number of traders.
     */
    @Override
    public int getNumberOfTraders() {
        return traderManager.getNumberOfTraders();
    }

    /**
     * Retrieves all stocks in the stock exchange.
     *
     * @return a list of all stocks.
     */
    public List<Stock> getAllStocks() {
        return stockManager.getAllStocks();
    }

    /**
     * Finds a stock by its symbol.
     *
     * @param symbol the symbol of the stock to find.
     * @return the stock with the specified symbol, or null if not found.
     */
    public Stock findStockBySymbol(String symbol) {
        return stockManager.findStockBySymbol(symbol);
    }

    /**
     * Finds a trader by their ID.
     *
     * @param id the ID of the trader to find.
     * @return the trader with the specified ID, or null if not found.
     */
    public Trader findTraderById(String id) {
        return traderManager.findTraderById(id);
    }

    /**
     * Adds a bid (buy order) to the stock exchange.
     *
     * @param bid the bid to add.
     */
    public void addBid(LimitOrder bid) {
        orderManager.addBid(bid);
    }

    /**
     * Adds an ask (sell order) to the stock exchange.
     *
     * @param ask the ask to add.
     */
    public void addAsk(LimitOrder ask) {
        orderManager.addAsk(ask);
    }

    /**
     * Retrieves all bids for a specified stock symbol.
     *
     * @param symbol the symbol of the stock.
     * @return the List of bids.
     */
    public List<LimitOrder> getBidsForSymbol(String symbol) {
        return orderManager.getBidsForSymbol(symbol);
    }

    /**
     * Retrieves all asks for a specified stock symbol.
     *
     * @param symbol the symbol of the stock.
     * @return the List of asks.
     */
    public List<LimitOrder> getAsksForSymbol(String symbol) {
        return orderManager.getAsksForSymbol(symbol);
    }
}
