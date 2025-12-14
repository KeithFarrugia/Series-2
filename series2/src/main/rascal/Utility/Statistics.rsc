module Utility::Statistics

import List;
import IO;
import Set;
import Map; 

import Conf;
import Utility::LinesOfCode;

// Retrieves the file path string from a Location data structure.
str getLocationFilePath(Location l) {
    return l.filePath;
}

/**
 * Sorts a list of Location records in ascending order based on the 'startLine' field.
 * Note: Uses selection sort.
 */
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

/**
 * Calculates the total number of unique lines covered by a set of Location ranges, 
 * merging any overlapping or adjacent ranges within the same file.
 * * This process involves:
 * 1. Grouping all Location ranges by their file path.
 * 2. Sorting the ranges within each file by their start line.
 * 3. Iterating through the sorted ranges, merging any where the next range's start 
 * is less than or equal to the current merged range's end line + 1.
 */
public int mergeRanges(set[Location] ranges) {
    // Grouping
    map[str, list[Location]] rangesByFile = ();

    for (l <- ranges) { // Iterate over all clone locations
        str file = l.filePath;
        if (file in rangesByFile) {
            rangesByFile[file] = rangesByFile[file] + [l];
        } else {
            rangesByFile[file] = [l];
        }
    } // Group ranges by their file path

    int totalUniqueLines = 0;
    
    for (filePath <- domain(rangesByFile)) { // Process one file at a time
        
        list[Location] fileRanges = rangesByFile[filePath]; 
        list[Location] sortedFileRanges = sortLocations(fileRanges); // Sort ranges by start line

        if (size(sortedFileRanges) == 0) continue;
        
        // Track start and end lines of the current source
        int currentStart = sortedFileRanges[0].startLine;
        int currentEnd = sortedFileRanges[0].endLine;
        
        if (size(sortedFileRanges) > 1) {
            for (i <- [1..size(sortedFileRanges)-1]) {  // Iterate through the rest of the ranges
                Location next = sortedFileRanges[i];
                
                // Check for overlap (inclusive end lines)
                if (next.startLine <= currentEnd + 1) { // Ranges are overlapping or adjacent
                    // Update the end line if the next range extends it
                    if (next.endLine > currentEnd) {
                        currentEnd = next.endLine; // Extend the merged range end
                    }
                } else {
                    // No overlap: Finalise the current merged range, add its length, and start a new one
                    int rangeLength = currentEnd - currentStart + 1;
                    totalUniqueLines += rangeLength; // Add length of the finished merged range
                    
                    // Start a new range
                    currentStart = next.startLine;
                    currentEnd = next.endLine;
                }
            }
        }
        
        // The last merged/unmerged range must be counted after the loop finishes.
        int rangeLength = currentEnd - currentStart + 1;
        totalUniqueLines += rangeLength; // Add length of the final merged range
    }
    
    return totalUniqueLines;
}

/**
 * Calculates and prints needed statistics for a specified type of clones in the project.
 * * Statistics include:
 * - Total number of unique duplicated lines (by merging overlapping ranges).
 * - Total lines of code in the project.
 * - Number of clone classes and instances for the specified clone type.
 * - Duplication percentage based on unique duplicated lines.
 */
public void printStatisticsForProject(list[Clone] projectClones, int cloneType) {
    // total lines in the project
    int totalLinesOfCode = totalProjectLOC();

    list[Clone] typeXClones = [c | c <- projectClones, c.cloneType == cloneType];
    int typeXClasses = size(typeXClones);
    
    int typeXInstances = sum([size(c.locations) | c <- typeXClones]);

    // Collect all unique Location objects
    set[Location] allLocations = {};
    for (Clone c <- typeXClones) {
        allLocations += toSet(c.locations);
    }
    
    // Merge overlapping line ranges and calculate sum
    int typeXDuplicatedLines = mergeRanges(allLocations);
    
    println("Duplicated Lines: <typeXDuplicatedLines>");
    
    // Calculate Duplication Percentage based on unique lines
    // Capping added to ensure percentage is not > 100% just in case
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