package nl.rug.aoop.messagequeue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;


public class TestMessage {

    private Message message;
    private String messageHeader;
    private String messageBody;
    private String messageJson;


    @BeforeEach
    void setUp() {
        messageHeader = "header";
        messageBody = "body";
        message = new Message(messageHeader, messageBody);
    }


    @Test
    void testMessageConstructor() {
        assertEquals(messageHeader, message.getHeader());
        assertEquals(messageBody, message.getBody());
        assertNotNull(message.getTimestamp());
    }

    @Test
    void testMessageImmutable() {
        List<Field> fields = List.of(Message.class.getDeclaredFields());
        fields.forEach(field -> {
            assertTrue(Modifier.isFinal(field.getModifiers()), field.getName() + " is not final");
        });
    }

    @Test
    public void testToJson() {
        Message message = new Message("header", "body");
        messageJson = "{\"header\":\"header\",\"body\":\"body\",\"timestamp\":\"" + message.getTimestamp().format(DateTimeFormatter.ofPattern("d-MM-uuuu HH:mm:ss.nnnnnnnnn")) + "\"}";
        String json = message.toJson();
        assertEquals(messageJson, json);
    }

    @Test
    public void testFromJson() {
        String json = "{\"header\":\"header\",\"body\":\"body\",\"timestamp\":\"28-09-2023 18:40:30.043474275\"}";

        Message message = Message.fromJson(json);

        assertEquals("header", message.getHeader());
        assertEquals("body", message.getBody());
        assertEquals(LocalDateTime.of(2023, 9, 28, 18, 40, 30, 43474275), message.getTimestamp());
    }
}
