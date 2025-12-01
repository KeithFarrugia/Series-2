module Main

import IO;

import lang::java::m3::Core;
import lang::java::m3::AST;
import Clones::Type1;
import DateTime;
import List;
import Utility::TokenAST;
import Clones::Type3;
loc test_project = |project://sig-metrics-test|;

int durationToMillis(Duration d) {
  return  d.years   * 1000 * 60 * 60 * 24 * 365
        + d.months  * 1000 * 60 * 60 * 24 * 30
        + d.days    * 1000 * 60 * 60 * 24
        + d.hours   * 1000 * 60 * 60
        + d.minutes * 1000 * 60
        + d.seconds * 1000
        + d.milliseconds;
}

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

void main() {
    
    datetime t0 = now();
    // testDuplicateLineCount();
    datetime t1 = now();
    // println("Duplication time <durationToMillis(createDuration(t0, t1))>");
    t0 = now();
    testType3();
    t1 = now();
    println("Duplication time Type 3<durationToMillis(createDuration(t0, t1))>");
}
