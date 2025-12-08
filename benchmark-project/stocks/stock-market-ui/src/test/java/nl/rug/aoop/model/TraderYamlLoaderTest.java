package nl.rug.aoop.model;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.model.loaders.TraderYamlLoader;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
public class TraderYamlLoaderTest {
    @Test
    public void testLoadTraders() {
        Path path = Path.of("src/test/java/nl/rug/aoop/model/data/traders.yaml");
        TraderYamlLoader traderYamlLoader = new TraderYamlLoader(path);
        try {
            List<Trader> traders = traderYamlLoader.loadTraders();
            assertNotNull(traders);
            assertFalse(traders.isEmpty());
            log.info(traders.toString());
        } catch (IOException e) {
            fail("Exception should not be thrown: " + e.getMessage());
        }
    }
}
