package nl.rug.aoop.messagequeue;

import nl.rug.aoop.messagequeue.commands.NetworkProducer;
import nl.rug.aoop.networking.Client.Client;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.lang.reflect.Field;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;

public class TestNetworkProducer {

    private NetworkProducer networkProducer;
    private Client mockClient;

    @BeforeEach
    public void setUp() {
        mockClient = Mockito.mock(Client.class);
        networkProducer = new NetworkProducer(mockClient);
    }

    @Test
    public void testConstructor() throws NoSuchFieldException, IllegalAccessException {
        assertNotNull(networkProducer);
    }

    @Test
    public void testPut() {
        Message sampleMessage = new Message("TestHeader", "TestBody");

        // Call the put method on NetworkProducer
        networkProducer.put(sampleMessage);
        // Verify that the send method of the Client was called with the expected argument
        verify(mockClient).send(Mockito.anyString());
    }
}
