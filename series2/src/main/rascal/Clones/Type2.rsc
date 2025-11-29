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

void testNormalize() {
    list[Declaration] cu = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    int duplicates = countDuplicates(cu);
    println("NumDuplicates found: <duplicates>");
}






















list[list[str]] tokenizeLines(Declaration cu) {
  // walk cu and emit tokens with their src line; group tokens per line
  map[int, list[str]] byLine = ();
  visit(cu) {
    case token t: {
       int line = t.src.begin.line;
       byLine[line] += [toString(t)]; // tokens already normalized by your normalise()
    }
  }
  // return in ascending line order
  list[int] lines = sort([l | l <- keys(byLine)]);
  return [byLine[l] | l <- lines];
}

list[tuple[int,int,list[str]]] windowsFromLines(list[list[str]] lines, int B) {
  list[tuple[int,int,list[str]]] windows = [];
  for (i <- [0 .. size(lines)-B]) {
    int startLine = i;
    int endLine = i + B - 1;
    list[str] tokseq = flatten(lines[startLine .. endLine]);
    windows += <startLine, endLine, tokseq>;
  }
  return windows;
}
int tokenHash(list[str] tokseq) {
  // convert to bytes or use existing hash; use rolling hash if you slide tokens with overlap
  return hash(tokseq);
}

// shingle set for a window (k-token grams)
set[int] shingleSet(list[str] tokseq, int k) {
  set[int] S = {};
  for (i <- [0 .. size(tokseq)-k]) {
    //S += hash(join(tokseq[i .. i+k-1], " ")); // not sure what it tried to do here
    S += hash(tokseq[i .. i+k-1]);
  }
  return S;
}