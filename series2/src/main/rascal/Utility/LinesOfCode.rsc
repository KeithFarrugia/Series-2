module Utility::LinesOfCode

import Conf;
import Utility::CleanCode;
import Utility::Reader;

import IO;
import List;
import String;
import Set;
import util::FileSystem;

import lang::java::m3::Core;
import lang::java::m3::AST;
import Conf;


/* ============================================================================
 *                           totalProjectLOC
 * ----------------------------------------------------------------------------
 * Returns the total LOC in the project excluding test files
 * We exclude test files as the annotation crash this project due to some
 * issues in the java M3 AST, since these are not included in our cloning analysis
 * ============================================================================
 */
public int totalProjectLOC(){
    set[loc] allFiles = files(projectRoot);
    set[loc] allJavaFiles = {
        f 
        | f <- allFiles,
        contains(f.path,".java") && !contains(f.path,"/test/")
    };

    set[int] locsPerFile = {
        countLinesOfCode(fileLoc) 
        | fileLoc <- allJavaFiles 
    };
    
    // Sum all the individual LoC counts to get the total project volume.
    return sum(locsPerFile);

}

/* ============================================================================
 *                           getAllFilesFromProjectRoot
 * ----------------------------------------------------------------------------
 * Gathers and structures file and module metrics into the ProjectMetrics 
 * data structure (defined in Conf.rsc).
 * This involves:
 *  1. Finding all non-test Java files in the project root.
 *  2. Iterating over the files to calculate their LOC and determine their 
 *     logical module name.
 *  3. Grouping the files into a map of Module Name -> list[FileMetrics].
 *  4. Converting the map into the final list[ModuleMetrics] structure.
 * 
 *  * This data is used to create the 'lines.json' file for the frontend by 
 *    returning
 *  * a ProjectMetrics record containing the complete file/module structure.
 * ============================================================================
 */
public ProjectMetrics getAllFilesFromProjectRoot() {
    set[loc] allFiles = files(projectRoot);
    set[loc] allJavaFiles = {
        f 
        | f <- allFiles,
        contains(f.path,".java") && !contains(f.path,"/test/")
    };

    // Map: str (ModuleName) -> list[FileMetrics]
    map[str, list[FileMetrics]] moduleFileMap = ();
    
    // Iterate through files, calculate LOC, and categorise into modules.
    for (loc fileLoc <- allJavaFiles) {
        str filePathStr = fileLoc.uri; 
        list[str] pathParts = split("/", filePathStr);
        int rootIndex = -1;
        for (i <- [0..size(pathParts)] ) {
            if (pathParts[i] == "org") {
                rootIndex = i;
                break;
            }
        }
        
        str moduleName = "Unknown_Module";
        str fileName = fileLoc.file;
        
        loc parentLoc = fileLoc.parent;
        str immediateParentName = parentLoc.file;
        
        // Get the name of the package one level up from the immediate parent
        loc grandParentLoc = parentLoc.parent;
        str grandParentName = grandParentLoc.file;
        
        if (rootIndex != -1 && rootIndex + 1 < size(pathParts)) {
            str coreModuleName = pathParts[rootIndex + 1];

            // Check if the file's immediate parent is a sub-package
            if (immediateParentName != coreModuleName) {
                // If the parent name is not the core module name, use the parent name
                // unless the parent name is something like 'java' or 'main'
                if (immediateParentName != "java" && immediateParentName != "main") {
                    moduleName = immediateParentName; 
                } else {
                    moduleName = coreModuleName;
                }
            } else {
                // The file is directly in the core package
                moduleName = coreModuleName; 
            }
        } else {
             // Fallback for files outside of the common 'org'/'com' structure
             moduleName = immediateParentName;
        }
        
        // Create the FileMetrics data structure
        int locCount = countLinesOfCode(fileLoc);
        
        FileMetrics fm = fileMetrics(
            fileName, 
            stripRootPrefix(fileLoc), 
            locCount
        );
        
        // Add the file to the module map
        if (moduleName in moduleFileMap) {
            moduleFileMap[moduleName] += fm;
        } else {
            moduleFileMap[moduleName] = [fm];
        }
    }
    
    // Convert the map into a list of ModuleMetrics
    // Get the set of keys and convert it to a sorted list
    list[str] sortedModuleNames = sort([name | name <- moduleFileMap]); 

    list[ModuleMetrics] modulesList = [
        moduleMetrics(name, moduleFileMap[name]) 
        | name <- sortedModuleNames // Iterate over the sorted list of names
    ];
    
    // Return the final ProjectMetrics structure
    return projectMetrics(stripProjectPrefix(projectRoot), modulesList);
}

/**
 * Reads a file and returns the total lines in that file, 
 */
public int countLinesOfCode(loc location) {
    str rawContent = readSingleFile(location);

    list[str] codeLines = split("\n", rawContent);
    codeLines = [line | line <- codeLines];

    return size(codeLines);
}

/* ============================================================================
 *                           stripProjectPrefix
 * ----------------------------------------------------------------------------
 *  Remove 'project://' prefix from a file location URI.
 * ============================================================================
 */
str stripProjectPrefix(loc location) {
    str fullPath = location.uri;
    str cleaned = replaceAll(fullPath, "project://", "");

    return cleaned;
}

/* ============================================================================
 *                           stripRootPrefix
 * ----------------------------------------------------------------------------
 * Remove the project root prefix from a file location URI.
 * ============================================================================
 */
str stripRootPrefix(loc location) {
    str rootPath = projectRoot.uri;
    str fullPath = location.uri;
    str cleaned = replaceAll(fullPath, rootPath + "/", "");

    return cleaned;
}
