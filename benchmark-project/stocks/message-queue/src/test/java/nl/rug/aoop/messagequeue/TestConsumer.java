package nl.rug.aoop.messagequeue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class TestConsumer {
    private MessageQueue unordered_msgQueue, ordered_msqQueue;
    private Consumer ordered_consumer, unordered_consumer;

    @BeforeEach
    void setUp() {
        unordered_msgQueue = new UnorderedQueue();
        ordered_msqQueue = new OrderedQueue();

        ordered_consumer = new Consumer(ordered_msqQueue);
        unordered_consumer = new Consumer(unordered_msgQueue);
    }

//    @Test
//    void testOrderedConsumerConstructor() {
//        assertNotNull(ordered_consumer);
//    }
//
//    @Test
//    void testUnorderedConsumerConstructor() {
//        assertNotNull(unordered_consumer);
//    }
//
//    @Test
//    void testOrderedPoll() {
//        Message message1 = new Message("header", "body");
//        Message message2 = new Message("header", "body");
//        Message message3 = new Message("header", "body");
//
//        ordered_msqQueue.enqueue(message3);
//        ordered_msqQueue.enqueue(message1);
//        ordered_msqQueue.enqueue(message2);
//
//        assertEquals(message1, ordered_consumer.poll());
//        assertEquals(message2, ordered_consumer.poll());
//        assertEquals(message3, ordered_consumer.poll());
//    }
//
//    @Test
//    void testUnorderedPoll() {
//        Message message1 = new Message("header", "body");
//        Message message2 = new Message("header", "body");
//        Message message3 = new Message("header", "body");
//
//        unordered_msgQueue.enqueue(message3);
//        unordered_msgQueue.enqueue(message1);
//        unordered_msgQueue.enqueue(message2);
//
//        assertEquals(message3, unordered_consumer.poll());
//        assertEquals(message1, unordered_consumer.poll());
//        assertEquals(message2, unordered_consumer.poll());
//    }
}