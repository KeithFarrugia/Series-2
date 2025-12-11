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
import Conf;
import Utility::CleanCode;

bool overlapsOrExtends(Location a, Location b) {
    if (a.filePath != b.filePath) return false; 
    
    return a.startLine <= b.endLine + 1
        && b.startLine <= a.endLine + 1;
}

Location mergeLocations(Location a, Location b) {
    int s       = min(a.startLine, b.startLine);
    int end     = max(a.endLine, b.endLine);

    return location(a.filePath, s, end);
}

bool clonesOverlap(Clone c1, Clone c2) {
    for (l1 <- c1.locations) {
        for (l2 <- c2.locations) {
            if (overlapsOrExtends(l1, l2))
                return true;
        }
    }
    return false;
}

Clone mergeTwoClones(Clone c1, Clone c2) {
    list[Location] mergedLocs = [];

    // merge each pair of overlapping fragments
    for (l1 <- c1.locations) {
        bool merged = false;
        for (l2 <- c2.locations) {
            if (overlapsOrExtends(l1, l2)) {
                mergedLocs += mergeLocations(l1, l2);
                merged = true;
            }
        }
        if (!merged) mergedLocs += l1;
    }

    // add remaining locations from c2 that didn't merge
    for (l2 <- c2.locations) {
        bool covered = false;
        for (m <- mergedLocs) {
            if (overlapsOrExtends(m, l2)) {
                covered = true;
                break;
            }
        }
        if (!covered) mergedLocs += l2;
    }

    int newLength = 0;

    for (l <- mergedLocs) {
        int len = l.endLine - l.startLine + 1;
        if (len > newLength) {
            newLength = len;
        }
    }

    return clone(
        mergedLocs,
        newLength,
        c1.cloneType,
        "<c1._id>_<c2._id>",
        "<c1.name>-MERGED-<c2.name>"
    );
}

list[Clone] mergeCloneList(list[Clone] clones) {
    bool changed = true;

    while (changed) {
        changed = false;
        list[Clone] newList = [];
        set[int] mergedIndices = {};

        for (i <- index(clones)) {
            if (i in mergedIndices) continue;

            Clone current = clones[i];

            for (j <- index(clones)) {
                if (i == j || j in mergedIndices) continue;

                if (clonesOverlap(current, clones[j])) {
                    current = mergeTwoClones(current, clones[j]);
                    mergedIndices += {j};
                    changed = true;
                }
            }

            mergedIndices += {i};
            newList += current;
        }

        clones = newList;
    }

    return clones;
}
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



lrel[node_loc, node_loc] delSymmPairs(lrel[node_loc, node_loc] clonePairs) {
  set[str] seen = {};
  lrel[node_loc, node_loc] out = [];

  for (pair <- clonePairs) {
    <L, R> = pair;
    // canonical ordering by file + start + end
    str keyL = "<L[1].uri>:<L[1].begin.line>:<L[1].end.line>";
    str keyR = "<R[1].uri>:<R[1].begin.line>:<R[1].end.line>";
    str canonical;
    if (keyL <= keyR) canonical = keyL + "|" + keyR;
    else canonical = keyR + "|" + keyL;

    if (!(canonical in seen)) {
      seen += {canonical};
      out += pair;
    }
  }
  return out;
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







list[Clone] buildASTCloneList(map[node, lrel[node_loc, node_loc]] cloneSet, int cloneType) {
    list[Clone] result = [];

    for (root <- domain(cloneSet)) {
        for (<L, R> <- cloneSet[root]) {

            node n1 = L[0];
            loc  l1 = L[1];

            node n2 = R[0];
            loc  l2 = R[1];

            // Convert Rascal loc → your Clone Location type
            Location loc1 = location(
                stripCompilationUnitPrefix(l1.uri),
                l1.begin.line,
                l1.end.line
            );

            Location loc2 = location(
                stripCompilationUnitPrefix(l2.uri),
                l2.begin.line,
                l2.end.line
            );

            int fragmentLength = l1.end.line - l1.begin.line + 1;

            str id = "<root>-<l1.begin.line>-<l2.begin.line>";
            str name = "ASTClone_<l1.begin.line>_<l2.begin.line>";

            result += clone(
                [loc1, loc2],
                fragmentLength,
                cloneType,
                id,
                name
            );
        }
    }

    return result;
}