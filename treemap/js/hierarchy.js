/* ------------- Build D3 hierarchy (modules -> files). value = lines_of_code ------------- */
export function buildHierarchy(data, moduleFilterSet, typeFilterSet){
  // moduleFilterSet: Set of module names to include (if empty => include all)
  // typeFilterSet: Set of clone types selected (e.g. 'type1','type2','type3'); if empty => include all

  const root = { name: data.projectRoot, children: [] };

  for(const mod of data.modules){
    if(moduleFilterSet.size && !moduleFilterSet.has(mod.name)) continue;

    const modNode = { name: mod.name, children: [] };
    for(const file of mod.files){
      // apply type filter: determine if file contains any ranges for selected types
      let passesTypeFilter = true;
      if(typeFilterSet.size){
        passesTypeFilter = false;
        for(const t of typeFilterSet){
          const key = `${t}_duplicatedLines`;
          if(file.cloneTypes && Array.isArray(file.cloneTypes[key]) && file.cloneTypes[key].length>0){
            passesTypeFilter = true; break;
          }
        }
      }
      if(!passesTypeFilter) continue;

      // leaf node
      modNode.children.push({
        name: file.name,
        filePath: file.filePath,
        lines_of_code: file.lines_of_code || 0,
        duplicationPercent: file._dup.duplicationPercent,
        duplicatedLines: file._dup.duplicatedLines,
        mergedRanges: file._dup.mergedRanges,
        cloneTypes: file.cloneTypes || {}
      });
    }

    // only add module if it has children after filtering
    if(modNode.children.length>0) root.children.push(modNode);
  }

  return root;
}