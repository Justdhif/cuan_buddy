import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dirsToProcess = [
  path.join(__dirname, 'src', 'components'),
  path.join(__dirname, 'src')
];

function processDirectory(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory() && file !== 'components' && file !== 'assets' && file !== 'locales') {
       processDirectory(fullPath);
    } else if (fullPath.endsWith('.tsx') || fullPath.endsWith('.ts')) {
       let content = fs.readFileSync(fullPath, 'utf8');
       let newContent = content;

       // Replace [var(--color-primary)] -> primary
       newContent = newContent.replace(/\[var\(--color-primary\)]/g, 'primary');
       newContent = newContent.replace(/\[var\(--color-secondary\)]/g, 'secondary');
       newContent = newContent.replace(/\[var\(--color-accent\)]/g, 'accent');
       
       newContent = newContent.replace(/\[var\(--background\)]/g, 'background');
       newContent = newContent.replace(/\[var\(--foreground\)]/g, 'foreground');
       newContent = newContent.replace(/\[var\(--card\)]/g, 'card');
       newContent = newContent.replace(/\[var\(--border\)]/g, 'border');

       // Handle cases where we have border-border if we use border as color
       // wait, border-[var(--border)] -> border-border
       
       if (newContent !== content) {
         fs.writeFileSync(fullPath, newContent);
         console.log(`Updated ${fullPath}`);
       }
    }
  }
}

for (const dir of dirsToProcess) {
  processDirectory(dir);
}
