'use strict';

// returns the value of `num1`
//console.log("ARgumentos")
//console.log(process.argv);

var myArgs = process.argv.slice(2);
//console.log('myArgs: ', myArgs);
var pathRoot = myArgs[0]
//console.log('pathRoot: ', pathRoot);
var pathTempRoot = myArgs[1]
//console.log('pathTempRoot: ', pathTempRoot);
var docId = myArgs[2]
//console.log('docId: ', docId);
var docName = myArgs[3]
//console.log('docName: ', docName);
var docExtension = myArgs[4]
//console.log('docExtension: ', docExtension);

const fs = require('fs');
const carbone = require('carbone');

let rawdata = fs.readFileSync(pathRoot+'/reqs.json');  
let data = JSON.parse(rawdata);

var options = {
variableStr  : '{#doc = '+docId+'}',
};

carbone.render(pathTempRoot, data, options, function(err, result){
if (err) return console.log(err);
fs.writeFileSync(pathRoot+'/'+docName+docExtension, result);
});



