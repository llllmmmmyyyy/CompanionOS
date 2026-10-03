import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const id = process.argv[2];
if (!/^[a-f0-9]{64}$/.test(id || '')) throw new Error('Usage: npm run review -- <videoId>, after an adult reviews the stored MP4');
const metadata = resolve('data', 'videos', `${id}.json`);
const value = JSON.parse(await readFile(metadata, 'utf8'));
value.reviewed = true; value.reviewedAt = Date.now();
await writeFile(metadata, JSON.stringify(value));
console.log('Video marked reviewed. This command does not itself inspect or moderate the video.');
