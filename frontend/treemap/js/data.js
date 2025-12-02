/** Merge overlapping ranges array [{start,end},...] and return merged array */
function mergeRanges(ranges){
  if(!ranges || ranges.length===0) return [];
  // copy and sort by start
  const arr = ranges.map(r=>({start: r.start, end: r.end})).sort((a,b)=>a.start-b.start);
  const out = [arr[0]];
  for(let i=1;i<arr.length;i++){
    const cur = arr[i];
    const last = out[out.length-1];
    if(cur.start <= last.end + 1){ // overlap or contiguous
      last.end = Math.max(last.end, cur.end);
    } else {
      out.push(cur);
    }
  }
  return out;
}

/** Given a file object, collect all ranges from all types and compute duplicated lines sum (merged),
    and produce duplicationPercent */
function computeDuplicationForFile(file){
  const allRanges = [];
  if(file.cloneTypes){
    for(const t of ["type1","type2","type3"]){
      const key = `${t}_duplicatedLines`;
      if(Array.isArray(file.cloneTypes[key])){
        for(const r of file.cloneTypes[key]){
          if(typeof r.start === "number" && typeof r.end === "number"){
            // clamp into file bounds
            const start = Math.max(1, r.start);
            const end = Math.min(file.lines_of_code || Infinity, r.end);
            if(end >= start) allRanges.push({start, end});
          }
        }
      }
    }
  }
  const merged = mergeRanges(allRanges);
  let duplicatedLines = 0;
  for(const r of merged) duplicatedLines += (r.end - r.start + 1);
  const loc = file.lines_of_code || 0;
  const duplicationPercent = loc>0 ? Math.round((duplicatedLines / loc) * 1000)/10 : 0; // 1 dec
  file._dup = {
    duplicatedLines,
    mergedRanges: merged,
    duplicationPercent
  };
}

/* ------------- Prepare data: compute duplication for each file ------------- */
export function prepareData(data){
  for(const module of data.modules){
    for(const file of module.files){
      computeDuplicationForFile(file);
    }
  }
}
