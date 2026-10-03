const fs = require('node:fs'); const path = require('node:path'); const vm = require('node:vm');
module.exports = ts => {
 function load(name) { if(name==='GameBoard')return {GameBoard:()=>{}};if(name==='Network')return {backendRequest:async()=>{throw Error('Network not mocked')}};
 const box={exports:{},Date,Math,Number,JSON,Array,require:id=>load(id.replace('./',''))};
 vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(__dirname,'../shared',name+'.ets'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2021}}).outputText,box);return box.exports; }
 return load('Index');
};
