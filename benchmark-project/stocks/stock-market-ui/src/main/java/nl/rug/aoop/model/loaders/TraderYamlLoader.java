package nl.rug.aoop.model.loaders;

import nl.rug.aoop.model.Trader;
import nl.rug.aoop.util.YamlLoader;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

/**
 * Loads the Traders into a Trader list.
 */
public class TraderYamlLoader {
    private final YamlLoader yamlLoader;

    /**
     * Sets the yamlLoader with a file Path.
     *
     * @param yamlFilePath path to look in.
     */
    public TraderYamlLoader(Path yamlFilePath) {
        this.yamlLoader = new YamlLoader(yamlFilePath);
    }

    /**
     * Loads the traders and returns the loaded trader list.
     *
     * @return returns the trader list.
     * @throws IOException in case traders could not be loaded.
     */
    public List<Trader> loadTraders() throws IOException {
        return yamlLoader.load(TraderList.class).getTraders();
    }

    /**
     * Used to load the traders into a List.
     */
    private static class TraderList {
        private List<Trader> traders;

        public List<Trader> getTraders() {
            return traders;
        }
    }
}
