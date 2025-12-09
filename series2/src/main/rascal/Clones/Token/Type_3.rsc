module Clones::Token::Type_3

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

int DUPLICATION_THRESHOLD = 6;


void testType3() {
    
    list[Declaration] ast = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    list[TokenizedLine] lines =  tokeniseAST(ast, false);

    list[tuple[int,int,real]] type3Results = findType3(lines);
    // TODO: Replace this once you know the correct value.
    println(" ======================================================== \n FINISHED TYPE 3 ========================================================\n ");
    if (size(type3Results) == 0) {
            println("No Type-3 clones found.");
        } else {
            for (r <- type3Results) {
                int i       = r[0];
                int j       = r[1];
                real sim    = r[2];

                int start1 = lines[i].lineNumber;
                int end1   = lines[i + DUPLICATION_THRESHOLD-1].lineNumber;

                int start2 = lines[j].lineNumber;
                int end2   = lines[j + DUPLICATION_THRESHOLD-1].lineNumber;

                println("Near-duplicate block (lines <start1>-<end1>) vs (lines <start2>-<end2>) — similarity: <sim>");
                            
                println("Block 1 (source lines <start1>-<end1>):");
                for (k <- [0 .. DUPLICATION_THRESHOLD]) {
                    println("  Line <lines[i + k].lineNumber>: <lines[i + k].tokens>");
                }

                println("Block 2 (source lines <start2>-<end2>):");
                for (k <- [0 .. DUPLICATION_THRESHOLD]) {
                    println("  Line <lines[j + k].lineNumber>: <lines[j + k].tokens>");
                }

                println("---------------------------------------------------------\n");
            }
        }
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

    real SIM_THRESHOLD = 0.70;
    int  t = DUPLICATION_THRESHOLD;
    list[Clone] clones = [];

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

    println("\n============== DEBUG: TYPE-3 COMPARISON END ================\n");

    return clones;
}
