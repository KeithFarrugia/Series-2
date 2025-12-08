<br />
<p align="center">
  <h1 align="center">Stock Market Simulation</h1>

  <p align="center">
    Project that simulates a simple stock market using a network
  </p>
</p>

## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
  * [Running](#running)
* [Modules](#modules)
* [Notes](#notes)
* [Evaluation](#evaluation)
* [Extras](#extras)

## About The Project

This project is a StockApplication that initializes some traderbots and has them interact with the stockApplication (simulating a stockMarket) over a network.

## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

* [Java 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) or higher
* [Maven 3.6](https://maven.apache.org/download.cgi) or higher

### Installation

1. Navigate to the `stocks` directory
2. Clean and build the project using:
```sh
mvn install
```

### Running

You should use the multirun plugin for intellij, or run the following mains:
StockApplication (for starting the server and services of the stockApp)
ViewApplication (for getting a visual representation of the stocks and traders)
TraderApp (to start some traderBots that interact with the stock market using a strategy)

## Modules
# Command
The command module is used to set up the basic infrastructure of handling commands. It contains the command interface and a CommandHandler which registers and executes
given commands.

# message-queue
This module is used to set up any infrastructure that requires interacting with a message queue and contains multiple classes.
The submodule commands in message-queue is responsible for holding any commands related to networking and message queue operations.
In the rest of the message queue module there are interfaces and classes used for instantiating queues and messages as well as a producer
and consumer class to help interact with a queue. 

The available queues from this module are:
OrderedQueue: orders messages according to their LocalDateTime, the messages are put on a list corresponding to their time and sorted with a treemap.
UnorderedQueue: orders messages based on when they are pushed into the queue
TimestampedPriorityBlockingQueue: similar to the ordered queue but uses a priority blocking queue so that it is more thread safe

# networking
This module contains the implementations for the Client, ClientHandler and Server as well as interfaces for the ResponseHandler and MessageHandler which are used to
send responses back to the client and handle messages respectively.
The client is responsible for connecting to the server and providing the functionality to allow incoming messages to be handled as well as send messages to the server.
The server is a simple server implementation that spawns a clientHandler whenever a client connect to handle the interactions for that client.
The clientHandler is used to handle interactions with a client. It can send messages to the client and delegates message handling to a message handler

# util
This is a simple module that contains a YamlLoader, allowing us to create simple loaders for stocks and traders within the stock-market-ui module

# stock-market-ui
this contains four submodules each aimed at different aspects of functionality to the app
Simpleview: this module is simply just used to create models, tables, frames such that later in the initialization module 
we can provide the user with an interface to observe the changes to the stockApp being made by the bots


model: this module contains 2 submodules called loaders and managers. The loader submodule is used to load the traders and the stocks from yaml. There are
3 classes in this module and. StockYamlLoader and TraderYamlLoader which load and return a List of stocks or traders depending on the class called from yaml.
The DataLoader class simplifies the call needed to load the stocks by having a hard coded path inside it and allowing other classes to just call loadStock/Trader
and have a list of stocks and traders from the yaml files available. 
The manager submodule is used to hold classes that perform operations on their respective nameManager such as getTraderByIndex, for stockExchange. 
Through stockExchange the 3 classes (OrderManager, StockManager, TraderManager) are used performing operations that are needed inside stockExchange.

The rest of the model module contains important interfaces and their needed implementation. 
The class Stock implements StockDataModel, and is used to identify a stock, and it's attributes
The class Trader implements TraderDataModel, and is used to keep the information regarding a trader and what that trader owns.
The class StockExchange implements StockExchangeDataModel and represents the core functionality of the stock exchange model. 
It aggregates the management of stocks, traders, and orders within the stock exchange. The class is constructed with a list of stocks 
and traders and initializes managers for each of these entities, which as described earlier provide support functions for this class.


control: this module contains classes that handle the stockApp's networking and order functionality. 
It has a submodule called 
commands which provide implementations of command called SellLimit and BuyLimit which are used to resolve buy and sell orders. 
They contain the logic to match orders, execute trades, and update traders and stocks involved. The LimitSupport class serves as our
utility class that provides helper methods to facilitate the order processing.

The other 2 classes in the module (not the submodule commands) are the following:
IncomingOrderMessageHandler is used to process incoming network messages, convert them back into order messages, 
and designate them to the appropriate command using the CommandHandler
OrderNetworkHandler is used to prepare and enqueue orders using the NetworkProducer.

initialization: this is the last module in the stock-market-ui module and contains the final pieces for our stock and view application.
It contains an AbstractViewFactory interface which is used by the SimpleViewFactory to create a simple view that can be used by our ViewApplication
to create a view on the stock exchange. The ViewApplication class contains a main that creates a new SimpleViewFactory and passes the stockExchange which has it's traders
and stocks loaded from the provided yaml files.

For the StockApplication part it contains 4 classes, the first is the StockApplication which calls the StockApplicationInitializer to simplify the main. The last
few lines of code in this main call the initializers: startPollingAndSendingUpdates() every 2 seconds to do as the name implies, poll the message queue and send 
the relevant updates to the clients. This module relies heavily on all the previous modules especially networking. 
The StockApplicationInitializer simplifies the UpdateSender and MessageQueuePoller and combines them to make calling this part of the code easier.
This class also starts the server on the required port, creates the stockExchange from the loaded yaml files and starts up a message queue using the 
TimestampedPriorityBlockingQueue. UpdateSender sends a string to each traderBot containing their trader info and info on all current stocks and stock info.
MessageQueuePoller then polls the message-queue and then forwards the message contents as JSON strings to the specified MessageHandler for processing.

TraderApp: this is the last module in our project and contains the bots that when the main is started are initialized and interact with the stock application
using the random strategy developed.
The strategy submodule contains the class RandomStrategy which implements the strategy interface. A trader and available stocks are provided as input to 
this strategy. Based on the requirements from the assignment the RandomStrategy class randomly decides between buy and sell order types, selects a random 
stock from the available stocks list, and determines an order amount. Then it calculates the order price with a 1% markup or markdown based on whether it's a buy or sell order, respectively.
TraderBot class is contains the functions of the trader bots we'd like to initialize. These bots follow a specified strategy to generate orders. 
When run, the bot randomly waits between 1 to 4 seconds and then generates a trading order according to it's strategy, sending this order to the
message queue. The bot is created with an ID and a strategy and sets up its network connection parameters, including its connection to the command 
handler via IncomingOrderMessageHandler.
TraderBotInitializer class initializes the bots for the TraderApp. Given a list of traders and stocks, it starts each trader bot with the RandomStrategy, 
and runs the bots in individual threads.
Lastly the TraderApp class contains the main for the application. Here, data for traders and stocks is loaded using DataLoader.
Then a TraderBotInitializer instance is created to initialize and connect all trader bots, thus kick-starting the automated trading process.

## Design

Command Pattern:
This pattern was started in the command module with the command interface which is used by the command handler. Both of these are then used in other modules to execute commands.
We decided to use this pattern to encapsulate certain requests as objects (the command), and have that request delegated to the commandHandler instead of executing it directly.
Classes that implement command are BuyLimit and SellLimit in the stock-market-ui module,MqPollCommand and MqPutCommand. Their uses are described in previous documentation
and in javadoc within the classes themselves but basically these are examples of commands that need to be executed when called. The next pattern helps with
executing these commands in an easier way.

Factory Pattern:
The factory pattern is used in the stock-market-ui module to register a set of commands that need to be executed while the program is running. It is also used
in the same module to initialize a simple view. The scope of using the factory pattern was to create a simple call when a traderBot wants to execute a command.
There are 2 factories in place for this, the MqCommandFactory; which handles commands relating to the message-queue, and OrderCommandFactory; which handles
the commands for buy and sellLimit. This pattern is useful as it provides a simpler interface for executing the commands as well as improving maintainability 
as if more commands need to be added, they can be registered in the factory.

Strategy Pattern:
This is only used within the TraderApp module. It's use case is to create a strategy for trading for the trader bots. So far the only implementation of this 
is the RandomStrategy class. The scope of using the strategy pattern here is such that in the future if more strategies need to be added then there is a simple interface
which each strategy for trading requires. Thus, different bots in the future may use different strategies for trading allowing for improved maintainability and
decoupling of how a bot determines what order to place, and how it places that order.


## Evaluation

In this project, BotTraders have been configured to interact with the stock market within the StockApplication. TraderBots place orders on the stock market,
adhering to the following rules: the order must be random, and traders cannot sell more stocks than they possess nor initiate buy orders that exceed their 
available funds.

While we believe we have met the general objectives of the assignment, granted there is still a lot of room for improvement and further optimization. 
However due to constraints like impending exam schedules and other assignment deadlines, combined with the project serving as a learning 
experience (learn on the go style), we couldn't fully address certain features.

That being said some areas of potential improvement include:

1: Enhanced Testing: While we did skip some tests by running the mains to ensure the absence of particular errors, more comprehensive edge-case testing 
for the stock-market-ui module and further trader testing would have been better. This limitation stemmed from time constraints rather than a lack of expertise.

2: Connection Handling: The networking module could be enhanced to better handle client disconnections. A reconstruction of the client handler and 
server could lead to improved event handling.

3: Network Consumer: Implementing a network consumer would be advantageous so as not to assume the queue operates locally. This integrates some of 
the previously highlighted challenges.

4: Order Command Design: The current design of the order command implementations could have been further segmented. As it stands, we feel that it 
may not strictly adhere to the single responsibility principle.

5: Strategic TraderBots: Once the aforementioned issues are tackled, it would be insightful to introduce more complex strategies for TraderBots 
aimed at revenue maximization. This could involve testing different strategies by having sets of bots compete, each set adopting a unique approach. 
Additionally, commands for more intricate order types like stop or stop-limit orders could be integrated.

While there might be other potential enhancements we've overlooked, we are confident that we've satisfied the core requirements of the assignment.

## Extras

Attached there should also be a UML Diagram providing a clearer explanation of how the components of the project interact with eachother

## Contact 
j.ellul@student.rug.nl 
d.o.ozdemir@student.rug.nl

