package nl.rug.aoop;

import nl.rug.aoop.control.OrderNetworkHandler;
import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.networking.Client.Client;
import nl.rug.aoop.networking.MessageHandler;
import nl.rug.aoop.strategy.Strategy;
import java.net.InetSocketAddress;

/**
 * TraderBot that is initialized with a strategy to use and sends orders every few seconds to the stockApps queue.
 */
public class TraderBot implements Runnable {
    private boolean running = true;

    private final String id;
    private final Strategy strategy;
    private final Client client;

    /**
     * Class constructor to start a client for the TraderBot.
     * @param id trader's ID.
     * @param strategy the strategy the TraderBot should use.
     * @param messageHandler message handler to handle messages.
     */
    public TraderBot(String id, Strategy strategy, MessageHandler messageHandler) {
        this.id = id;
        this.strategy = strategy;
        int defaultPort = 8080;
        String defaultHost = "localhost";

        // Fetch the STOCK_EXCHANGE_PORT and STOCK_EXCHANGE_HOST environment variables
        int port;
        String host;
        try {
            port = Integer.parseInt(System.getenv("STOCK_EXCHANGE_PORT"));
            host = System.getenv("STOCK_EXCHANGE_HOST");
            if (host == null || host.isEmpty()) {
                host = defaultHost;
            }
        } catch (NumberFormatException | NullPointerException e) {
            port = defaultPort;
            host = defaultHost;
        }

        InetSocketAddress address = new InetSocketAddress(host, port);
        client = new Client(address,messageHandler);
    }

    /**
     * runnable method that calls the generateOrder method from a chosen strategy.
     * sends the order to the queue every 1-4 seconds.
     */
    @Override
    public void run() {
        running = true;
        while (running) {
            try {
                Thread.sleep((int) (Math.random() * 3000) + 1000);
                LimitOrder limitOrder = strategy.generateOrder();
                sendMessageToQueue(limitOrder);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            }
        }
    }

    /**
     * Method to shut down the bot.
     */
    public void shutdown() {
        running = false;
    }

    /**
     * Sends the message to the queue.
     * @param limitOrder the order to place on the queue.
     */
    public void sendMessageToQueue(LimitOrder limitOrder) {
        OrderNetworkHandler orderNetworkHandler = new OrderNetworkHandler(client);
        orderNetworkHandler.putOrder(limitOrder);
    }
}
