package nl.rug.aoop.messagequeue;

import java.util.LinkedList;
import java.util.Queue;

/**
 * This class implements a message queue in a regular FIFO manner, the first message that comes in is always the
 * first one to get out.
 */
public class UnorderedQueue implements MessageQueue {
    private final Queue<Message> msgQueue;

    /**
     * A linked list is used to implement the queue.
     */
    public UnorderedQueue() {
        msgQueue = new LinkedList<>();
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
