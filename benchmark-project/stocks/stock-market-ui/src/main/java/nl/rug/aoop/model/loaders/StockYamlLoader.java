package nl.rug.aoop.model.loaders;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.util.YamlLoader;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

/**
 * Loads the stock information from a yaml file.
 */
@Slf4j
public class StockYamlLoader {
    private final YamlLoader yamlLoader;

    /**
     * Initializes the Yaml loader with a path.
     *
     * @param path the path to the yaml file.
     */
    public StockYamlLoader(Path path) {
        this.yamlLoader = new YamlLoader(path);
    }

    /**
     * This method loads the stocks inside the yaml file.
     *
     * @return the list of loaded stocks
     * @throws IOException if it fails to load
     */
    public List<Stock> loadStocks() throws IOException {
        return yamlLoader.load(StockList.class).getStocks();
    }

    /**
     * Used to load the stocks into a List.
     */
    private static class StockList {
        private List<Stock> stocks;

        /**
         * Gets the list of stocks.
         *
         * @return the list of stocks.
         */
        public List<Stock> getStocks() {
            return stocks;
        }
    }
}
