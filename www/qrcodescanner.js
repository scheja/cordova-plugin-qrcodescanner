var exec = require('cordova/exec');

exports.startScan = function (x, y, width, height, success, error) {
    exec(success, error, "QRCodeScanner", "startScan", [x, y, width, height]);
};

exports.stopScan = function (success, error) {
    exec(success, error, "QRCodeScanner", "stopScan", []);
};
