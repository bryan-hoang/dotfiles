const { readFileSync } = require('fs');

const eslintConfig = JSON.parse(readFileSync('.eslintrc.json', 'utf8'));

module.exports = eslintConfig;
