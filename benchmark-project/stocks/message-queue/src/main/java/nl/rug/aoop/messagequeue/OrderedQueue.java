package nl.rug.aoop.messagequeue;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;

/**
 * The ordered queue orders messages according to their LocalDateTime, the messages are put on a list corresponding
 * to their time and sorted with a treemap.
 */
public class OrderedQueue implements MessageQueue {
    private final SortedMap<LocalDateTime, List<Message>> msgQueue;
    private int size = 0;

    /**
     * An instance of the TreeMap class is created.
     */
    public OrderedQueue() {
        msgQueue = new TreeMap<>();
    }

    @Override
    public void enqueue(Message message) {
        LocalDateTime timestamp = message.getTimestamp();
        if (!msgQueue.containsKey(timestamp)) {
            msgQueue.put(timestamp, new ArrayList<>());
        }
        msgQueue.get(timestamp).add(message);
        size++;
    }

    @Override
    public Message dequeue() {
        if (msgQueue.isEmpty()) {
            return null;
        }
        LocalDateTime firstStamp = msgQueue.firstKey();
        List<Message> messages = msgQueue.get(firstStamp);

        if (messages.isEmpty()) {
            msgQueue.remove(firstStamp);
            return null;
        } else {
            Message msg = messages.remove(0);
            if (messages.isEmpty()) {
                msgQueue.remove(firstStamp);
            }
            size--;
            return msg;
        }
    }

    @Override
    public int getSize() {
        return size;
    }
}
