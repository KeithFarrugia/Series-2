package nl.rug.aoop.messagequeue;

import com.google.gson.*;

import java.lang.reflect.Type;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * This adapter is used to adapt the "LocalDateTime" object to the serializer and deserializer so that it can be
 * turned into a JSON format and back.
 */
public class LocalDateTimeAdapter implements JsonSerializer<LocalDateTime>, JsonDeserializer<LocalDateTime> {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("d-MM-uuuu HH:mm:ss.nnnnnnnnn");

    @Override
    public LocalDateTime deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context)
            throws JsonParseException {
        return LocalDateTime.parse(json.getAsString(),
                FORMATTER.withLocale(Locale.ENGLISH));
    }

    @Override
    public JsonElement serialize(LocalDateTime localDateTime, Type srcType, JsonSerializationContext context) {
        return new JsonPrimitive(FORMATTER.format(localDateTime));
    }
}
