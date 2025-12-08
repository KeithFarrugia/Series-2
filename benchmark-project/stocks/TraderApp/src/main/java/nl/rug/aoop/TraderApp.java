package nl.rug.aoop;

import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.Trader;
import nl.rug.aoop.model.loaders.DataLoader;
import java.util.List;

/**
 * Main Class.
 */
public class TraderApp {
    /**
     * Main for the TraderApplication.
     * @param args default.
     */
    public static void main(String[] args) {
        DataLoader dataLoader = new DataLoader();
        List<Trader> traders = dataLoader.loadTraders();
        List<Stock> stocks = dataLoader.loadStocks();

        if (traders == null || stocks == null) {
            System.out.println("Failed to load traders or stocks.");
            return;
        }
        TraderBotInitializer botInitializer = new TraderBotInitializer(traders, stocks);
        botInitializer.initializeAndConnectBots();
    }
}