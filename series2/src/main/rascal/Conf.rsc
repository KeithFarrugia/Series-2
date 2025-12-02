module Conf

public loc clonesJson = |project://series2/clones.json|;

public data Clone = clone(
    loc file,
    int startLine,
    int endLine,
    int length,
    int cloneType
);

list [Clone] Clones = [];