package nl.rug.aoop.initialization;

import lombok.Getter;
import nl.rug.aoop.control.messagehandlers.IncomingNetworkMessageHandler;
import nl.rug.aoop.control.messagehandlers.IncomingOrderMessageHandler;
import nl.rug.aoop.initialization.factories.MqCommandFactory;
import nl.rug.aoop.initialization.factories.OrderCommandFactory;
import nl.rug.aoop.messagequeue.MessageQueue;
import nl.rug.aoop.messagequeue.TimestampedPriorityBlockingQueue;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import nl.rug.aoop.model.loaders.DataLoader;
import nl.rug.aoop.networking.MessageHandler;
import nl.rug.aoop.networking.Server.Server;

import java.util.List;

/**
 * Handles the initialization processes of the stock application,
 * which includes data loading, setting up message handlers,
 * and starting the server.
 */
public class StockApplicationInitializer {
    private static MessageHandler incomingNetworkMessageHandler;
    private final Thread mqpThread;
    @Getter
    private Server server;
    private final UpdateSender updateSender;
    @Getter
    private List<Stock> stocks;
    @Getter
    private List<Trader> traders;
    private boolean hasStartedMQPThread = false;

    /**
     * Constructor that initializes necessary components for the stock application.
     */
    public StockApplicationInitializer() {
        DataLoader dataLoader = new DataLoader();
        stocks = dataLoader.loadStocks();
        traders = dataLoader.loadTraders();
        StockExchange stockExchange = new StockExchange(stocks, traders);
        MessageQueue messageQueue = new TimestampedPriorityBlockingQueue();
        updateSender = new UpdateSender(stockExchange);
        WebViewFactory viewFactory = new WebViewFactory();
        viewFactory.createView(stockExchange);
        incomingNetworkMessageHandler = new IncomingNetworkMessageHandler(new MqCommandFactory(messageQueue));
        MessageHandler incomingOrderMessageHandler = new
                IncomingOrderMessageHandler(new OrderCommandFactory(stockExchange));

        MessageQueuePoller mqp = new MessageQueuePoller(messageQueue, incomingOrderMessageHandler);
        mqpThread = new Thread(mqp);
    }

    /**
     * Initializes and starts the application server on the specified port.
     *
     * @param port the port on which the server should run.
     */
    public void startServer(int port) {
        server = new Server(port, incomingNetworkMessageHandler);
        Thread serverThread = new Thread(server);
        serverThread.start();
    }

    /**
     * Begins the process of polling the message queue and sending updates to clients.
     */
    public void startPollingAndSendingUpdates() {
        if (!hasStartedMQPThread) {
            mqpThread.start();
            hasStartedMQPThread = true;
        }
        updateSender.sendUpdatesToClients(server.getClientHandlers());
    }
}