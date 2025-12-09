module Main

import IO;

import lang::java::m3::Core;
import lang::java::m3::AST;
import Clones::Token::Type_1_2;
import Clones::Token::Type_3;
import DateTime;
import List;
import Utility::Write;
import Utility::LinesOfCode;
import Conf;
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

void main() {
    writeClonesToJson(testType3());
    writeLinesOfCodeToJson(getAllFilesFromProjectRoot(projectRoot));
    // datetime t0 = now();
    // // testDuplicateLineCount();
    // datetime t1 = now();
    // // println("Duplication time <durationToMillis(createDuration(t0, t1))>");
    // t0 = now();
    // testType3();
    // t1 = now();
    // println("Duplication time Type 3<durationToMillis(createDuration(t0, t1))>");
}
