module Utility::Reader

import IO;
import String;
import List;
import Set;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Utility::CleanCode;

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
        isCompilationUnit(f)
    ];

    return ast;
}
