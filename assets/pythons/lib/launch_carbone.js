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
var docId = myArgs[1]
//console.log('docId: ', docId);
var docName = myArgs[2]
//console.log('docName: ', docName);

const fs = require('fs');
const carbone = require('carbone');

let rawdata = fs.readFileSync(pathRoot+'/reqs.json');  
let data = JSON.parse(rawdata);

var options = {
variableStr  : '{#doc = '+docId+'}',
};

carbone.render(pathTempRoot+'/reqs_template.odt', data, options, function(err, result){
if (err) return console.log(err);
fs.writeFileSync(pathRoot+'/'+docName+'.odt', result);
});

carbone.render(pathTempRoot+'/reqs_template.ods', data, options, function(err, result){
if (err) return console.log(err);
fs.writeFileSync(pathRoot+'/'+docName+'.ods', result);
});


