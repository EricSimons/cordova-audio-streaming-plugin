//
//  CDVStream.h
//
//  Created by sonny on 5/27/14.
//
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>

/* @interface AudioStreamerPlayerItem : AVPlayerItem */

/* @property (nonatomic, strong) NSString *mediaID; */
/* @property (nonatomic, strong) NSString *callbackID; */

/* @end */

@interface CDVStream : CDVPlugin


// creates an audio stream
- (void) cordovaCreateStream:(CDVInvokedUrlCommand *)command;

// plays the stream
- (void) cordovaPlayStream:(CDVInvokedUrlCommand *)command;

// pauses the player
- (void) cordovaPauseStream:(CDVInvokedUrlCommand *)command;

// pauses the player and resets the time of stream to 0:00
- (void) cordovaStopStream:(CDVInvokedUrlCommand *)command;

// sets all pointers to any stream related objects to nil
- (void) cordovaDestroyStream:(CDVInvokedUrlCommand *)command;

// seeks the player to the passed in position in stream
- (void) cordovaSeekToPositionInStream:(CDVInvokedUrlCommand *)command;



// adds a callback function to be called in a set interval
- (void) cordovaAddCallbackFunctionForInterval:(CDVInvokedUrlCommand *)command;

// removes the callback that was added
- (void) cordovaRemoveCallbackFunctionForInterval:(CDVInvokedUrlCommand *)command;


// adds a callback function to be called after audio has finished playing
- (void)cordovaAddEndOfStreamCallbackFunction:(CDVInvokedUrlCommand *)command;

// removes the finished playing callback
- (void)cordovaRemoveEndOfStreamCallbackFunction:(CDVInvokedUrlCommand *)command;


@end
