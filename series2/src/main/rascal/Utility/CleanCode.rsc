module Utility::CleanCode

import IO;
import List;
import String;
import Set;

/* ============================================================================
 *                              cleanSource
 * ----------------------------------------------------------------------------
 *  Cleans a source string by:
 *   1. Normalising all whitespace characters to a standard newline.
 *   2. Removing multi-line comments (/* ... * /).
 *   3. Removing single-line comments (// ...).
 *   4. Collapsing multiple consecutive blank lines to a single blank line.
 * ============================================================================
 */
public str cleanSource(str sourcestr) {
    
    /* -------------------------------------------------------------------- 
     * Step 1: Normalise all whitespace characters to newline
     * This is a safety step against unprintable characters.
     * -------------------------------------------------------------------- */
    str normalizedWhitespace = replaceAll(sourcestr, "[\\p{Z}\\s]", "\n");

    /* -------------------------------------------------------------------- 
    // Step 2: Remove multi-line comments
     * -------------------------------------------------------------------- */
    str noMultiLineComments = visit(normalizedWhitespace) {
        case /\/\*[\s\S]*?\*\// => "\n"
    };

    /* -------------------------------------------------------------------- 
     * Step 3: Remove single-line comments
     * -------------------------------------------------------------------- */
    str noAllComments = visit(noMultiLineComments) {
        case /\/\/[^\n]*/ => "\n"
    };

    /* -------------------------------------------------------------------- 
     * Step 4: Collapse multiple consecutive blank lines into 
     * a single newline
     * -------------------------------------------------------------------- */
    str finalCleanstr = visit(noAllComments) {
        case /^\n[ \t\n]*\n/ => "\n"
    };

    return finalCleanstr;
}

/* ============================================================================
 *                        stripCompilationUnitPrefix
 * ----------------------------------------------------------------------------
 *  Cleans a location string by removing prefixes such as:
 *   - java+compilationUnit:///
 *   - project://
 * ============================================================================
 */
public str stripCompilationUnitPrefix(str location) {
    str cleaned = replaceAll(
        replaceAll(location, "java\\+compilationUnit:///", ""), 
        "project://", ""
    );
    return cleaned;
}