export function renderPolymetric(rootData) {
  const container = document.getElementById("chart");
  container.innerHTML = "";

  const width = container.clientWidth;
  const height = container.clientHeight;
  const svg = d3.select(container).append("svg")
    .attr("width", width)
    .attr("height", height)
    .append("g")
    .attr("transform", "translate(40, 20)"); // Add some left margin for the root node

  const color = d3.scaleLinear()
    .domain([0, 50, 100])
    .range(["#28a745", "#ffea00", "#ff3b30"])
    .interpolate(d3.interpolateRgb);

  const tooltip = d3.select("#tooltip");

  // Get project averages for scaling
  const { avgLOC, avgFileCount } = rootData.projectMetrics || { avgLOC: 1, avgFileCount: 1 };
  const baseWidth = 100;
  const baseHeight = 30;
  const minVisualSize = 5;

  // 1. Convert data to D3 hierarchy (using LOC for value)
  const root = d3.hierarchy(rootData)
    .sum(d => d.lines_of_code || d.fileCount || 0) // Sum LOC for files, fileCount for dirs
    .sort((a, b) => b.value - a.value);

  // 2. Define the D3 Tree Layout
  const treeLayout = d3.tree()
    .size([height, width - 1200]) // [Y-Max, X-Max]
    .separation((a, b) => { // Tweak separation based on estimated visual height
      const aHeight = Math.log(a.data.lines_of_code || a.data.fileCount || 1);
      const bHeight = Math.log(b.data.lines_of_code || b.data.fileCount || 1);
      return (Math.log(aHeight) + Math.log(bHeight)) / 20 + 10.5;
    });

  // 3. Compute the layout
  const nodes = treeLayout(root).descendants();

  // 4. Calculate visual dimensions and adjust coordinates
  nodes.forEach(d => {
    // --- HEIGHT (Length) ---
    if (d.data.lines_of_code !== undefined) {
      // Files: Height relative to project average LOC
      d.visualHeight = Math.max(minVisualSize, baseHeight * (d.data.lines_of_code / avgLOC));
    } else {
      // Directories (Root/Module): Fixed height for readability
      d.visualHeight = baseHeight;
    }

    // --- WIDTH ---
    if (d.data.fileCount !== undefined) {
      // Directories (Module): Width relative to project average file count
      d.visualWidth = Math.max(baseWidth, baseWidth * (d.data.fileCount / avgFileCount));
    } else {
      // Files: Fixed width
      d.visualWidth = baseWidth;
    }

    // Adjust Y to be the top edge of the rectangle, not the center
    d.y = d.y - d.visualHeight / 2;
  });

  const maxX = d3.max(nodes, d => d.x + d.visualWidth) || width;
  const maxY = d3.max(nodes, d => d.y + d.visualHeight) || height;

  const requiredWidth = maxX + 40; // Add margin on the right
  const requiredHeight = maxY + 40; // Add margin at the bottom

  // Adjust the SVG dimensions to fit the content if it exceeds the initial size
  d3.select(container).select("svg")
    .attr("width", Math.max(width, requiredWidth))
    .attr("height", Math.max(height, requiredHeight));

  // Draw links
  svg.selectAll("path.link")
    .data(root.links())
    .enter()
    .append("path")
    .attr("class", "link")
    .attr("fill", "none")
    .attr("stroke", "#555")
    .attr("stroke-width", 1)
    .attr("d", d3.linkHorizontal()
      .x(d => d.x + d.visualWidth) // Start link at right edge of parent
      .y(d => d.y + d.visualHeight / 2) // Start link at center of parent node
    );

  // Draw nodes
  const g = svg.selectAll("g.node")
    .data(nodes)
    .enter()
    .append("g")
    .attr("class", "node")
    .attr("transform", d => `translate(${d.x},${d.y})`);

  g.append("rect")
    .attr("width", d => d.visualWidth - 4) // Apply width, subtract padding
    .attr("height", d => d.visualHeight)
    // Coloring logic: Files use their own %, Dirs use the calculated average %
    .attr("fill", d => {
      // All other nodes (Dirs and Files)
      if (d.data.duplicationPercent !== undefined) {
        return color(d.data.duplicationPercent);
      }
      return "#444"; // Default color if no duplication info
    })
    .attr("stroke", "#222")
    .on("mousemove", (event, d) => {
      if(d.data.lines_of_code || d.data.fileCount) {
        tooltip.style("opacity", 1)
          .style("left", (event.pageX + 12) + "px")
          .style("top", (event.pageY + 12) + "px")
          .html(renderTooltip(d));
      }
    })
    .on("mouseout", () => tooltip.style("opacity", 0));

  g.append("text")
    .attr("x", 4)
    .attr("y", 14)
    .attr("fill", "#fff")
    .style("pointer-events", "none")
    .style("font-size", "12px")
    .text(d => d.data.name);

  // tooltip helper
  function renderTooltip(d){
    const dd = d.data;
    let html = `<strong>${dd.name}</strong><br/>`;

    if(dd.filePath){
        html += `<small>${dd.filePath}</small><br/>`;
    }

    if(dd.lines_of_code !== undefined){
      html += `LOC: <strong>${dd.lines_of_code}</strong> (Avg LOC: ${Math.round(avgLOC)})<br/>`;
    }

    if(dd.fileCount !== undefined){
      html += `Files: <strong>${dd.fileCount}</strong> (Avg Files/Dir: ${Math.round(avgFileCount)})<br/>`;
    }

    if(dd.duplicationPercent !== undefined){
      html += `Duplication %: <strong>${dd.duplicationPercent}%</strong><br/>`;
      if(dd.duplicatedLines !== undefined){
          html += `Duplicated lines: <strong>${dd.duplicatedLines}</strong><br/>`;
      }

      if(Array.isArray(dd.mergedRanges) && dd.mergedRanges.length){
        html += `<div style="margin-top:6px"><strong>Ranges</strong><br/>`;
        for(const r of dd.mergedRanges){
          html += `&nbsp;&nbsp;${r.start} - ${r.end}<br/>`;
        }
        html += `</div>`;
      }
    }
    return html;
  }
}