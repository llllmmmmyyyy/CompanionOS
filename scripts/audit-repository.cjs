// Tracked-file hygiene check; prints paths/rule names, never matched secret values.
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const root = path.resolve(__dirname, '..');
const files = cp.execFileSync('git', ['-c', `safe.directory=${root.replaceAll('\\', '/')}`, 'ls-files', '-z'], { cwd: root }).toString().split('\0').filter(Boolean);
const findings = [];
const rules = [
  ['private-key', /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/],
  ['recognized-token', /(?:AIza[0-9A-Za-z_-]{30,}|ghp_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{40,}|sk-[0-9A-Za-z_-]{30,})/],
  ['personal-machine-path', /[A-Za-z]:[\\/]Users[\\/][^\s\\/]+[\\/]/],
];
for (const file of files) {
  if (/(?:^|\/)(?:node_modules|oh_modules|build|dist|artifacts|certificates|signing)\/|(?:^|\/)(?:local\.properties|\.env(?:\..*)?)$|\.(?:hap|hsp|pem|key|p12|pfx|jks|keystore|cer|crt|p7b|profile)$/i.test(file) && !file.endsWith('/.env.example')) {
    findings.push({ file, rule: 'forbidden-tracked-path' });
  }
  const bytes = fs.readFileSync(path.join(root, file));
  if (bytes.includes(0)) continue;
  const text = bytes.toString('utf8');
  for (const [name, pattern] of rules) if (pattern.test(text)) findings.push({ file, rule: name });
  if (file.endsWith('/.env.example') && /^[ \t]*[A-Z0-9_]*(?:API_KEY|TOKEN|PASSWORD|SECRET)[ \t]*=[ \t]*[^\s#]/m.test(text)) findings.push({ file, rule: 'nonblank-example-secret' });
}
console.log(JSON.stringify({ trackedFiles: files.length, findings }, null, 2));
if (findings.length) process.exitCode = 1;
