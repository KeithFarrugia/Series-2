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

/*
 * Minimum number of physical source lines a clone must span.
 */
int DUPLICATION_THRESHOLD = 6;
int MASS_THRESHOLD = 12;

/*
 * Entry point: count duplicated lines via AST clone detection.
 */
int countDuplicates(list[Declaration] asts) {
    list[Declaration] nAsts = [normalise(a) | a <- asts];    

    list[node] subtrees = getSubtrees(nAsts);
    
    map[int, list[loc]] bucket = groupByHash(subtrees);
    set[loc] duplicated = collectDuplicateLocations(bucket);
    println("Duplicated locations found: <duplicated>");
    return size(duplicated);
}

/*
 * Extract ALL subtrees (nodes) from all compilation units,
 * but only include nodes whose mass ≥ MASS_THRESHOLD.
 */
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

/*
 * Compute the tree mass (= number of nodes)
 */
int mass(node n) {
    int m = 0;
    visit(n) {
        case node _: m += 1;
    }
    return m;
}

/*
 * Filter + normalise + hash AST nodes.
 */
map[int, list[loc]] groupByHash(list[node] nodes) {
    map[int, list[loc]] bucket = ();

    for (node n <- nodes) {
        L = n.src; // Why does settng loc at the beginning not work?? It's a loc!!!!!

        node clean = delAnnotationsRec(n); // I know it says deprecated, but it works
        println("Cleaned Node: <toString(clean)>");
        
        str s = toString(clean);
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

/*
 * Collect duplicated line spans.
 */
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

/*
 * Helper: count source lines covered by a location.
 */
int lines(loc L) = L.end.line - L.begin.line + 1;

/*
 * AST normalisation
 */
Declaration normalise(Declaration d) {
  // visit returns the transformed tree, so assign it back to d
  d = visit(d) {
    case \id(_) => \id("ID")
    case \stringLiteral(_) => \stringLiteral("STR")
    case \textBlock(_) => \textBlock("LIT")
    case \number(_) => \number("LIT")
    case \characterLiteral(_) => \characterLiteral("LIT")
    case \booleanLiteral(_) => \booleanLiteral("LIT")

    case \simpleType(_) => \simpleType(id("TYPE"))
    case \qualifiedType(_, _, _) => \qualifiedType([], id("TYPE"), id("TYPE"))
    case \arrayType(_) => \arrayType(simpleType(id("TYPE")))
    case \parameterizedType(_, _) => \parameterizedType(simpleType(id("TYPE")), [])
    case \unionType(_) => \unionType([simpleType(id("TYPE"))])
    case \intersectionType(_) => \intersectionType([simpleType(id("TYPE"))])
    case \wildcard(_) => \simpleType(id("TYPE"))

    case \int() => \simpleType(id("TYPE"))
    case \float() => \simpleType(id("TYPE"))
    case \long() => \simpleType(id("TYPE"))
    case \double() => \simpleType(id("TYPE"))
    case \byte() => \simpleType(id("TYPE"))
    case \short() => \simpleType(id("TYPE"))
    case \char() => \simpleType(id("TYPE"))
    case \string() => \simpleType(id("TYPE"))
    case \byte() => \simpleType(id("TYPE"))
    case \boolean() => \simpleType(id("TYPE"))
    case \void() => \simpleType(id("TYPE"))
  };
  return d;
}

void testNormalize() {
    list[Declaration] cu = [createAstFromFile(|project://sig-metrics-test/src/main/java/org/sigmetrics/Duplication.java|, true)];
    int duplicates = countDuplicates(cu);
    println("NumDuplicates found: <duplicates>");
}