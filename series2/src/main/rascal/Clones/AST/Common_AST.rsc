module Clones::AST::Common_AST



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

/* ============================================================================
 *                        Constants / Configuration
 * ----------------------------------------------------------------------------
 * DUPLICATION_THRESHOLD:   minimum number of physical source lines a clone must
 *                          span.  
 * MASS_THRESHOLD:          minimum number of AST nodes (mass) for a subtree to
 *                          be considered for clone detection.  
 * ============================================================================ */
 
alias node_loc = tuple[node, loc];

public int  DUPLICATION_THRESHOLD   = 6;
public int  MASS_THRESHOLD          = 12;
public real SIMILARITY_THRESHOLD    = 0.7;



/* ============================================================================
 *                             getSubtrees()
 * ----------------------------------------------------------------------------
 * Extracts all subtrees (nodes) from all given compilation units (ASTs),
 * but only include those whose mass (number of descendant nodes) is ≥
 * MASS_THRESHOLD.
 * ============================================================================ */
list[node] getSubtrees(list[Declaration] cus) {
    list[node] result = [];

    for (cu <- cus) {
        visit(cu) {
            case node x: {
                int m = mass(x);
                if (m >= MASS_THRESHOLD) {
                    result += x;
                }
            }
        }
    }
    return result;
}

/* ============================================================================
 *                                 mass()
 * ----------------------------------------------------------------------------
 * Compute the “mass” of a subtree: simply the total number of nodes reachable
 * from the given node (including itself), by traversing recursively.  
 * ============================================================================ */
int mass(node n) {
    int m = 0;
    visit(n) {
        case node _: m += 1;
    }
    return m;
}

loc getLocation(loc l){
    return l;
}

public bool minNodeLines(loc key) {
    if (key.end.line - key.begin.line >= 6) {
        return true;
    }
    return false;
}


public num calculateSimilarity(node t1, node t2) {
    //Similarity = 2 x S / (2 x S + L + R)

    list[node] tree1 = [];
    list[node] tree2 = [];

    visit (t1) {
        case node x: {
            tree1 += x;
        }
    }

    visit (t2) {
        case node x: {
            tree2 += x;
        }
    }

    num s = size(tree1 & tree2);
    num l = size(tree1 - tree2);
    num r = size(tree2 - tree1); 
        
    num similarity = (2 * s) / (2 * s + l + r); 

    return similarity;
}



public lrel[node_loc, node_loc] delSymmPairs(lrel[node_loc, node_loc] clonePairs) {

    lrel[node_loc,  node_loc] newClonePairs = [];

    for (pair <- clonePairs) {
        
        tuple[node_loc, node_loc] reversePair = 
            <
                <pair[1][0],pair[1][1]>,
                <pair[0][0],pair[0][1]>
            >;

        if (reversePair notin newClonePairs) {		
            newClonePairs += pair;
        }
    }
    return newClonePairs;
}




list[node] checkForInnerClones(tuple[node,loc] tree, map[node, lrel[node_loc, node_loc]] cloneSet) {
    list[node] subNodes = [];
    visit (tree[0]) {
        case node x: {
            // Only if the tree is not equal to itself, and has a certain mass.
            if (x != tree[0] && x.src?) {
                loc location = getLocation(x.src);
                
                tuple[node,loc] current = <x, location>;
                bool member  = false;
                
                for (cCloneSet <- domain(cloneSet)) {
                    for (currentPair <- cloneSet[cCloneSet]) {
                        if (
                            (current[1] <= currentPair[0][1] && currentPair[0][0] == current[0]) || 
                            (current[1] <= currentPair[1][1] && currentPair[1][0] == current[0]) ){
                            if (cloneSet[current[0]]?) {
                                if (size(cloneSet[current[0]]) == size(cloneSet[cCloneSet])) {
                                    member = true;
                                }
                            }
                        } 
                    }
                }

                if(member){
                    subNodes += x;
                }
                
            }
        }
    }
    return subNodes;
}


public bool contains(loc outer, loc inner){
    return outer.begin.line <= inner.begin.line &&
    outer.end.line   >= inner.end.line;
}



public map[node, lrel[node_loc, node_loc]] removeInternalCloneClasses(
    map[node, lrel[node_loc, node_loc]] cloneSet
) {
    
    println("\n\n==================================================================");
    println("Starting removeInternalCloneClasses");
    println("Initial cloneSet size <size(cloneSet)>");

    for(nodeKey <- cloneSet){
        println("\n ------------------------------------");
        println(" Inspecting nodeKey: \n <nodeKey> \n ------------------------------------ \n");

        visit(nodeKey){
            case node subKey: {
                println("  Visiting subKey <subKey>");

                // ================================
                // Skip self-comparison
                // ================================
                if(subKey == nodeKey){
                    println("    Skipping self-comparison for <subKey>");
                } 
                // ================================
                else if(cloneSet[subKey]?){
                    println("    subKey exists in cloneSet");

                    // ================================
                    // Check if all subKey pairs are contained in nodeKey
                    // ================================
                    bool allContained = true;

                    for(i <- [0 .. size(cloneSet[subKey])-1]){
                        tuple[node_loc, node_loc] pair = cloneSet[subKey][i];
                        <sn1, sl1> = pair[0];
                        <sn2, sl2> = pair[1];

                        println("      Checking pair index <i> : <pair>");
                        println("      sl1 <sl1>, sl2 <sl2>");

                        bool foundParent = false;
                        for(<<_, l1>, <_, l2>> <- cloneSet[nodeKey]){
                            if(
                               (contains(l1, sl1) && contains(l2, sl2)) ||
                               (contains(l2, sl1) && contains(l1, sl2))
                            ){
                                foundParent = true;
                                println("        Found matching parent pair!");
                                break;
                            }
                        }

                        if(!foundParent){
                            println("        No parent found for pair <pair>");
                            allContained = false;
                            break;
                        }
                    }

                    if(allContained){
                        println("    subKey <subKey> is fully contained in nodeKey <nodeKey>, removing subKey");
                        cloneSet = delete(cloneSet, subKey);
                    }
                    else {
                        println("    subKey <subKey> not fully contained, keeping it");
                    }
                } 
                else {
                    println("    subKey NOT in cloneSet");
                }
            }
        }
    }
    
    println("Finished removeInternalCloneClasses");
    println("Final cloneSet size <size(cloneSet)>");

    return cloneSet;
}




