module Utility::Reader

import IO;
import String;
import List;
import Set;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Utility::CleanCode;
import analysis::m3::FlowGraph;
import analysis::graphs::Graph;
import analysis::flow::ControlFlow;
import Node;
import lang::java::flow::JavaToObjectFlow;
/* ============================================================================
 *                              readSingleFile
 * ----------------------------------------------------------------------------
 * Read a single file at a given location into a string
 * ============================================================================
 */
public str readSingleFile(loc location) {     
    return readFile(location);
}

/* ============================================================================
 *                              cleanRaw
 * ----------------------------------------------------------------------------
 * Read a single file at a given location into a string
 * ============================================================================
 */
public str cleanRaw(loc location) {     
    str org_code        = readSingleFile(location);

    return cleanSource(org_code);
}

/* ============================================================================
 *                                  getFileInLines
 * ----------------------------------------------------------------------------
 *  ~ Read a single file at a given location.
 *  ~ Clean up the read source code
 *  ~ Split it up into a list of lines, each index being a different line
 *  ~ Remove any empty lines
 * ============================================================================
 */
public list[str] getFileInLines(loc location) {
    str cleaned_code = cleanRaw(location);

    list[str] code_lines = split("\n", cleaned_code);
    code_lines = [line | line <- code_lines, line != "", trim(line) != "}"];

    return code_lines;
}
/* ============================================================================
 *                                  modelToLines
 * ----------------------------------------------------------------------------
 *  Simply put this function converts an entire model to a sequence of lines
 * ============================================================================
 */
list[str] modelToLines(M3 model) {
    set[loc] source_files = files(model);
    list[str] all_lines = [];
    
    for (f <- source_files) {
        list [str] file_lines = getFileInLines(f);
        all_lines += file_lines;
    }
    
    return [trim(line) | line <- all_lines];
}




list[Declaration] genASTFromProject(loc location) {
    M3 model = createM3FromMavenProject(location);

    list[Declaration] ast = [
        createAstFromFile(f, true)
        | f <- files(model.containment),  // TODO MAYBE REMOVE >CONTAIMNENT
        isCompilationUnit(f),
        contains(f.path,".java") && !contains(f.path,"/test/")

    ];

    return ast;
}


// /* ============================================================================
//  * generateCFGFromProject
//  * ----------------------------------------------------------------------------
//  * Builds the M3 model for a project and extracts the Control-Flow Graph (CFG)
//  * for all analyzed declarations (e.g., methods/constructors).
//  * * The result is a map: [Declaration Location -> Control-Flow Graph]
//  * where the Control-Flow Graph is a simple Graph[loc] (rel[loc, loc]).
//  * ============================================================================
//  */
// public map[loc, Graph[loc]] generateCFGFromProject(loc projectLocation) {
    
//     // Get all ASTs (which is needed to find the body of each method)
//     list[Declaration] allAsts = genASTFromProject(projectLocation);
    
//     // 1. Build the M3 model
//     M3 model = createM3FromMavenProject(projectLocation);
    
//     map[loc, Graph[loc]] projectCFGs = ();
    
//     // Filter method locations based on name scheme (as we did previously)
//     set[loc] methodLocations = { // This is fucking up, try get it to match the AST version
//         name 
//         | <name, _> <- model.declarations, 
//           name.scheme == "java+method"
//     };
    
//     println("Found <size(methodLocations)> methods to analyze CFGs for.");
//     println("<methodLocations>");
//     // 2. Iterate over all methods
//     for (declLoc <- methodLocations) {   
        
//         // Find the specific AST node for the method declaration
//         Declaration methodDecl = findMethodDeclaration(declLoc, allAsts);
//         println("Analyzing CFG for method at location: <declLoc>");
//         if (methodDecl == \dimension([])) {
//             println("DEBUG: Could not find AST Declaration for method at <declLoc>. Skipping.");
//             continue;
//         }
//         // **CRITICAL FIX**: Call createCFG with the Declaration AST node.
//         CFG controlFlowResult = cfg(methodDecl, model); 
//         println("Control flow result: <controlFlowResult>");
//         ControlFlow complexFlow = controlFlowResult.graph; 

//         // DEBUG: Confirm success
//         if (size(complexFlow) == 0) {
//             println("DEBUG: Flow analysis FAILED for method <declLoc> (Complex Flow is empty).");
//             continue;
//         } else {
//             println("DEBUG: Flow analysis SUCCEEDED for method <declLoc> with <size(complexFlow)> edges.");
//         }
        
//         // 3. Project the complex ControlFlow into a simple Graph[loc]
//         Graph[loc] simpleCFG = { 
//             <getLocFromControlNode(from), getLocFromControlNode(to)> 
//             | <from, _, to> <- complexFlow
//         };
        
//         // Final check
//         if (size(simpleCFG) > 0) {
//             projectCFGs += (declLoc : simpleCFG);
//         }
//     }
    
//     return projectCFGs;
// }

// private Declaration findMethodDeclaration(loc methodLoc, list[Declaration] allAsts) {
//     for (Declaration cu <- allAsts) {
//         bottom-up visit (cu) {
//             case Declaration d: {
//                 println("Checking declaration at <d> against <methodLoc.uri>");
//                 if (d.src.uri == methodLoc.uri)
//                  return d;
//             }
//         };
//     }
//     return \dimension([]);
// }

// // This helper extracts the 'loc id' from any ControlNode
// loc getLocFromControlNode(ControlNode nodeId) {
//     switch(nodeId) {
//         case \block(loc id): return id;
//         case \entry(loc id): return id;
//         case \exit(loc id): return id;
//         default: return |unknown:///|; // Should not happen for standard CFGs
//     }
// }