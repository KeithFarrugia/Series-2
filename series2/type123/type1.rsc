module series2::type1

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import Map;
import String;
import Node;

int MIN_BLOCK_SIZE = 6;

alias CloneClass = set[loc];

public list[Declaration] getASTs(loc projectLocation) {
  M3 model = createM3FromDirectory(projectLocation);
  set[loc] compilationUnits = { f | <f, _> <- model.containment, isCompilationUnit(f) };
  return [ createAstFromFile(f, true) | f <- compilationUnits ];
}

public node normalizeForType1(node n) {
  return unsetRec(n, {"src", "decl"});
}


public list[tuple[loc location, Statement astNode]] extractCodeBlocks(list[Declaration] asts) {
  list[tuple[loc location, Statement astNode]] codeBlocks = [];

  visit(asts) {
    case \method(_, _, _, _, _, _, Statement impl): {
      loc useLoc = (impl.src?) ? impl.src : |unknown:///|;
      if (useLoc != |unknown:///|) {
        int lineCount = useLoc.end.line - useLoc.begin.line + 1;
        if (lineCount >= MIN_BLOCK_SIZE) {
          codeBlocks += <useLoc, impl>;
        }
      }
    }

    case \constructor(_, _, _, _, Statement impl): {
      loc useLoc = (impl.src?) ? impl.src : |unknown:///|;
      if (useLoc != |unknown:///|) {
        int lineCount = useLoc.end.line - useLoc.begin.line + 1;
        if (lineCount >= MIN_BLOCK_SIZE) {
          codeBlocks += <useLoc, impl>; // BODY
        }
      }
    }
  }

  return codeBlocks;
}


public set[CloneClass] detectType1Clones(list[tuple[loc location, Statement astNode]] codeBlocks) {
  map[node, set[loc]] cloneGroups = ();

  for (<loc location, Statement astNode> <- codeBlocks) {
    node normalized = normalizeForType1(astNode);

    if (normalized in cloneGroups) {
      cloneGroups[normalized] = cloneGroups[normalized] + {location};
    } else {
      cloneGroups[normalized] = {location};
    }
  }

  return { group | group <- range(cloneGroups), size(group) >= 2 };
}

public int countClones(set[CloneClass] cloneClasses) {
  return (0 | it + size(cc) | cc <- cloneClasses);
}

public int calculateDuplicatedLines(set[CloneClass] cloneClasses) {
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

public int calculateTotalLOC(list[Declaration] asts) {
  int totalLOC = 0;
  visit(asts) {
    case m: \method(_, _, _, _, _, _, Statement impl): {
      loc useLoc = (impl.src?) ? impl.src : (m.src? ? m.src : |unknown:///|);
      if (useLoc != |unknown:///|) totalLOC += (useLoc.end.line - useLoc.begin.line + 1);
    }
    case c: \constructor(_, _, _, _, Statement impl): {
      loc useLoc = (impl.src?) ? impl.src : (c.src? ? c.src : |unknown:///|);
      if (useLoc != |unknown:///|) totalLOC += (useLoc.end.line - useLoc.begin.line + 1);
    }
  }
  return totalLOC;
}

public real calculateDuplicationPercentage(int duplicatedLines, int totalLOC) {
  if (totalLOC <= 0) return 0.0;
  return (duplicatedLines * 100.0) / (totalLOC * 1.0);
}

public void mainAlgorithm(loc projectLocation) {
  println("=== Type-1 Clone Detection (AST-based) ===");
  println("Project: <projectLocation>");
  println("");

  list[Declaration] asts = getASTs(projectLocation);

  
  list[tuple[loc location, Statement astNode]] codeBlocks = extractCodeBlocks(asts);
  set[CloneClass] cloneClasses = detectType1Clones(codeBlocks);

  println("\nFound <size(cloneClasses)> Type-1 clone classes.\n");
  
  int classId = 1;
  for (CloneClass cc <- cloneClasses) {
    println("Clone Class <classId>: <size(cc)> instances");
    for (loc l <- cc) {
      println("  - <l>");
    }
    classId += 1;
  }
  println();

  int duplicatedLines = calculateDuplicatedLines(cloneClasses);
  int totalLOC = calculateTotalLOC(asts);
  real duplicationPercentage = calculateDuplicationPercentage(duplicatedLines, totalLOC);

  println("Type-1 Clone Detection Statistics:");
  println("Total lines of code: <totalLOC>");
  println("Duplicated lines: <duplicatedLines>");
  println("Percentage duplicated: <duplicationPercentage>%");
  println("Number of clone instances: <countClones(cloneClasses)>");
  println("Number of clone classes: <size(cloneClasses)>");
}

