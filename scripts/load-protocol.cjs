// Load the actual shared ArkTS model for host tests; network is intentionally unavailable.
const fs = require('node:fs'); const path = require('node:path'); const vm = require('node:vm');
module.exports = ts => {
  const box = { exports: {}, Number, JSON, Array, Error,
    require: () => ({ backendRequest: async () => { throw Error('Network not mocked'); } }) };
  vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.resolve(__dirname, '../shared/Index.ets'), 'utf8'),
    { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 } }).outputText, box);
  return box.exports;
};
