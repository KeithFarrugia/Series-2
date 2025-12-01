module Clones::Type3

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
list[tuple[int,int,real]] findType3(list[TokenizedLine] lines) {

    real SIM_THRESHOLD = 0.70;
    int  t = DUPLICATION_THRESHOLD;
    list[tuple[int,int,real]] results = [];

    int n = size(lines);
    list[set[str]] blocks = [ flattenBlock(lines, i, t) | i <- [0 .. n - t] ];

    println("\n ============== DEBUG: TYPE-3 COMPARISON START ============== \n");
    println("Total blocks: <size(blocks)>");
    println("Threshold: <SIM_THRESHOLD>  (t = <t> lines per block)\n");

    for (i <- [0 .. n - t]) {

        println("---------------------------------------------------------");
        println("BLOCK <i> tokens: <blocks[i]>");
        println("---------------------------------------------------------");

        for (j <- [i + 1 .. n - t]) {

            real sim = jaccard(blocks[i], blocks[j]);

            // Print comparisons that are close or passing threshold
            if (sim >= 0.40) {
                println("Comparing block <i> with block <j> → similarity = <sim>");
            }

            if (sim >= SIM_THRESHOLD && sim < 1.0) {
                println("\n************** TYPE-3 NEAR-MISS FOUND **************");
                println("Block <i>  ~  Block <j>");
                println("Similarity: <sim>");
                println("Block <i> tokens:\n  <blocks[i]>");
                println("Block <j> tokens:\n  <blocks[j]>");
                println("***************************************************\n");

                results += <i, j, sim>;
            }
        }
    }

    println("\n============== DEBUG: TYPE-3 COMPARISON END ================\n");

    return results;
}
