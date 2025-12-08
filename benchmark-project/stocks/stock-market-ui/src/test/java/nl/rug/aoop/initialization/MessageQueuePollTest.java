package nl.rug.aoop.initialization;

import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.messagequeue.MessageQueue;
import nl.rug.aoop.networking.MessageHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.mockito.Mockito.*;

public class MessageQueuePollTest {


    private MessageHandler messageHandler;
    private MessageQueue messageQueue;
    private MessageQueuePoller poller;

    @BeforeEach
    public void setup() {
        messageHandler = mock(MessageHandler.class);
        messageQueue = mock(MessageQueue.class);
        poller = new MessageQueuePoller(messageQueue, messageHandler);
    }

    @Test
    public void testRun() {
        Message mockMessage1 = mock(Message.class);
        Message mockMessage2 = mock(Message.class);
        when(mockMessage1.toJson()).thenReturn("{msg1}");
        when(mockMessage2.toJson()).thenReturn("{msg2}");
        when(messageQueue.dequeue()).thenReturn(mockMessage1).thenReturn(mockMessage2).thenReturn(null);

        Thread pollerThread = new Thread(poller);
        pollerThread.start();
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        poller.stop();

        verify(messageHandler, times(1)).handleMessage("{msg1}");
        verify(messageHandler, times(1)).handleMessage("{msg2}");
    }


}
