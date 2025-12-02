module Utility::Write

import IO;
import Conf;
import String;
import Grammar;
import lang::json::IO;

// loc1 = location("src/main/java/org/sigmetrics/Calculator.java", 13, 19);
// loc2 = location("src/main/java/org/sigmetrics/Duplication.java", 14, 20);
// loc3 = location("src/main/java/org/sigmetrics/Duplication.java", 13, 19);

// loc4 = location("src/main/java/org/sigmetrics/Duplication.java", 5, 10);
// loc5 = location("src/main/java/org/sigmetrics/Complexity.java", 14, 23);

// list[Location] locs1 = [
//     loc1,
//     loc2,
//     loc3
// ];

// list[Location] locs2 = [
//     loc4,
//     loc5
// ];

// clone1 = clone(locs1, 7, 1, "c1", "Exact Match");
// clone2 = clone(locs2, 6, 2, "c2", "Near-Miss");
// clonesList = [clone1, clone2];

// Define a function that creates the JSON structure and returns it as a string
void writeClonesToJson(list[Clone] clonesList) {
    // 1. Define the project root path
    str rootPath = "/dev/software_evo/Series-2/sig-metrics-test";

    // 2. Create the top-level ProjectClones data structure
    ProjectClones projectData = projectClones(rootPath, clonesList);
    
    // 3. Write the structure directly to the file as JSON
    // We use an indent of 2 for pretty-printing, and dropOrigins=true 
    // to ensure clean JSON output without Rascal internal metadata.
    writeJSON(clonesJson, projectData, indent=2, dropOrigins=true);
}