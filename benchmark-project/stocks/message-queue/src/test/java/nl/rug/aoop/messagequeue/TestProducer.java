package nl.rug.aoop.messagequeue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class TestProducer {
    private MessageQueue unordered_msgQueue, ordered_msqQueue;
    private Producer ordered_producer, unordered_producer;

    @BeforeEach
    void setUp() {
        unordered_msgQueue = new UnorderedQueue();
        ordered_msqQueue = new OrderedQueue();

        ordered_producer = new Producer(ordered_msqQueue);
        unordered_producer = new Producer(unordered_msgQueue);
    }

//    @Test
//    void testOrderedProducerConstructor() {
//        assertNotNull(ordered_producer);
//    }
//
//    @Test
//    void testUnorderedProducerConstructor() {
//        assertNotNull(unordered_producer);
//    }
//
//    @Test
//    void testUnorderedPut() {
//        Message message1 = new Message("header", "body");
//        Message message2 = new Message("header", "body");
//        Message message3 = new Message("header", "body");
//
//        unordered_producer.put(message3);
//        unordered_producer.put(message1);
//        unordered_producer.put(message2);
//
//        assertEquals(message3, unordered_msgQueue.dequeue());
//        assertEquals(message1, unordered_msgQueue.dequeue());
//        assertEquals(message2, unordered_msgQueue.dequeue());
//    }
}