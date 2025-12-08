package nl.rug.aoop.messagequeue;

/**
 * This is an interface representing message queue consumers.
 * It provides a method to receive messages from the queue.
 */
public interface MQConsumer {
    /**
     * This method is used to retrieve the first message in the queue.
     *
     * @return the first message in the message queue
     */
    Message poll();
}
