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

import Conf;
import Utility::Write;
import Utility::LinesOfCode;
import Utility::Statistics;
import Utility::Timings;
import Utility::CloneMerger;

/* ============================================================================
 *                     Token-based Clone Generation
 * ----------------------------------------------------------------------------
 *  Generates clones of the specified type using the Token-based detector.
 *  Returns a list of clones.
 * ============================================================================
 */
list[Clone] generateTokenClones(int cloneType) {
    switch (cloneType) {
        case 1: {return findClonesOfType1Or2Token(1);}
        case 2: {return findClonesOfType1Or2Token(2);}
        case 3: {return findClonesOfType3Token   ( );}

        default: {println("Invalid clone type: <cloneType>"); return [];}
    }
}

/* ============================================================================
 *                     AST-based Clone Generation
 * ----------------------------------------------------------------------------
 *  Generates clones of the specified type using the AST-based detector.
 *  Returns a list of clones.
 * ============================================================================
 */
list[Clone] generateASTClones(int cloneType) {
    switch (cloneType) {
        case 1: {return findClonesOfType1Or2AST(1);}
        case 2: {return findClonesOfType1Or2AST(2);}
        case 3: {return findClonesOfType3AST   ( );}

        default: {println("Invalid clone type: <cloneType>"); return [];}
    }
}

/* ============================================================================
 *                     General Clone Generation
 * ----------------------------------------------------------------------------
 *  Generates clones using the specified method (AST=1, Token=2) and type.
 *  Prints statistics for the generated clones before returning them.
 * ============================================================================
 */
list[Clone] generateClones(int methodType, int cloneType) {
    if (methodType == 1) {
        println("Using AST-based clone detection...");
        list[Clone] clones = generateASTClones(cloneType);
        printStatisticsForProject(clones, cloneType);
        return clones;
    } else if (methodType == 2) {
        println("Using Token-based clone detection...");
        list[Clone] clones = generateTokenClones(cloneType);
        printStatisticsForProject(clones, cloneType);
        return clones;
    } else {
        println("Invalid method type: <methodType>");
        return [];
    }
}


/* ============================================================================
 *                     General Clone Generation
 * ----------------------------------------------------------------------------
 *  Generates clones using the specified method (AST=1, Token=2) and type.
 *  Prints statistics for the generated clones before returning them.
 * ============================================================================
 */
void main(int methodType, int cloneType) { 
    list [Clone] clones = [];

    datetime t0 = now();
    
    if(cloneType == -1){
        println("Generating all clone types separately...");
        list[Clone] allClones = [];
        for (int ct <- [1,2,3]) {
            allClones += generateClones(methodType, ct);
        }
        clones = mergeCloneTypes(allClones);
    }else{
        clones = generateClones(methodType, cloneType);
    }

    datetime t1 = now();
    println("Total Time: <calcTime(t0, t1)>");
    
    writeClonesToJson(clones);
    writeLinesOfCodeToJson(getAllFilesFromProjectRoot());
}