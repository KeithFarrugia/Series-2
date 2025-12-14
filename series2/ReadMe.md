# Clone Detection Project - Series II
## Directory Organisation

The project structure is organised for clarity, separating source code, configuration, and project data. Below is a table containing the directory structure within src.

| Directory/File | Purpose |
| :--- | :--- |
| `Utility/` | Contains common helper modules (.rsc) for tasks like writing files (Write), calculating lines of code (LinesOfCode), and generating summary statistics (Statistics). |
| `Clones/AST/` | Contains the Abstract Syntax Tree (AST)-based algorithms for clone detection (Type 1, 2, and 3).|
| `Clones/Token/` | Contains the Token-based algorithms for clone detection (Type 1, 2, and 3). |
| `Conf.rsc` | The main Configuration module. It defines project paths (rootPath), output file locations (clonesJson, linesJson), and Rascal data types used across the project. |
| `Main.rsc` | The project's Entry Point module. |

## Running the Project

The project is designed to be executed directly within the Rascal Terminal.

1.  **Open Rascal:** Launch the Rascal project.
2.  **Import the Project:** Ensure your current working directory in the terminal is the root of this project.
3.  **Run Main Module:** Execute the main Rascal module:
    ```rascal
    import main;
    main();
    ```
    This command initiates the clone detection process based on the settings defined in the `conf` directory.

## Configuration

Before running the project, you must adjust the configuration file in the `conf` directory to specify the target project you wish to analyse.

### Changing the Target Project

1.  Open the `Conf.rsc`
2.  Change the value of `projectRoot` to the project name or ID that you want to analyse.
3.  Change the value of `rootPath` to the project's absolute file path to match the equivalent location on your local filesystem.

## Results and Visualisations
Upon successful completion of the program, the Rascal terminal will display summary statistics, and two JSON files will be generated in the root directory (the same level as this `ReadMe.md`).

### Summary Statistics

The terminal output will provide performance and summary data, similar to the following format:

| Metric | Example Value | Description |
| :--- | :--- | :--- |
| **Time** | `9856 ms` | Total time taken for the entire clone detection, reported in milliseconds. |
| **Duplicated Lines** | `313` | The total number of unique duplicated lines of code found across all detected clone instances. |
| **Total Lines of Code** | `33859` | The total number of lines in the project source files. This count includes comments and blank lines to ensure an accurate base for calculating the duplication percentage, as clones often span through these elements. |

### Clone Type Breakdown

The output also tells the user which type of clone they chose to detect and the counts of each of the following:

* **Clone Classes:** A set of identified clones consisting of at least two instances that are related to each other.
* **Instances:** A sequence of identified duplicated lines of code corresponding to at least one other sequence (or instance) in the project.
* **Duplication Percentage:** The total percentage of the project's source code that is duplicated, calculated as: (Total Unique Duplicated Lines / Total Lines of Code in Project) * 100.

### Frontend Data Files

The following two JSON files are generated in the root project directory and need to be moved to the fronted/ directory for the visualisations to work:

1.  **`lines.json`**: Contains each source files information such as path and lines of code. This is needed to calculate the tree structures and other metrics.
2.  **`clones.json`**: Contains the full details of all detected clone classes and their instances.