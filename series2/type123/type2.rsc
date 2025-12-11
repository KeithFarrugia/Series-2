module series2::type2

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import Map;
import String;
import Node;
import series2::type1;

int MIN_BLOCK_SIZE = 6;


// Loads all Java files from a directory and builds an AST for each file.
public list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromDirectory(projectLocation);
    set[loc] compilationUnits = {f | <f, _> <- model.containment, isCompilationUnit(f)};
    list[Declaration] asts = [createAstFromFile(f, true) | f <- compilationUnits];
    return asts;
}

// Normalize AST for Type-2: replace all identifiers and literals with generic values
// This makes clones with different variable names and values still match
node normalizeForType2(node n) {
  return bottom-up visit(n) {

    // --- Literals 
    case \number(str _)           => \number("0")
    case \booleanLiteral(str _)   => \booleanLiteral("true")
    case \stringLiteral(str _)    => \stringLiteral("S")   
    case \textBlock(str _)        => \textBlock("S")
    case \characterLiteral(str _) => \characterLiteral("C")

    // --- Identifiers 
    case \id(str _)               => \id("ID")

    // --- Variable declaration fragments
    case \variable(Expression _, list[Declaration] dims) =>
      \variable(\id("ID"), dims)

    case \variable(Expression _, list[Declaration] dims, Expression init) =>
      \variable(\id("ID"), dims, init)

    // --- Parameters 
    case \parameter(list[Modifier] mods, Type t, Expression _, list[Declaration] dims) =>
      \parameter(mods, t, \id("ID"), dims)
  };
}



// Extract method and constructor bodies as AST nodes
list[tuple[loc location, Statement astNode]] extractCodeBlocks(list[Declaration] asts) {
    list[tuple[loc location, Statement astNode]] codeBlocks = [];
    
    visit(asts) {
        case \method(_, _, _, _, _, _, Statement impl): {
            if (impl.src?) {
                int lineCount = impl.src.end.line - impl.src.begin.line + 1;
                
                if (lineCount >= MIN_BLOCK_SIZE) {
                    codeBlocks += <impl.src, impl>;
                }
            }
        }
        case \constructor(_, _, _, _, Statement impl): {
            if (impl.src?) {
                int lineCount = impl.src.end.line - impl.src.begin.line + 1;
                
                if (lineCount >= MIN_BLOCK_SIZE) {
                    codeBlocks += <impl.src, impl>;
                }
            }
        }
    }
    
    return codeBlocks;
}

// Group code blocks by their normalized AST structure
// Type-2 clones have same structure but different identifiers/literals
// EXCLUDES Type-1 clones (those are already detected by Type-1)
set[CloneClass] detectType2Clones(list[tuple[loc location, Statement astNode]] codeBlocks) {
    map[node, set[loc]] type1Groups = ();
    for (<loc location, Statement astNode> <- codeBlocks) {
        node type1Norm = series2::type1::normalizeForType1(astNode);
        if (type1Norm in type1Groups) {
            type1Groups[type1Norm] += {location};
        } else {
            type1Groups[type1Norm] = {location};
        }
    }
    
    map[node, set[loc]] cloneGroups = ();
    
    for (<loc location, Statement astNode> <- codeBlocks) {
        node type1Norm = series2::type1::normalizeForType1(astNode);
        if (type1Norm in type1Groups && size(type1Groups[type1Norm]) >= 2) {
            continue;
        }
        
        node normalized = normalizeForType2(astNode);
        normalized = unsetRec(normalized, {"src", "decl", "typ"});

        
        if (normalized in cloneGroups) {
            cloneGroups[normalized] += {location};
        } else {
            cloneGroups[normalized] = {location};
        }
    }
    
    return {group | group <- range(cloneGroups), size(group) >= 2};
}

// Counts the total number of clone instances across all clone classes.
int countClones(set[CloneClass] cloneClasses) {
    return (0 | it + size(cc) | cc <- cloneClasses);
}

// Calculates the number of duplicated lines by counting all instances
// except one per clone class (only the extra copies).
int calculateDuplicatedLines(set[CloneClass] cloneClasses) {
    int duplicatedLines = 0;
    for (CloneClass cc <- cloneClasses) {
        if (size(cc) > 1) {
            loc rep = getOneFrom(cc);
            for (loc l <- cc, l != rep) {
                duplicatedLines += (l.end.line - l.begin.line + 1);
            }
        }
    }
    return duplicatedLines;
}

// Counts the total lines of code in all methods and constructors.
int calculateTotalLOC(list[Declaration] asts) {
    int totalLOC = 0;
    visit(asts) {
        case \method(_, _, _, _, _, _, Statement impl): {
            if (impl.src?) {
                totalLOC += (impl.src.end.line - impl.src.begin.line + 1);
            }
        }
        case \constructor(_, _, _, _, Statement impl): {
            if (impl.src?) {
                totalLOC += (impl.src.end.line - impl.src.begin.line + 1);
            }
        }
    }
    return totalLOC;
}

// Calculates the percentage of duplicated code relative to the total codebase.
real calculateDuplicationPercentage(int duplicatedLines, int totalLOC) {
    if (totalLOC == 0) return 0.0;
    return (duplicatedLines * 100.0) / totalLOC;
}

public void mainAlgorithm(loc projectLocation) {
    println("=== Type-2 Clone Detection (AST-based) ===");
    println("Project: <projectLocation>");
    println("");
    
    list[Declaration] asts = getASTs(projectLocation);
    list[tuple[loc location, Statement astNode]] codeBlocks = extractCodeBlocks(asts);
    
    println("Found <size(codeBlocks)> code blocks");
    
    set[CloneClass] cloneClasses = detectType2Clones(codeBlocks);
    
    println("\n=== Results ===");
    println("Clone Classes: <size(cloneClasses)>");
    println("Total Clones: <countClones(cloneClasses)>");
    
    int duplicatedLines = calculateDuplicatedLines(cloneClasses);
    int totalLOC = calculateTotalLOC(asts);
    real duplicationPercentage = calculateDuplicationPercentage(duplicatedLines, totalLOC);
    
    println("Duplicated Lines: <duplicatedLines>");
    println("Total LOC: <totalLOC>");
    println("Duplication: <duplicationPercentage>%");
}
