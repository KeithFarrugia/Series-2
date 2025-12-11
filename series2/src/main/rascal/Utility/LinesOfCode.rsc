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
public ProjectMetrics getAllFilesFromProjectRoot() {
    set[loc] allFiles = files(projectRoot);
    set[loc] allJavaFiles = {
        f 
        | f <- allFiles,
        contains(f.path,".java") && !contains(f.path,"/test/")
    };

    // Map: str (ModuleName) -> list[FileMetrics]
    map[str, list[FileMetrics]] moduleFileMap = ();
    
    // 2. Iterate through files, calculate LOC, and categorize into modules.
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
        
        // 2. Get the name of the package one level up from the immediate parent
        loc grandParentLoc = parentLoc.parent;
        str grandParentName = grandParentLoc.file;
        
        if (rootIndex != -1 && rootIndex + 1 < size(pathParts)) {
            str coreModuleName = pathParts[rootIndex + 1];

            // Check if the file's immediate parent is a sub-package (e.g., 'dumb')
            if (immediateParentName != coreModuleName) {
                // If the parent name is not the core module name, use the parent name
                // UNLESS the parent name is something like 'java' or 'main'
                if (immediateParentName != "java" && immediateParentName != "main") {
                    moduleName = immediateParentName; // e.g., "dumb"
                } else {
                    moduleName = coreModuleName; // Fall back to "sigmetrics"
                }
            } else {
                // The file is directly in the core package (e.g., App.java in sigmetrics)
                moduleName = coreModuleName; // "sigmetrics"
            }
        } else {
             // Fallback for files outside of the common 'org'/'com' structure
             moduleName = immediateParentName;
        }
        
        // 3. Create the FileMetrics data structure
        int locCount = countLinesOfCode(fileLoc);
        
        FileMetrics fm = fileMetrics(
            fileName, 
            stripRootPrefix(fileLoc), 
            locCount
        );
        
        // 4. Add the file to the module map
        if (moduleName in moduleFileMap) {
            moduleFileMap[moduleName] += fm;
        } else {
            moduleFileMap[moduleName] = [fm];
        }
    }
    
    // 5. Convert the map into a list of ModuleMetrics
    // Get the set of keys and convert it to a sorted list
    list[str] sortedModuleNames = sort([name | name <- moduleFileMap]); 
    // ^ In Rascal, using a map as a generator source defaults to iterating over its keys.

    list[ModuleMetrics] modulesList = [
        moduleMetrics(name, moduleFileMap[name]) 
        | name <- sortedModuleNames // Iterate over the sorted list of names
    ];
    
    // 6. Return the final ProjectMetrics structure
    return projectMetrics(stripProjectPrefix(projectRoot), modulesList);
}

/* ============================================================================
 *                              countLinesOfCode
 * ----------------------------------------------------------------------------
 *  Reads a source file from a given location, cleans it using normaliseContent,
 *  splits it into lines, removes empty lines, and counts the remaining lines.
 * ============================================================================
 */
public int countLinesOfCode(loc location) {
    str rawContent = readSingleFile(location);

    list[str] codeLines = split("\n", rawContent);
    codeLines = [line | line <- codeLines];
    
    // Return the number of lines of code
    return size(codeLines);
}

str stripProjectPrefix(loc location) {
    str fullPath = location.uri;
    str cleaned = replaceAll(fullPath, "project://", "");

    return cleaned;
}

str stripRootPrefix(loc location) {
    str rootPath = projectRoot.uri;
    str fullPath = location.uri;
    str cleaned = replaceAll(fullPath, rootPath + "/", "");

    return cleaned;
}
