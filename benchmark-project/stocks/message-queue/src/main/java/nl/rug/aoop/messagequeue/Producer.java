package nl.rug.aoop.messagequeue;

/**
 * This class implements a producer for a message queue who has the ability to add into its corresponding
 * message queue.
 */
public class Producer implements MQProducer {
    private final MessageQueue msgQueue;

    /**
     * The producer is assigned the message queue that it will put messages on.
     *
     * @param msgQueue The message queue
     */
    public Producer(MessageQueue msgQueue) {
        this.msgQueue = msgQueue;
    }

    @Override
    public void put(Message message) {
        msgQueue.enqueue(message);
    }
}
