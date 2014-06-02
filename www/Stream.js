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

    exec(this.successCallback, this.errorCallback, "Stream", "cordovaCreateStream", [this.id, this.src]);
};

Stream.get = function(id) {
    return streamObjects[id];
};

Stream.prototype.play = function() {
    console.log('i am in play');
    exec(null, null, "Stream", "cordovaPlayStream", [this.id]);
};

Stream.prototype.pause = function() {
    exec(null, null, "Stream", "cordovaPauseStream", []);
};

Stream.prototype.destroy = function() {
    exec(null, null, "Stream", "cordovaDeleteStream", [this.id]);
};

module.exports = Stream;
