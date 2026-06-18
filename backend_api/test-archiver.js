const fs = require('fs');

async function testArchiver() {
  const m = await import('archiver');
  const archive = new m.ZipArchive({ zlib: { level: 9 } });
  
  const output = fs.createWriteStream('test.zip');
  archive.pipe(output);
  
  archive.append('Hello World', { name: 'hello.txt' });
  await archive.finalize();
  
  console.log('Zip created successfully');
}

testArchiver().catch(console.error);
