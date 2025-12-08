package nl.rug.aoop.control;

import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.messagequeue.commands.NetworkProducer;
import nl.rug.aoop.model.LimitOrder;
import nl.rug.aoop.networking.Client.Client;

/**
 * This class is used to process the orders and send them in a queue over the network.
 */

public class OrderNetworkHandler {
    private final NetworkProducer networkProducer;

    /**
     * This is a constructor for the OrderProcessor class.
     *
     * @param client the client.
     */
    public OrderNetworkHandler(Client client) {
        this.networkProducer = new NetworkProducer(client);
    }

    /**
     * Places an order on the queue using the networkProducer.
     *
     * @param limitOrder the order to be placed on the queue.
     */
    public void putOrder(LimitOrder limitOrder) {
        Message message = new Message(limitOrder.getOrderType(), limitOrder.toJson());
        networkProducer.put(message);
    }
}
