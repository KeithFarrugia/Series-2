package nl.rug.aoop.messagequeue.commands;

import nl.rug.aoop.messagequeue.MQProducer;
import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.networking.Client.Client;

/**
 * This implementation of MQProducer doesn't put messages into queues locally but instead
 * the Network producer puts messages in queues over by sending them over the network.
 *
 */
public class NetworkProducer implements MQProducer {
    private final Client client;

    /**
     * Wraps the provided message into a NetworkMessage and sends
     * it over the network using the Client.
     *
     * @param client the client being used to send the message
     */
    public NetworkProducer(Client client) {
        this.client = client;
    }

    @Override
    public void put(Message message) {
        NetworkMessage networkMessage = new NetworkMessage("MqPut", message.toJson());
        client.send(networkMessage.toJson());
    }
}