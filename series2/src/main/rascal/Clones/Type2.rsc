module Clones::Type2

import IO;
import String;
import List;
import Set;
import Map;
import Utility::Hash;
import Utility::Reader;
import lang::java::m3::Core;
import lang::java::m3::AST;

/*
 * Minimum number of physical source lines a clone must span.
 */
int DUPLICATION_THRESHOLD = 6;

/*
 * Entry point: count duplicated lines via AST clone detection.
 */
int countDuplicates(list[Declaration] asts) {
    list[Declaration] nAsts = [normalise(a) | a <- asts];    

    list[Statement] statements = getStatements(nAsts);
    
    map[int, list[loc]] bucket = groupByHash(statements);
    set[loc] duplicated = collectDuplicateLocations(bucket);
    println("Duplicated locations found: <duplicated>");
    return size(duplicated);
}
/*
 * Extract all statements from a list of compilation units.
 */
list[Statement] getStatements(list[Declaration] asts) {
    list[Statement] statements = [];

    for (Declaration cu <- asts) {
        // recursively visit everything in the CU
        visit(cu) {
            // match statements inside methods or nested blocks
            case \methodDeclaration(_, _, _, _, \block(stmts)) =>
                statements += stmts;

            case \block(stmts) =>
                statements += stmts;
        }
    }

    return statements;
}

/*
 * Filter + normalise + hash AST nodes.
 */
map[int, list[loc]] groupByHash(list[Declaration] asts) {
    map[int, list[loc]] bucket = ();

    for (n <- asts) {
        loc L = n.src;

        if (lines(L) < DUPLICATION_THRESHOLD) // Fix later since we need all groups of 6 lines checkd not methods only
            continue;

        str s = toString([n]);
        int h = hash(s);

        if (h in bucket)
            bucket[h] += [L];
        else
            bucket[h] = [L];
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
        println("Occurrences for hash <h>: <occurrences>");
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
}