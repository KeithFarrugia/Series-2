package nl.rug.aoop.model.loaders;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.Trader;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

/**
 * This class is used to load data the data primarily using the YamlLoaders of certain classes.
 *
 */
@Slf4j
public class DataLoader {

    /**
     * empty constructor to help call the class.
     *
     */
    public DataLoader() {
    }

    /**
     * Loads the traders and stores them in a list.
     *
     * @return the traders
     */
    public List<Trader> loadTraders() {

        Path yamlFilePath = Path.of("data" + File.separator + "traders.yaml");

        TraderYamlLoader traderYamlLoader = new TraderYamlLoader(yamlFilePath);
        try {
            return traderYamlLoader.loadTraders();
        } catch (IOException e) {
            log.error("Error occurred while loading traders: " + e.getMessage());
        }
        return null;
    }

    /**
     * Loads the stocks and stores them in a list.
     *
     * @return the stocks.=
     */
    public List<Stock> loadStocks() {
        Path yamlFilePath = Path.of("data" + File.separator + "stocks.yaml");
        StockYamlLoader stockYamlLoader = new StockYamlLoader(yamlFilePath);
        try {
            return stockYamlLoader.loadStocks();
        } catch (IOException e) {
            log.error("Error occurred while loading stocks: " + e.getMessage());
        }
        return null;
    }
}

