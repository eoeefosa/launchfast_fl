const fs = require('fs');
const path = require('path');

const libDir = '/Users/admin/Downloads/code/nodejs/project/launchfast-fl/lib';
const nodes = [];
const links = [];

function traverse(dir, parentId = null) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const fullPath = path.join(dir, file);
    const stats = fs.statSync(fullPath);
    const id = fullPath.replace('/Users/admin/Downloads/code/nodejs/project/launchfast-fl/', '');
    
    nodes.push({
      id,
      name: file,
      isDir: stats.isDirectory(),
      parentId
    });

    if (stats.isDirectory()) {
      traverse(fullPath, id);
    } else if (file.endsWith('.dart')) {
      // Find imports
      const content = fs.readFileSync(fullPath, 'utf8');
      const lines = content.split('\n');
      lines.forEach(line => {
        const match = line.match(/^import ['"](package:launchfast\/|.*\.dart)['"];/);
        if (match) {
          let target = match[1];
          if (target.startsWith('package:launchfast/')) {
            target = 'lib/' + target.replace('package:launchfast/', '');
          } else {
            // Relative path
            target = path.normalize(path.join(path.dirname(id), target));
          }
          links.push({ source: id, target });
        }
      });
    }
  });
}

traverse(libDir);

// Filter links to only include targets that exist in nodes
const nodeIds = new Set(nodes.map(n => n.id));
const validLinks = links.filter(l => nodeIds.has(l.target));

fs.writeFileSync('/Users/admin/Downloads/code/nodejs/project/launchfast-fl/graph_data.json', JSON.stringify({ nodes, links: validLinks }, null, 2));
console.log('Graph data generated');
