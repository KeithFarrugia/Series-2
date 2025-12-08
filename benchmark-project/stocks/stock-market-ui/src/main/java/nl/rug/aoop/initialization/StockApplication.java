package nl.rug.aoop.initialization;

/**
 * The main class of the StockApplication, the server is initialized here.
 */

public class StockApplication {

    /**
     * The server is initialized, information about the current status of stocks and traders are sent every
     * 2 seconds.
     *
     * @param args arguments
     */
    public static void main(String[] args) {
        int defaultPort = 8080;
        int port;
        try {
            port = Integer.parseInt(System.getenv("STOCK_EXCHANGE_PORT"));
        } catch (NumberFormatException | NullPointerException e) {
            port = defaultPort;
        }

        StockApplicationInitializer initializer = new StockApplicationInitializer();
        initializer.startServer(port);
        while (true) {
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            if (initializer.getServer().getClientHandlers().size() != 0) {
                initializer.startPollingAndSendingUpdates();
            }
        }
    }

}
