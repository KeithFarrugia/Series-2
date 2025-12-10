module Utility::Statistics

import List;
import IO;

import Conf;
import Utility::LinesOfCode;

public void printStatisticsForProject(list[Clone] projectClones, int cloneType) {
    // total lines in the project
    int totalLinesOfCode = totalProjectLOC();

    list[Clone] typeXClones = [c | c <- projectClones, c.cloneType == cloneType];
    int typeXClasses = size(typeXClones);
    int typeXInstances = sum([size(c.locations) | c <- typeXClones]);

    int typeXDuplicatedLines = sum([size(c.locations) * c.fragmentLength | c <- typeXClones]);
    real typeXDuplication = 100.0 * typeXDuplicatedLines / totalLinesOfCode;


    println("Project statistics:");
    println("Total lines of code: <totalLinesOfCode>");
    println("");
    println("Type-<cloneType> clones: <typeXClasses> clone classes, <typeXInstances> instances, <typeXDuplication>% duplication");
}
