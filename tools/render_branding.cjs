// Export our code-native SVG compositions; no browser or HTML rendering.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const images = fs.existsSync(path.join(root, 'release', 'images', 'overtime-banner-zh.svg')) ? path.join(root, 'release', 'images') : path.join(root, 'images');
const out = process.argv[2] ? path.resolve(process.argv[2]) : images;
(async () => {
  for (const name of ['overtime-banner-zh','overtime-banner-en','download-zh','download-en','social-preview-1.7']) {
    const input = path.join(out, name + '.svg');
    const output = path.join(out, name + '.png');
    await sharp(fs.readFileSync(input)).png({compressionLevel:9}).toFile(output);
    const meta = await sharp(output).metadata();
    console.log(`${name}.png: ${meta.width}x${meta.height}, ${fs.statSync(output).size} bytes`);
  }
  if (fs.statSync(path.join(out, 'social-preview-1.7.png')).size >= 1000000) throw Error('Social preview must stay below 1 MB');
})();
