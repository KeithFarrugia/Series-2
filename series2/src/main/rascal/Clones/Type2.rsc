module Clones::Type2

import IO;
import String;
import List;
import Set;
import Map;
import Node;
import Location;
import Utility::Hash;
import Utility::Reader;
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
int DUPLICATION_THRESHOLD   = 6;
int MASS_THRESHOLD          = 12;

/* ============================================================================
 *                             countDuplicates()
 * ----------------------------------------------------------------------------
 * Entry point: given a list of Java compilation-unit ASTs (list of Declarations),
 * normalize them, extract subtrees above mass threshold, group by hash of
 * normalized subtree, collect duplicated locations, and return number of
 * duplicates found.  
 * ============================================================================ */
int countDuplicates(list[Declaration] asts) {
    list[Declaration] nAsts = [normalise(a) | a <- asts];    

    list[node] subtrees         = getSubtrees(nAsts);
    
    map[int, list[loc]] bucket  = groupByHash(subtrees);
    set[loc] duplicated         = collectDuplicateLocations(bucket);

    println("Duplicated locations found: <duplicated>");
    return size(duplicated);
}

/*
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


/* ============================================================================
 *                             groupByHash()
 * ----------------------------------------------------------------------------
 * For each subtree: retrieve its source location (.src), remove annotations
 * recursively (including src, decl, typ, etc) using delAnnotationsRec, then
 * stringify the cleaned node, hash that string, and group locations by hash.
 * The result is a map: hash → list of source-file locations of subtrees.  
 * ============================================================================ */
map[int, list[loc]] groupByHash(list[node] nodes) {
    map[int, list[loc]] bucket = ();

    for (node n <- nodes) {
        L = n.src; // Why does settng loc at the beginning not work?? It's a loc!!!!!

        node clean_node = delAnnotationsRec(n); // I know it says deprecated, but it works
        println("Cleaned Node: <toString(clean_node)>");
        
        str s = toString(clean_node);
        int h = hash(s);
        if (bucket[h]?) {
            bucket[h] += [L];
        } else {
            bucket[h] = [L];
        }
    }

    println("Bucket size: <size(bucket)>");
    return bucket;
}

/* ============================================================================
 *                        collectDuplicateLocations()
 * ----------------------------------------------------------------------------
 * Given the bucket map (hash → list of locations), collect all locations
 * whose hash occurs more than once (i.e. duplicates). Print clone info and
 * return the set of duplicated locs.  
 * ============================================================================ */
set[loc] collectDuplicateLocations(map[int, list[loc]] bucket) {
    set[loc] duplicated = {};

    for (h <- bucket) {
        list[loc] occurrences = bucket[h];
        //println("Occurrences for hash <h>: <occurrences>");
        if (size(occurrences) < 2)
            continue;

        for (L <- occurrences) {
            println("Clone of hash <h> at <L>");
            duplicated += {L};
        }

    }

    return duplicated;
}





/* ============================================================================
 *                             lines()
 * ----------------------------------------------------------------------------
 * Helper: compute number of physical source lines spanned by a location.  
 * ============================================================================ */
int lines(loc L) = L.end.line - L.begin.line + 1;

/* ============================================================================
 *                            normalise()
 * ----------------------------------------------------------------------------
 * Normalize a Java AST Declaration by rewriting identifier names, literals,
 * types, etc. This helps detecting Type-2 clones (structurally same but
 * syntactically different). Returns a new Declaration.  
 * ============================================================================ */
Declaration normalise(Declaration d) {
  // visit returns the transformed tree, so assign it back to d
  d = visit(d) {
    case \id                (_)     => \id              ("ID" )
    case \stringLiteral     (_)     => \stringLiteral   ("STR")
    case \textBlock         (_)     => \textBlock       ("LIT")
    case \number            (_)     => \number          ("LIT")
    case \characterLiteral  (_)     => \characterLiteral("LIT")
    case \booleanLiteral    (_)     => \booleanLiteral  ("LIT")

    case \simpleType        (_)         => \simpleType          (id("TYPE"))
    case \qualifiedType     (_, _, _)   => \qualifiedType       ([], id("TYPE"), id("TYPE"))
    case \arrayType         (_)         => \arrayType           (simpleType(id("TYPE")))
    case \parameterizedType (_, _)      => \parameterizedType   (simpleType(id("TYPE")), [])
    case \unionType         (_)         => \unionType           ([simpleType(id("TYPE"))])
    case \intersectionType  (_)         => \intersectionType    ([simpleType(id("TYPE"))])
    case \wildcard          (_)         => \simpleType          (id("TYPE"))

    case \int       () => \simpleType(id("TYPE"))
    case \float     () => \simpleType(id("TYPE"))
    case \long      () => \simpleType(id("TYPE"))
    case \double    () => \simpleType(id("TYPE"))
    case \byte      () => \simpleType(id("TYPE"))
    case \short     () => \simpleType(id("TYPE"))
    case \char      () => \simpleType(id("TYPE"))
    case \string    () => \simpleType(id("TYPE"))
    case \byte      () => \simpleType(id("TYPE"))
    case \boolean   () => \simpleType(id("TYPE"))
    case \void      () => \simpleType(id("TYPE"))
  };
  return d;
}

str normaliseNode (node n) {
    switch (n) {
        // Case 1: Match the top-level \method node.
        case \method(_, _, Type \return, _, list[Declaration] parameters, _, _):
            return toString(unsetRec((\method([], [], \return, id("ID"), parameters, [], \empty()))));
        
        // Case 2: Match the top-level \block node.
        case \block(list[Statement] _) :
            // Return the block with an empty statement list.
            return toString(\empty());

        case \parameter(_, _, _, _):
            return "empty()";

        case \for(_, _, _,_):
            return toString(unsetRec(\for([], [],\empty())));

        case \for(_, _, _):
            return toString(unsetRec(\for([], [], \empty())));

        case \class(_, Expression name, _, _, _, _):
            return toString(unsetRec(\class([], name, [], [], [], [])));
            
        case  \class(list[Declaration] body):
            return toString(unsetRec(\class([])));
        default:
            return "";
    }
}


void testNormalize() {
    list[Declaration] cu = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    int duplicates = countDuplicates(cu);
    println("NumDuplicates found: <duplicates>");
}
void testBlocks() {
    list[Declaration] ast = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    for (cu <- ast) {
        Declaration norm = normalise(cu);
        loc cuLoc        = norm.src;
        list[set[str]] lines = tokenizeLines(cu);

        println(" ===================================== ");
        println("LINES");
        for(l <- lines ){
            for(ls <- l){
                println(ls);
            }
           
            println(" ===================================== ");
        }
    }
}

// =====================================
// --- types and helpers
// =====================================

data Window = window(
    loc         fileLoc,    // location of the file / compilation unit
    int         startLine,  // first line of the window (0-based)
    int         endLine,    // last line of the window
    list[str]   tokens      // normalized token sequence of the window
);

int getBeginLine(loc l) {
    return l.begin.line;
}
int getEndLine(loc l) {
    return l.end.line;
}
list[set[str]] tokenizeLines(Declaration cu) {
    // walk cu and emit tokens with their src line; group tokens per line
    map[int, set[str]] byLine = ();
    visit(cu) {
        case node n: {
            if(n.src?){
                
                int line                                = getBeginLine(n.src);

                if(!(byLine[line]?)){
                    byLine[line] = {};
                }
                

                str something = normaliseNode(n);
                if(something == ""){

                    tuple[list[node], bool] sub_nodes = filterOutSubNodes(n);
                    if(sub_nodes[1] == false){
                    byLine[line] += toString(unsetRec(n));
                    }
                    
                    for(s_n <- sub_nodes[0]){
                        byLine[line] += toString(unsetRec(s_n));
                    }

                }else{
                    byLine[line] += something;
                }
                
            }
        }
    }
    // return in ascending line order
    list[int] lines = sort([l | l <- domain(byLine)]); // error here
    return [byLine[l] | l <- lines];
}


tuple[list[node], bool] filterOutSubNodes(node parent){
    println("\n \nFILTERING OUT KIDS \n");
    list[node] sub_nodes = [];
    bool has_kids = false;
    println("PARENT:\n<toString(parent)[0 .. 100]> ...");
    visit(parent){
        case node n:{
            println("CHILD: \n \t<toString(n)[0  .. 100]> ... ");
            if((n.src?)){
                has_kids = true;
                if(
                    getBeginLine(n.src) == getBeginLine(parent.src) && 
                    getEndLine  (n.src) == getBeginLine(parent.src) 
                ){
                    sub_nodes += n;
                }

            }
        }
    }

    return <sub_nodes, has_kids>;
}

list[str] flatten(list[list[str]] lls) {
   return concat(lls);
}