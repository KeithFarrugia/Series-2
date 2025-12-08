package nl.rug.aoop;

import nl.rug.aoop.control.messagehandlers.IncomingOrderMessageHandler;
import nl.rug.aoop.initialization.factories.OrderCommandFactory;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import nl.rug.aoop.strategy.RandomStrategy;
import nl.rug.aoop.strategy.Strategy;
import java.util.ArrayList;
import java.util.List;

/**
 * Class to initialize the traderBots.
 */
public class TraderBotInitializer {
    private final List<Stock> stocks;
    private final List<Trader> traders;
    private final List<TraderBot> traderBots;

    /**
     * Class constructor.
     * @param traders the traders to initialize.
     * @param stocks the available stocks.
     */
    public TraderBotInitializer(List<Trader> traders, List<Stock> stocks) {
        this.stocks = stocks;
        this.traders = traders;
        this.traderBots = new ArrayList<>();
    }

    /**
     * Sets up each traderBot with its own thread and gives them the RandomStrategy, and the messageHandler.
     */
    public void initializeAndConnectBots() {
        StockExchange stockExchange = new StockExchange(stocks, traders);
        IncomingOrderMessageHandler incomingOrderMessageHandler = new
                IncomingOrderMessageHandler(new OrderCommandFactory(stockExchange));
        for (Trader trader : traders) {
            Strategy traderStrategy = new RandomStrategy(trader, stocks);
            TraderBot bot = new TraderBot(trader.getId(), traderStrategy, incomingOrderMessageHandler);
            traderBots.add(bot);

            Thread botThread = new Thread(bot);
            botThread.start();
        }
    }

    public List<TraderBot> getTraderBots() {
        return traderBots;
    }
}
