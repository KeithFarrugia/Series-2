FROM --platform=linux/amd64 maven:3.8.3-openjdk-17

COPY . ./

RUN mvn package -Dmaven.test.skip -Dcheckstyle.skip
ENTRYPOINT ["java", "-cp", "stock-market-ui/target/stock-market-ui-1.0-SNAPSHOT-jar-with-dependencies.jar", "nl.rug.aoop.initialization.StockApplication"]
