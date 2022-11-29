var fs = require('fs-extra');

// Returns the current working directory of the process; console.log('Current directory: ' + process.cwd());
var rootDir = process.cwd();

//copies directory and subdirectories
fs.copy(rootDir + '/www/project/android', rootDir + '/platforms/android/res', function (err) {
    if (err) return console.error(err + ' An error occured! \r\n');

    process.stdout.write('Resources successfully copied! \r\n');
});
