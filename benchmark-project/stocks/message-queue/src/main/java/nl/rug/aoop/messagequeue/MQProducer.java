package nl.rug.aoop.messagequeue;

/**
 * This is an interface representing message queue producers.
 * It provides a method to put a message on a message queue.
 */
public interface MQProducer {
    /**
     * Adds a message to the message queue.
     *
     * @param message the message that is being added
     */
    void put(Message message);
}
