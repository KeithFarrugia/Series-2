package nl.rug.aoop.messagequeue;

/**
 * This is an interface representing a message queue.
 * It provides methods to send and receive messages.
 */
public interface MessageQueue {
    /**
     * Used to insert a message into the queue.
     *
     * @param message The message being inserted
     */
    void enqueue(Message message);

    /**
     * Used to obtain the first element in the queue.
     *
     * @return the first element in the queue
     */
    Message dequeue();

    /**
     * Used to obtain the size of the  message queue.
     *
     * @return the size of the message queue
     */
    int getSize();
}
