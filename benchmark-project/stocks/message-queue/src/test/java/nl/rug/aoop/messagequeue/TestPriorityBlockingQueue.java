package nl.rug.aoop.messagequeue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.testng.AssertJUnit.assertNull;

public class TestPriorityBlockingQueue {

    private TimestampedPriorityBlockingQueue queue;

    @BeforeEach
    public void setUp() {
        queue = new TimestampedPriorityBlockingQueue();
    }

//    @Test
//    void testEnqueue() {
//        Message message1 = new Message("header", "body");
//        Message message2 = new Message("header", "body");
//        Message message3 = new Message("header", "body");
//
//        queue.enqueue(message3);
//        queue.enqueue(message1);
//        queue.enqueue(message2);
//
//        assertEquals(3, queue.getSize());
//        assertEquals(message1, queue.dequeue());
//        assertEquals(message2, queue.dequeue());
//        assertEquals(message3, queue.dequeue());
//    }

//    @Test
//    public void testDequeue() throws InterruptedException {
//        Message msg1 = new Message("header1", "body");
//        Thread.sleep(1);
//        Message msg2 = new Message("header2", "body");
//
//        queue.enqueue(msg2);
//        queue.enqueue(msg1);
//
//        assertEquals(2, queue.getSize());
//
//        Message dequeuedMessage1 = queue.dequeue();
//
//        assertEquals(msg1.getHeader(), dequeuedMessage1.getHeader());
//        assertEquals(msg1.getBody(), dequeuedMessage1.getBody());
//        assertEquals(msg1.getTimestamp(), dequeuedMessage1.getTimestamp());
//
//        Message dequeuedMessage2 = queue.dequeue();
//
//        assertEquals(msg2.getHeader(), dequeuedMessage2.getHeader());
//        assertEquals(msg2.getBody(), dequeuedMessage2.getBody());
//        assertEquals(msg2.getTimestamp(), dequeuedMessage2.getTimestamp());
//    }
//
//    @Test
//    public void testDequeueFromEmptyQueue() {
//        assertNull(queue.dequeue());
//    }
//
//    @Test
//    public void testQueueOrdering() throws InterruptedException {
//        Message msg1 = new Message("header1", "test message 1");
//        Thread.sleep(10);
//        Message msg2 = new Message("header2", "test message 2");
//
//        queue.enqueue(msg2);
//        queue.enqueue(msg1);
//
//        assertEquals(msg1, queue.dequeue());
//        assertEquals(msg2, queue.dequeue());
//    }
//
//    @Test
//    public void testGetSize() {
//        assertEquals(0, queue.getSize());
//
//        Message msg = new Message("Header", "test message");
//        queue.enqueue(msg);
//        assertEquals(1, queue.getSize());
//    }
//
//    @Test
//    public void testTimestampOrderingWithMultipleThreads() throws InterruptedException {
//        int numThreads = 100;
//        int numMessagesPerThread = 100;
//        Thread[] threads = new Thread[numThreads];
//        List<Message> dequeuedMessages = Collections.synchronizedList(new ArrayList<>());
//
//        for (int i = 0; i < numThreads; i++) {
//            threads[i] = new Thread(() -> {
//                for (int j = 0; j < numMessagesPerThread; j++) {
//                    Message msg = new Message("header", "body");
//                    queue.enqueue(msg);
//                }
//            });
//            threads[i].start();
//        }
//
//        for (Thread thread : threads) {
//            thread.join();
//        }
//
//        int totalMessages = numThreads * numMessagesPerThread;
//        for (int i = 0; i < totalMessages; i++) {
//            dequeuedMessages.add(queue.dequeue());
//        }
//
//        Message prevMessage = null;
//        for (Message currentMessage : dequeuedMessages) {
//            if (prevMessage != null) {
//                assertTrue(prevMessage.getTimestamp().compareTo(currentMessage.getTimestamp()) <= 0);
//            }
//            prevMessage = currentMessage;
//        }
//    }
}
