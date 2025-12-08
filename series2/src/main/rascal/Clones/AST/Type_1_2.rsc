module Clones::AST::Type_1_2

import Clones::AST::Common_AST;
import Utility::TokenAST;
import Utility::Reader;
import IO;
import String;
import List;
import Set;
import Map;
import Node;
import Location;
import lang::java::m3::Core;
import lang::java::m3::AST;
extend lang::java::m3::TypeSymbol;
import util::Math;
import util::FileSystem;
import util::Reflective;


map[node, lrel[node, loc]] buckets  = ();

void testOutASTType1(){
    buckets  = ();
    // list[Declaration] ast = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    list[Declaration] ast = genASTFromProject(|project://smallsql0.21_src|);
    list[Declaration] norm_ast = [];
    // for(d <- ast){
    //     norm_ast += normaliseDeclaration(d);
    // }
    visit (ast) {
        case node x: {
            int currentMass = mass(x);
            if (currentMass >= MASS_THRESHOLD) {
                addNodeToMap(x);
            }
        }
    }

    // println("Done with indexing the subtrees into buckets.");
    // println("Result: ");
    // for(k <- domain(buckets)){
    //     println("Key: \n<k>");
    //     for (<b, _> <- buckets[k]) {
    //         println("\tChild\n\t <b>\n");
    //     }
    // }
    map[node, lrel[node_loc, node_loc]] cloneSet = removeInternalCloneClasses(findClonesSets());
    printCloneSets(cloneSet);
}

/* ============================================================================
 *                             addNodeToMap()
 * ----------------------------------------------------------------------------
 * Basically: 
 * A node is added to the bucket if:
 *      - It contains the minimum number of lines required
 *      - This is stored in the DUPLICATION_THRESHOLD at "Clones::AST::Common_AST"
 *        Usually set to 6 lines.
 * ============================================================================
 */
void addNodeToMap(
    node n
) {
    loc location = getLocation(n.src);
    // println("Before Cleaning\n <n>");
    // println("After Cleaning\n <unsetRec(n)>");
    // println("Before Cleaning 2\n <n>");
    if (minNodeLines(location) == false) {
        return;
    }
    println("<location>");
    if (buckets[unsetRec(n)]?) {
        if(location != buckets[unsetRec(n)][0][1]){
            buckets[unsetRec(n)] += <unsetRec(n), location>;
        }
    } else {
        buckets[unsetRec(n)] = [<unsetRec(n), location>];
    }
}










map[node, lrel[node_loc, node_loc]] findClonesSets(){
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (bucket <- buckets) {
        if (size(buckets[bucket]) >= 2) {
            lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
            complementBucket += buckets[bucket] * buckets[bucket];
            // Removing reflective pairs
            complementBucket = [p | p <- complementBucket, p.L != p.R];
            // Cleanup symmetric clones, they are useless.
            complementBucket = delSymmPairs(complementBucket);
                
            for (treeRelation <- complementBucket) {
                if (clonesSet[treeRelation[0][0]]?) {
                    clonesSet[treeRelation[0][0]] += treeRelation;
                } else {
                    clonesSet[treeRelation[0][0]] = [treeRelation];
                }
            }
        }
    }
    return clonesSet;
}


void printCloneSets(map[node, lrel[node_loc, node_loc]] clonesSet) {
    int classId = 1;

    for (k <- domain(clonesSet)) {
        println("==========================================");
        println("Clone Class <classId>");
        println("AST Key:");
        println("<k>");
        println("Pairs:");

        for (<L, R> <- clonesSet[k]) {
            println("  \t (< L[1] >)  \nCLONE OF\n \t <R[1] >");
        }

        classId += 1;
        println("");
    }
}