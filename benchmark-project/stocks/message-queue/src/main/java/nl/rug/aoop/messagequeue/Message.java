package nl.rug.aoop.messagequeue;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * Messages store text information as well as the time they were created on.
 */
@Getter
public class Message implements Comparable<Message> {
    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDateTime.class, new LocalDateTimeAdapter())
            .create();
    private final String header;
    private final String body;
    private final LocalDateTime timestamp;

    /**
     * The header and the message body that was input into the method is stored along the time the message was created.
     *
     * @param messageHeader header of the message
     * @param messageBody   body text of the message
     */
    public Message(String messageHeader, String messageBody) {
        this.header = messageHeader;
        this.body = messageBody;
        this.timestamp = LocalDateTime.now();
    }

    /**
     * takes a string (formatted in a json format) and turns it into the corresponding message object.
     *
     * @param json the string formatted in json format
     * @return object corresponding to the json
     */
    public static Message fromJson(String json) {
        return GSON.fromJson(json, Message.class);
    }

    /**
     * Serializes the object and turns into a JSON format.
     *
     * @return string corresponding to the json
     */
    public String toJson() {
        return GSON.toJson(this);
    }

    public String getHeader() {
        return header;
    }

    public String getBody() {
        return body;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    @Override
    public int compareTo(Message message) {
        return this.getTimestamp().compareTo(message.getTimestamp());
    }
}
