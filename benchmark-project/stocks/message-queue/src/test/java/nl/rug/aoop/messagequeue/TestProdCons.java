package nl.rug.aoop.messagequeue;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

public class TestProdCons {


    private MQProducer ordered_producer, unordered_producer;
    private MQConsumer ordered_consumer, unordered_consumer;

    @Before
    public void setUp() {
        MessageQueue ordered_queue = new OrderedQueue();
        MessageQueue unordered_queue = new UnorderedQueue();

        ordered_producer = new Producer(ordered_queue);
        ordered_consumer = new Consumer(ordered_queue);

        unordered_producer = new Producer(unordered_queue);
        unordered_consumer = new Consumer(unordered_queue);

    }

    @Test
    public void testOrderedProducerAndConsumer() {
        Message message1 = new Message("Header", "Body");
        Message message2 = new Message("Header", "Body");
        Message message3 = new Message("Header", "Body");
        ordered_producer.put(message2);
        ordered_producer.put(message3);
        ordered_producer.put(message1);

        assertEquals(message1, ordered_consumer.poll());
        assertEquals(message2, ordered_consumer.poll());
        assertEquals(message3, ordered_consumer.poll());
    }

    @Test
    public void testUnorderedProducerAndConsumer() {
        Message message1 = new Message("Header", "Body");
        Message message2 = new Message("Header", "Body");
        Message message3 = new Message("Header", "Body");
        unordered_producer.put(message2);
        unordered_producer.put(message3);
        unordered_producer.put(message1);

        assertEquals(message2, unordered_consumer.poll());
        assertEquals(message3, unordered_consumer.poll());
        assertEquals(message1, unordered_consumer.poll());
    }


    @Test
    public void testUnorderedEmptyQueue() {
        assertNull(unordered_consumer.poll());
    }

    @Test
    public void testOrderedEmptyQueue() {
        assertNull(ordered_consumer.poll());
    }
}
