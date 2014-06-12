var argscheck = require('cordova/argscheck');
var exec = require('cordova/exec');
var utils = require('cordova/utils');

var streamObjects = {};


/*
 * This class provides audio streaming capability on iOS.
 *
 * @constructor
 * @param src: The remote url to play.
 * @param successCallback: The callback to be called when the file is ready to play / buffered.
 * @param errorCallback: The callback to be called if an error occurs.
 *
 * Note: the buffering takes place on a serial dispatch queue. Also, when the audio file reaches the end, it automatically seeks back to the beginning.
 */

var Stream = function(src, successCallback, errorCallback) {
    this.id = utils.createUUID();
    streamObjects[this.id] = this;
    this.src = src;
    this.successCallback = successCallback;
    this.errorCallback = errorCallback;

    exec(this.successCallback, this.errorCallback, "Stream", "cordovaCreateStream", [this.id, this.src, 103]);
};

Stream.get = function(id) {
    return streamObjects[id];
};


Stream.prototype.play = function() {
    exec(null, null, "Stream", "cordovaPlayStream", [this.id]);
};


Stream.prototype.pause = function() {
    exec(null, null, "Stream", "cordovaPauseStream", []);
};


Stream.prototype.stop = function() {
    exec(null, null, "Stream", "cordovaStopStream", [this.id]);
};


Stream.prototype.destroy = function() {
    exec(null, null, "Stream", "cordovaDestroyStream", [this.id]);
};

// the time argument is in milliseconds, represented by an integer
Stream.prototype.seekToTime = function(time, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "Stream", "cordovaSeekToPositionInStream", [this.id, time]);
};

// the successCallback is called on second intervals
Stream.prototype.addCallbackToCallAtSecondsInterval = function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, "Stream", "cordovaAddCallbackFunctionForInterval", [this.id]);
};


Stream.prototype.removeCallbackToCallAtSecondsInterval = function() {
    exec(null, null, "Stream", "cordovaRemoveCallbackFunctionForInterval", [this.id]);
};


Stream.prototype.addEndOfStreamCallbackFunction = function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, "Stream", "cordovaAddEndOfStreamCallbackFunction", [this.id]);
};


Stream.prototype.removeEndOfStreamCallbackFunction = function() {
    exec(null, null, "Stream", "cordovaRemoveEndOfStreamCallbackFunction", [this.id]);
};

module.exports = Stream;
