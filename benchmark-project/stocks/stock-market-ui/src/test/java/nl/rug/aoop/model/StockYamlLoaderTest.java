package nl.rug.aoop.model;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.model.loaders.StockYamlLoader;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
public class StockYamlLoaderTest {

    @Test
    public void testLoadStocks() {
        Path path = Path.of("src/test/java/nl/rug/aoop/model/data/stocks.yaml");
        StockYamlLoader stockYamlLoader = new StockYamlLoader(path);
        try {
            List<Stock> stocks = stockYamlLoader.loadStocks();
            assertNotNull(stocks);
            assertFalse(stocks.isEmpty());
            log.info(stocks.toString());
        } catch (IOException e) {
            fail("Exception should not be thrown: " + e.getMessage());
        }
    }
}
