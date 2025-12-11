module Utility::Statistics

import List;
import IO;
import Set;
import Map; 

import Conf;
import Utility::LinesOfCode;


// *****************************************************************
// NAMED HELPER FUNCTIONS (To replace grouping and sorting logic)
// *****************************************************************

// Helper function for grouping ranges by file path
str getLocationFilePath(Location l) {
    return l.filePath;
}

// Helper function to manually sort locations by startLine (Selection Sort replacement)
list[Location] sortLocations(list[Location] locations) {
    list[Location] sorted = [];
    list[Location] remaining = locations; 

    while (size(remaining) > 0) {
        int min_idx = 0;
        int min_startLine = remaining[0].startLine;
        
        for (i <- index(remaining)) {
            if (remaining[i].startLine < min_startLine) {
                min_startLine = remaining[i].startLine;
                min_idx = i;
            }
        }
        
        sorted += [remaining[min_idx]];
        
        list[Location] newRemaining = [];
        for (j <- index(remaining)) {
            if (j != min_idx) {
                newRemaining += [remaining[j]];
            }
        }
        remaining = newRemaining;
    }
    return sorted;
}


// *****************************************************************
// MERGE RANGES FUNCTION (FINAL FIX: Map Iteration)
// *****************************************************************
public int mergeRanges(set[Location] ranges) {
    // 1. Manual Grouping
    map[str, list[Location]] rangesByFile = ();

    for (l <- ranges) {
        str file = l.filePath;
        if (file in rangesByFile) {
            rangesByFile[file] = rangesByFile[file] + [l];
        } else {
            rangesByFile[file] = [l];
        }
    }

    int totalUniqueLines = 0;
    
    for (filePath <- domain(rangesByFile)) {
        
        list[Location] fileRanges = rangesByFile[filePath]; 
        list[Location] sortedFileRanges = sortLocations(fileRanges);

        if (size(sortedFileRanges) == 0) continue;
        
        // Use simple integers to track the merged range extent
        int currentStart = sortedFileRanges[0].startLine;
        int currentEnd = sortedFileRanges[0].endLine;
        
        if (size(sortedFileRanges) > 1) {
            for (i <- [1..size(sortedFileRanges)-1]) { 
                Location next = sortedFileRanges[i];
                
                // Check for overlap (inclusive end lines)
                if (next.startLine <= currentEnd + 1) {
                    // MERGE: Update the end line if the next range extends it
                    if (next.endLine > currentEnd) {
                        currentEnd = next.endLine;
                    }
                } else {
                    // NO OVERLAP: Finalize the current merged range, add its length, and start a new one
                    int rangeLength = currentEnd - currentStart + 1;
                    totalUniqueLines += rangeLength;
                    
                    // Start a new range
                    currentStart = next.startLine;
                    currentEnd = next.endLine;
                }
            }
        }
        
        // FINALIZATION: The last merged/unmerged range must be counted after the loop finishes.
        int rangeLength = currentEnd - currentStart + 1;
        totalUniqueLines += rangeLength;
    }
    
    return totalUniqueLines;
}

public void printStatisticsForProject(list[Clone] projectClones, int cloneType) {
    // total lines in the project
    int totalLinesOfCode = totalProjectLOC();

    list[Clone] typeXClones = [c | c <- projectClones, c.cloneType == cloneType];
    int typeXClasses = size(typeXClones);
    
    int typeXInstances = sum([size(c.locations) | c <- typeXClones]);

    // 1. Collect all unique Location objects
    set[Location] allLocations = {};
    for (Clone c <- typeXClones) {
        allLocations += toSet(c.locations);
    }
    
    // 2. Merge overlapping line ranges and calculate sum in one go (returns INT)
    int typeXDuplicatedLines = mergeRanges(allLocations);
    
    println("Duplicated Lines: <typeXDuplicatedLines>");
    println("Total LOC: <totalLinesOfCode>");

    // 4. Calculate Duplication Percentage based on unique lines
    // Capping added to ensure percentage is not > 100% due to LOC definition
    int actualDuplicatedLines = typeXDuplicatedLines;
    if (actualDuplicatedLines > totalLinesOfCode) {
        actualDuplicatedLines = totalLinesOfCode;
    }

    real typeXDuplication = 0.0;
    if (totalLinesOfCode > 0) {
        typeXDuplication = 100.0 * actualDuplicatedLines / totalLinesOfCode;
    }

    println("Project statistics:");
    println("Total lines of code: <totalLinesOfCode>");
    println("");
    println("Type-<cloneType> clones: <typeXClasses> clone classes, <typeXInstances> instances, <typeXDuplication>% duplication");
}