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
import Conf;
import Utility::CloneMerger;

int DUPLICATION_THRESHOLD = 6;


/* ============================================================================
 *                          testDuplicateLineCount
 * ----------------------------------------------------------------------------
 *  Ensures that countDuplicates(M3) returns the expected number of duplicated
 *  lines in the test Maven project. This verifies that the final duplicate-line
 *  count, after combining all duplicate blocks, is correct.
 * ============================================================================
 */
list[Clone] testDuplicateLineCount() {
    //list[Declaration] ast = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    list[Declaration] ast = genASTFromProject(|project://clone-demo|);
    list[TokenizedLine] lines =  tokeniseAST(ast, true);
    return mergeClonePairList(findDuplicates (lines, 1));
}


int hashBlock(list[TokenizedLine] lines, int s, int t) {
    // Make sure all lines in the block belong to the same file
    str file = lines[s].sourceLoc.uri;

    list[set[str]] block = [];
    for (k <- [0 .. t]) {
        if (lines[s + k].sourceLoc.uri != file) {
            return -1;  // invalid → this block is ignored
        }
        if (size(lines[s + k].tokens) == 0)
            continue;
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


list[Clone] findDuplicates(list[TokenizedLine] lines, int cloneType) {

    lines = removeEmptyTokenLines(lines);
    
    // for(t<- lines){
    //     println("\n<t>");
    // }
    int t = DUPLICATION_THRESHOLD;
    map[int, list[int]] hashMap = ();      // hash -> starting indices
    set[int] duplicated = {};
    list[Clone] clones = [];

    int n = size(lines);
    if (n < t) return [];

    // 1. Build a hash for every t-line block
    for (i <- [0 .. n - t]) {

        int h = hashBlock(lines, i, t);
        if (h == -1) continue;
        
        if (h in hashMap)
            hashMap[h] += [i];
        else
            hashMap[h] = [i];
    }
    
    // 2. For every hash that occurs more than once, mark duplicates
    for (h <- hashMap) {
        list[int] starts = hashMap[h];
        if (size(starts) < 2) continue;
        
        
        for (i <- starts) {
            for (j <- starts) {
                if (i < j) {

                    // ------------------------------------------------------------
                    // DEBUG OUTPUT: print whole clone pair if *any* line in A or B
                    // originates from the target source file
                    // ------------------------------------------------------------
                
                    // println("\n=== DUPLICATE FOUND at indices <i> and <j> ===");

                    // println("BLOCK A (starting at index <i>):");
                    // for (k <- [i .. i + t]) {
                    //     println("  [<k>] <lines[k]>");
                    // }

                    // println("\nBLOCK B (starting at index <j>):");
                    // for (k <- [j .. j + t]) {
                    //     println("  [<k>] <lines[k]>");
                    // }

                    // println("--------------------------------------------------\n");

                    // ------------------------------------------------------------
                    // Build location objects
                    Location loc1 = toLocation(lines, i, t);
                    Location loc2 = toLocation(lines, j, t);

                    str id = "<h>-<i>-<j>";
                    str name = "TokenClone_<i>_<j>";

                    clones += clone(
                        [loc1, loc2],    // two clone fragment locations
                        t,               // fragment length
                        cloneType,               // clone type → token-based ⇒ Type-2
                        id,
                        name
                    );
                    
                }
            }
        }
       
    }

    return clones;
}

