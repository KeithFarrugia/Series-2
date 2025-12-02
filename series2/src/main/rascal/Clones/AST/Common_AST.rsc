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


public map[node, lrel[node, loc]] buckets  = ();

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


