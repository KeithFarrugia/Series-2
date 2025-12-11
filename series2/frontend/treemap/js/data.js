/** Merge overlapping ranges array [{start,end},...] and return merged array */
export function mergeRanges(ranges){
  // (mergeRanges function remains unchanged)
  if(!ranges || ranges.length===0) return [];
  const arr = ranges.map(r=>({start: r.start, end: r.end})).sort((a,b)=>a.start-b.start);
  const out = [arr[0]];
  for(let i=1;i<arr.length;i++){
    const cur = arr[i];
    const last = out[out.length-1];
    if(cur.start <= last.end + 1){
      last.end = Math.max(last.end, cur.end);
    } else {
      out.push(cur);
    }
  }
  return out;
}

/** * Pre-processes file structure by collecting raw, unmerged clone ranges 
 * and organizing them by clone type, clamping them to file bounds.
 */
function prepareFileRawRanges(file, allClones){
  const cloneTypeRanges = { 'type1': [], 'type2': [], 'type3': [] };

  // Collect raw ranges and group them by type
  for(const cloneGroup of allClones.clones){
    const typeKey = `type${cloneGroup.cloneType}`;
    if (!cloneTypeRanges[typeKey]) continue;

    for(const loc of cloneGroup.locations){
      if(loc.filePath === file.filePath){
        if(typeof loc.startLine === "number" && typeof loc.endLine === "number"){
          // We must use the absolute line numbers provided by the cloning tool
          // as they refer to the physical lines, allowing clones outside the
          // non-commented LOC range to be counted.
          const start = Math.max(1, loc.startLine);
          // Set the end line to the tool's reported end line, bypassing LOC validation.
          const end = loc.endLine; 

          // We only check for valid range length.
          if(end >= start) {
            cloneTypeRanges[typeKey].push({ start, end });
          }
        }
      }
    }
  }

  // Store the raw range data by type for filtering and dynamic calculation
  file._rawCloneRanges = cloneTypeRanges;
}


/* ------------- Prepare data: only prepare raw ranges, no final metrics ------------- */
/** Merges clone information into the file structure. */
export function prepareData(fileStructure, cloneData){
  for(const module of fileStructure.modules){
    for(const file of module.files){
      prepareFileRawRanges(file, cloneData);
    }
  }
}

// NEW FUNCTION: Calculates metrics based on a specific filter set
export function calculateFilteredDuplication(file, typeFilterSet) {
    const allRanges = [];

    // 1. Collect ranges only from the types present in the filter set
    for (const t of typeFilterSet) { // t is like 'type1', 'type2', etc.
        if (file._rawCloneRanges && file._rawCloneRanges[t]) {
            allRanges.push(...file._rawCloneRanges[t]);
        }
    }

    // 2. Compute merged duplicated lines and percentage
    const merged = mergeRanges(allRanges);
    let duplicatedLines = 0;
    for(const r of merged) duplicatedLines += (r.end - r.start + 1);

    const loc = file.linesOfCode || 0;
    // Round to 1 decimal place (multiply by 1000, round, divide by 10)
    const duplicationPercent = loc > 0 ? Math.round((duplicatedLines / loc) * 1000) / 10 : 0;

    return {
        duplicatedLines,
        duplicationPercent,
        mergedRanges: merged // useful for tooltips/drilldown
    };
}