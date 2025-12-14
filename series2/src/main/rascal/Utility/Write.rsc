module Utility::Write

import IO;
import Conf;
import String;
import Grammar;
import lang::json::IO;

// Writes a list of clones to a json to be consumed by the frontend
void writeClonesToJson(list[Clone] clonesList) {
    // Create the top-level ProjectClones data structure
    ProjectClones projectData = projectClones(rootPath, clonesList);
    
    // Write the structure directly to the file as JSON
    // We use an indent of 2 for pretty-printing, and dropOrigins=true 
    // to ensure clean JSON output without Rascal internal metadata.
    writeJSON(clonesJson, projectData, indent=2, dropOrigins=true);
}

// Same Logic as writeClones
void writeLinesOfCodeToJson(ProjectMetrics projectMetrics) {
    writeJSON(linesJson, projectMetrics, indent=2, dropOrigins=true);
}