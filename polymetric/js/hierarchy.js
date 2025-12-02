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
        cloneTypes: file.cloneTypes || {},
        
      });
    }

    // only add module if it has children after filtering
    if(modNode.children.length>0) {
      // CALCULATE AVERAGE DUPLICATION PERCENT FOR THE DIRECTORY (modNode)
      let totalDuplicationPercent = 0;
      for(const child of modNode.children){
          totalDuplicationPercent += child.duplicationPercent;
      }
      modNode.duplicationPercent = totalDuplicationPercent / modNode.children.length;

      // Add the file count metric
      modNode.fileCount = modNode.children.length;

      root.children.push(modNode);
    }
  }
  root.projectMetrics = data.projectMetrics;

  let rootTotalDuplicationPercent = 0;
  let rootTotalFileCount = 0;

  if(root.children.length > 0) {
      for(const child of root.children){
          // Duplication: Sum up the duplication percent of all Level 1 modules
          // We'll average it out based on the number of files total
          rootTotalDuplicationPercent += (child.duplicationPercent || 0) * child.fileCount;
          rootTotalFileCount += child.fileCount;
      }
      
      // Calculate the weighted average duplication percent for the project root
      if (rootTotalFileCount > 0) {
          root.duplicationPercent = Math.round((rootTotalDuplicationPercent / rootTotalFileCount) * 10) / 10;
      } else {
          root.duplicationPercent = 0;
      }
      
      // Total file count for the root
      root.fileCount = rootTotalFileCount;
  } else {
      root.duplicationPercent = 0;
      root.fileCount = 0;
  }
  
  return root;
}