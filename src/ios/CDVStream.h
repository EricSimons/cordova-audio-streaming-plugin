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

- (void) cordovaCreateStream:(CDVInvokedUrlCommand *)command;
- (void) cordovaPlayStream:(CDVInvokedUrlCommand *)command;
- (void) cordovaPauseStream:(CDVInvokedUrlCommand *)command;
- (void) cordovaDeleteStream:(CDVInvokedUrlCommand *)command;
//- (void) cordovaIsStreamReadyToPlay:()

@end
