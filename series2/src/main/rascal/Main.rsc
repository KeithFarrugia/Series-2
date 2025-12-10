module Main

import IO;

import lang::java::m3::Core;
import lang::java::m3::AST;

import DateTime;
import List;

import Clones::Token::Type_1_2;
import Clones::Token::Type_3;
import Clones::AST::Type_1_2;
import Clones::AST::Type_3;

import Utility::Write;
import Utility::LinesOfCode;
import Conf;

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
    int methodType = 1;
    int cloneType = 1;
    list [Clone] clones;
    switch (methodType) {
        case 1: {
            println("Using AST-based clone detection...");

            switch (cloneType) {
                case 1: clones = findClonesOfType1Or2AST(1);
                case 2: clones = findClonesOfType1Or2AST(2);
                case 3: clones = findClonesOfType3AST();
                default: println("Invalid clone type chosen.");
            }
        }

        case 2: {
            println("Using Token-based clone detection...");

            switch (cloneType) {
                case 1: clones = findClonesOfType1Or2Token(1);
                case 2: clones = findClonesOfType1Or2Token(2);
                case 3: clones = findClonesOfType3Token();
                default: println("Invalid clone type chosen.");
            }
        }

        default: println("Invalid method chosen.");
    }

    writeClonesToJson(clones);
    writeLinesOfCodeToJson(getAllFilesFromProjectRoot(projectRoot));
}
