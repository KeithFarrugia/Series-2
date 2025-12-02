module Conf

public loc clonesJson = |project://series2/clones.json|;

public data Clone = clone(
    list [Location] locations,
    int fragmentLength,
    int cloneType,
    str _id,
    str name
);

// Ignore for now
// Represents an individual location in the JSON 'locations' list
public data Location = location(
    str filePath,
    int startLine,
    int endLine
);

// Represents the entire JSON structure
public data ProjectClones = projectClones(
    str projectRoot,
    list[Clone] clones
);