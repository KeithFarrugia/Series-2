export function renderTreemap(rootData){
  const container = document.getElementById("chart");
  container.innerHTML = ""; // reset

  const width = container.clientWidth;
  const height = container.clientHeight;

  const svg = d3.select(container).append("svg")
    .attr("width", width)
    .attr("height", height);

  // create hierarchy: modules are parents; value -> linesOfCode (area)
  const droot = d3.hierarchy(rootData).sum(d => d.linesOfCode || 0).sort((a,b)=>b.value-a.value);

  const treemap = d3.treemap()
    .size([width, height])
    .paddingInner(6)
    .paddingTop(20) // leave room for module header
    .tile(d3.treemapResquarify);

  treemap(droot);

  const color = d3.scaleLinear()
    .domain([0, 50, 100])
    .range(["#28a745", "#ffea00", "#ff3b30"])
    .interpolate(d3.interpolateRgb);

  const tooltip = d3.select("#tooltip");

  // Draw group nodes (modules)
  const group = svg.selectAll("g.module")
    .data(droot.children || [])
    .enter().append("g")
      .attr("class","module")
      .attr("transform", d=> `translate(${d.x0},${d.y0})`);

  // module background rect (outline)
  group.append("rect")
    .attr("width", d=> Math.max(1, d.x1 - d.x0))
    .attr("height", d=> Math.max(1, d.y1 - d.y0))
    .attr("fill", "transparent")
    .attr("stroke", "#555")
    .attr("stroke-width", 1);

  // header bar
  group.append("rect")
    .attr("width", d=> Math.max(1, d.x1 - d.x0))
    .attr("height", 20)
    .attr("fill", "#333");

  group.append("text")
    .attr("x", 6)
    .attr("y", 14)
    .attr("class","module-header")
    .text(d => `${d.data.name} (${d.children.length})`);

  // draw leaves inside each group
  const leaves = [];
  droot.each(node=>{
    if(node.children==null && node.depth>0){
      // it's a file leaf. push the data plus absolute positions.
      leaves.push(node);
    }
  });

  const leafG = svg.selectAll("g.leaf")
    .data(leaves)
    .enter().append("g")
    .attr("class","leaf")
    .attr("transform", d => `translate(${d.x0},${d.y0})`);

  leafG.append("rect")
    .attr("width", d => Math.max(1, d.x1 - d.x0))
    .attr("height", d => Math.max(1, d.y1 - d.y0))
    .attr("fill", d => color(d.data.duplicationPercent || 0))
    .attr("stroke", "#222")
    .on("mousemove", (event, d) => {
      tooltip.style("opacity", 1)
        .style("left", (event.pageX + 12) + "px")
        .style("top", (event.pageY + 12) + "px")
        .html(renderTooltip(d));
    })
    .on("mouseout", () => tooltip.style("opacity", 0));

  leafG.append("text")
    .attr("x", 6)
    .attr("y", 16)
    .attr("fill", "#fff")
    .style("pointer-events","none")
    .style("font-size","12px")
    .text(d => d.data.name);

  // small subtext for percent if space
  leafG.append("text")
    .attr("x", 6)
    .attr("y", 32)
    .attr("fill", "#fff")
    .style("pointer-events","none")
    .style("font-size","11px")
    .text(d => {
      const pct = d.data.duplicationPercent || 0;
      return `${pct}% duplicated`;
    });

  // helper to render tooltip HTML
  function renderTooltip(d){
    const dd = d.data;
    let html = `<strong>${dd.name}</strong><br/><small>${dd.filePath || ""}</small><br/>`;
    html += `LOC: <strong>${dd.linesOfCode}</strong><br/>`;
    html += `Duplicated lines: <strong>${dd.duplicatedLines}</strong> (${dd.duplicationPercent}%)<br/>`;
    if(Array.isArray(dd.mergedRanges) && dd.mergedRanges.length){
      html += `<div style="margin-top:6px"><strong>Ranges</strong><br/>`;
      for(const r of dd.mergedRanges){
        html += `&nbsp;&nbsp;${r.start} - ${r.end}<br/>`;
      }
      html += `</div>`;
    }
    return html;
  }
}