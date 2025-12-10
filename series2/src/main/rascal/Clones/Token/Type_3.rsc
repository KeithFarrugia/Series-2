module Clones::Token::Type_3

import IO;
import String;
import List;
import Set;
import util::Math;
import Map;
import Utility::Reader;
import Utility::TokenAST;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Conf;
import Utility::CloneMerger;

int DUPLICATION_THRESHOLD = 6;

list [Clone] findClonesOfType3Token(){
    list[Declaration] ast = genASTFromProject(projectRoot);
    list[TokenizedLine] lines =  tokeniseAST(ast, true);

    return mergeClonePairList(findType3(lines));
}

bool sameFileBlock(list[TokenizedLine] lines, int s, int t) {
    str file = lines[s].sourceLoc.uri;
    for (k <- [0 .. t]) {
        if (lines[s + k].sourceLoc.uri != file) {
            return false;
        }
    }
    return true;
}

/* ============================================================================
 * Flatten a block of t lines into a single set of tokens
 * ============================================================================
 */
set[str] flattenBlock(list[TokenizedLine] lines, int s, int t) {
    set[str] group = {};
    for (k <- [0 .. t]) {
        group += lines[s + k].tokens;
    }
    return group;
}


/* ============================================================================
 * Jaccard similarity for sets
 * ============================================================================
 */
real jaccard(set[str] A, set[str] B) {
    if (size(A) == 0.0 && size(B) == 0.0) return 1.0;
    real inter = toReal(size(A & B));
    real uni   = toReal(size(A + B));
    return inter / uni;
}


/* ============================================================================
 * Type-3 clone detector with DEBUG OUTPUT
 * ============================================================================
 */
list[Clone] findType3(list[TokenizedLine] lines) {
    
    lines = removeEmptyTokenLines(lines);

    real SIM_THRESHOLD = 0.70;
    int  t = DUPLICATION_THRESHOLD;
    list[Clone] clones = [];

    int n = size(lines);
    list[set[str]] blocks =
    [ sameFileBlock(lines, i, t) ? flattenBlock(lines, i, t) : {} 
    | i <- [0 .. n - t]
    ];

    // println("\n ============== DEBUG: TYPE-3 COMPARISON START ============== \n");
    // println("Total blocks: <size(blocks)>");
    // println("Threshold: <SIM_THRESHOLD>  (t = <t> lines per block)\n");

    for (i <- [0 .. n - t]) {
        if (!sameFileBlock(lines, i, t)) continue;
        // println("---------------------------------------------------------");
        // println("BLOCK <i> tokens: <blocks[i]>");
        // println("---------------------------------------------------------");

        for (j <- [i + 1 .. n - t]) {
            if (!sameFileBlock(lines, j, t)) continue;
            real sim = jaccard(blocks[i], blocks[j]);
            if (sim >= SIM_THRESHOLD && sim < 1.0) {

                Location loc1 = toLocation(lines, i, t);
                Location loc2 = toLocation(lines, j, t);

                str id = "T3_<i>_<j>";
                str name = "Type3Clone_<i>_<j>";

                clones += clone(
                    [loc1, loc2],
                    t,          // fragment length
                    3,          // clone type → Type-3
                    id,
                    name
                );
            }
        }
    }

    //println("\n============== DEBUG: TYPE-3 COMPARISON END ================\n");

    return clones;
}
