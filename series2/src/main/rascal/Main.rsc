module Main

import IO;

import lang::java::m3::Core;
import lang::java::m3::AST;
import Clones::Type1;
import DateTime;

loc test_project = |project://hsqldb-2.3.1|;

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
    M3 model = createM3FromMavenProject(test_project);

    int duplicates = countDuplicates(model);

    // TODO: Replace this once you know the correct value.
    int expected = 14;

    if (duplicates == expected) {
        println("✓ DuplicateLineCount test passed.");
    } else {
        println("✗ DuplicateLineCount test failed. Expected <expected> duplicate lines, found <duplicates>.");
    }

    return duplicates == expected;
}

void main() {
    
    datetime t0 = now();
    testDuplicateLineCount();
    datetime t1 = now();
    println("Duplication time <durationToMillis(createDuration(t0, t1))>");
}
