module Clones::Token::Type_1_2

import IO;
import String;
import List;
import Set;
import util::Math;
import Map;
import Utility::Hash;
import Utility::Reader;
import Utility::TokenAST;
import lang::java::m3::Core;
import lang::java::m3::AST;

int DUPLICATION_THRESHOLD = 6;


/* ============================================================================
 *                          testDuplicateLineCount
 * ----------------------------------------------------------------------------
 *  Ensures that countDuplicates(M3) returns the expected number of duplicated
 *  lines in the test Maven project. This verifies that the final duplicate-line
 *  count, after combining all duplicate blocks, is correct.
 * ============================================================================
 */
test bool testDuplicateLineCount() {
    list[Declaration] ast = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    list[TokenizedLine] lines =  tokeniseAST(ast, false);
    int duplicates = findDuplicates(lines);

    // TODO: Replace this once you know the correct value.
    int expected = 14;

    if (duplicates == expected) {
        println("✓ DuplicateLineCount test passed.");
    } else {
        println("✗ DuplicateLineCount test failed. Expected <expected> duplicate lines, found <duplicates>.");
    }

    return duplicates == expected;
}



int hashBlock(list[TokenizedLine] lines, int s, int t) {
    list[set[str]] block = [];
    for (k <- [0 .. t]) {
        block += lines[s + k].tokens;
    }
    return hash(block);
}
/* ============================================================================
 *                             countDuplicates
 * ----------------------------------------------------------------------------
 *  Counts the number of lines that are part of duplicate blocks in the model.
 *  Delegates the work to findDuplicates after converting the model to lines.
 * ============================================================================
 */

int findDuplicates(list[TokenizedLine] lines) {
    int t = DUPLICATION_THRESHOLD;
    map[int, list[int]] hashMap = ();      // hash -> starting indices
    set[int] duplicated = {};

    int n = size(lines);
    if (n < t) return 0;

    // 1. Build a hash for every t-line block
    for (i <- [0 .. n - t]) {

        int h = hashBlock(lines, i, t);

        if (h in hashMap)
            hashMap[h] += [i];
        else
            hashMap[h] = [i];
    }
    
    // 2. For every hash that occurs more than once, mark duplicates
    for (h <- hashMap) {
        list[int] starts = hashMap[h];
        if (size(starts) < 2) continue;

        // Print each duplicate block
        for (s <- starts) {
            println("Duplicate block starting at line <s>:");
            for (k <- [0 .. t]) {
                duplicated += {s + k};
                println("  <lines[s + k]>");   // print each line
            }
            println("");  // blank line between blocks
        }
    }
    // for (i <- [0 .. size(lines)-1]) {
    //     println("Line <i>: <lines[i]>");
    // }
    // for (h <- sort([k | k <- hashMap])) { // sort keys for readability
    //     list[int] indices = hashMap[h];
    //     println("Hash <h>  Starting lines: <indices>");
    // }
    // println("SIZE OF HASH MAP: <size(hashMap)>");

    return size(duplicated);
}

