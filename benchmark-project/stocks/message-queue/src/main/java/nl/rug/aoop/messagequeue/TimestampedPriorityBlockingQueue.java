package nl.rug.aoop.messagequeue;

import java.util.concurrent.PriorityBlockingQueue;

/**
 * This is a queue implementation to deal with the issue of thread-safety. Everything added into this queue is
 * sorted by its timestamp.
 */
public class TimestampedPriorityBlockingQueue implements MessageQueue {

    private final PriorityBlockingQueue<Message> msgQueue;

    /**
     * Creating a new instance of the PriorityBlockingQueue class (The Java one).
     */
    public TimestampedPriorityBlockingQueue() {
        msgQueue = new PriorityBlockingQueue<>();
    }

    @Override
    public void enqueue(Message message) {
        msgQueue.offer(message);
    }

    @Override
    public Message dequeue() {
        return msgQueue.poll();
    }

    @Override
    public int getSize() {
        return msgQueue.size();
    }
}
