package nl.rug.aoop.messagequeue;

/**
 * This class implements a consumer for a message queue who has the ability to remove and return messages
 * from its corresponding message queue.
 */
public class Consumer implements MQConsumer {
    private final MessageQueue msgQueue;

    /**
     * The producer is assigned the message queue that it will poll messages from.
     *
     * @param msgQueue the message queue
     */
    public Consumer(MessageQueue msgQueue) {
        this.msgQueue = msgQueue;
    }

    @Override
    public Message poll() {
        return msgQueue.dequeue();
    }
}
