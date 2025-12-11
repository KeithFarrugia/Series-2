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
import Conf;
import Utility::LinesOfCode;
import Utility::CloneMerger;
import DateTime;



map[node, lrel[node, loc]] buckets  = ();

list [Clone] findClonesOfType1Or2AST(int cloneType){
    buckets  = ();
    list[Declaration] ast = genASTFromProject(projectRoot);
    list[Declaration] norm_ast = [];
    
    if(cloneType == 2){
        for(d <- ast){
            norm_ast += normaliseDeclaration(d);
        }
    }else{
        norm_ast = ast;
    }

    visit (norm_ast) {
        case node x: {
            int currentMass = mass(x);
            if (currentMass >= MASS_THRESHOLD) {
                addNodeToMap(x);
            }
        }
    }
    
    list [Clone] c = buildASTCloneList(removeInternalCloneClasses(findClonesSets()), cloneType);
    return c;
}
int durationToMillis(Duration d) {
  return  d.years   * 1000 * 60 * 60 * 24 * 365
        + d.months  * 1000 * 60 * 60 * 24 * 30
        + d.days    * 1000 * 60 * 60 * 24
        + d.hours   * 1000 * 60 * 60
        + d.minutes * 1000 * 60
        + d.seconds * 1000
        + d.milliseconds;
}
void findASTType12(){
    buckets  = ();
    list[Declaration] ast = genASTFromProject(projectRoot);
    list[Declaration] norm_ast = [];
    
    for(d <- ast){
        norm_ast += normaliseDeclaration(d);
    }

    visit (norm_ast) {
        case node x: {
            int currentMass = mass(x);
            if (currentMass >= MASS_THRESHOLD) {
                addNodeToMap(x);
            }
        }
    }
    
    datetime t0 = now();
    list [Clone] c = buildASTCloneList(removeInternalCloneClasses(findClonesSets()), 2);
    datetime t1 = now();
    println("AST TIME        <durationToMillis(createDuration(t0, t1))>");
    
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
    loc location;
    if(n has src){
        location = getLocation(n.src);
    }
    else {
        return;
    }
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