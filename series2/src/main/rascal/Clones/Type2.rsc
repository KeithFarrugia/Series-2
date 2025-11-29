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
void testBlocks() {
    list[Declaration] cu = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    detectBlocks(cu);
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

list[list[str]] tokenizeLines(Declaration cu) {
    // walk cu and emit tokens with their src line; group tokens per line
    map[int, list[str]] byLine = ();
    visit(cu) {
        case node n: {
            if(n.src?){
                
                int line = getBeginLine(n.src);
                if(byLine[line]?){
                    byLine[line] += toString(delAnnotationsRec(n));
                }else{
                    byLine[line] = [toString(delAnnotationsRec(n))];
                }
            }
        }
    }
    // return in ascending line order
    list[int] lines = sort([l | l <- domain(byLine)]);
    return [byLine[l] | l <- lines];
}


list[str] flatten(list[list[str]] lls) {
   return concat(lls);
}


list[Window] windowsFromLines(loc fileLoc, list[list[str]] lines, int B) {
  list[Window] windows = [];
  int n = size(lines);

  for (i <- [0 .. n - B]) {

    int s               = i;
    int e               = i + B - 1;
    list[str] tokseq    = flatten(lines[s .. e]);

    windows += window(fileLoc, s, e, tokseq);
  }
  return windows;
}

int tokenHash(list[str] tokseq) {
  str s = intercalate(" ", tokseq);
  println("");
  
  println("WHAT WE ARE HASHING:\n <s>");
  println("");

  return hash(s);
}

set[int] shingleSet(list[str] tokseq, int k) {
  set[int] S = {};
  int m = size(tokseq);
  for (i <- [0 .. m - k]) {
    // splice slice so intercalate sees a flat list of tokens:
    list[value] slice = [ * tokseq[i .. i+k-1] ];
    str s = intercalate(" ", slice);
    S += hash(s);
  }
  return S;
}

// (Placeholder) construct a loc for a window; needs real implementation
loc mkLocForWindow(loc cuLoc, int startLine, int endLine) {
    cuLoc.begin.line = startLine;
    cuLoc.end.line = endLine;
  // TODO: compute correct begin/end character positions if you want full loc;
  // for now create a loc that spans the lines (begin column=0, end column=0)
  //return |file://{cuLoc.uri}|@startLine:0 - |file://{cuLoc.uri}|@endLine:0;
  return cuLoc;
}


void reportExactMatches(list[Window] ws) {
  for (i <- [0 .. size(ws)-2]) {
    for (j <- [i+1 .. size(ws)-1]) {
      Window w1 = ws[i];
      Window w2 = ws[j];
      println("Exact clone between <w1.fileLoc> lines <w1.startLine>-<w1.endLine> and <w2.fileLoc> lines <w2.startLine>-<w2.endLine>");
    }
  }
}

void detectBlocks(list[Declaration] cus, int B = 6, int kShingle = 3) {
    map[int, list[Window]] exactBucket   = ();
    map[int, list[tuple[Window, set[int]]]] shingleIndex = ();

    println("Starting detectBlocks on <size(cus)> compilation units.");

    for (cu <- cus) {
        Declaration norm = normalise(cu);
        loc cuLoc        = norm.src;
        list[list[str]] lines = tokenizeLines(norm);
        println("  CU at <cuLoc>: tokenized into <size(lines)> lines.");

        list[Window] wins = windowsFromLines(cuLoc, lines, B);
        println("    - generated <size(wins)> windows of size <B>");

        for (Window w <- wins) {
            int h = tokenHash(w.tokens);
            println("Window <w.startLine>-<w.endLine> hash <h>");
            
            set[int] S = shingleSet(w.tokens, kShingle);
            println("  Shingle-set size: <size(S)>");
            println("  Shingle hashes: <S>"); // print the actual integer hashes

            // Optional: print the corresponding token sequences for each shingle
            println("  Shingle contents:");
            for (i <- [0..size(w.tokens)-kShingle]) {
                list[str] slice = w.tokens[i .. i+kShingle-1];
                println("    <slice>");
            }

            int signature = min(S);
            println("  Shingle-signature (min hash) <signature>");
            
            tuple[Window, set[int]] entry = <w, S>;
            if (shingleIndex[signature]?) {
                shingleIndex[signature] = shingleIndex[signature] + [entry];
            } else {
                shingleIndex[signature] = [entry];
            }
        }
    }

    println("Finished building buckets — exactBucket has <size(exactBucket)> keys.");

    for (h <- exactBucket) {
        list[Window] ws = exactBucket[h];
        if (size(ws) > 1) {
            println("=== Exact clone bucket for hash <h>: <size(ws)> windows ===");
            reportExactMatches(ws);
        }
    }

    println("Shingle-index has <size(shingleIndex)> signature keys.");
}
