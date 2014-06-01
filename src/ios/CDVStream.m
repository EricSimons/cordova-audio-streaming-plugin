//
//  CDVStream.m
//
//  Created by sonny on 5/27/14.
//
//

#import <Cordova/CDV.h>
#import "CDVStream.h"

@interface CDVStream()

@property (nonatomic, strong) NSMutableDictionary *audioPlayerDict;
@property (nonatomic, strong) NSMutableDictionary *callbackDict;

@property (nonatomic, strong) AVPlayer *audioPlayer;

@end

@implementation CDVStream

#pragma mark lazy instantiation methods

- (NSMutableDictionary *)audioPlayerDict {
    if (!_audioPlayerDict) _audioPlayerDict = [[NSMutableDictionary alloc] init];
    return _audioPlayerDict;
}

- (AVPlayer *)audioPlayer {
    if (!_audioPlayer) _audioPlayer = [[AVPlayer alloc] init];
    _audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    return _audioPlayer;
}


#pragma mark cordova interface methods

- (void) cordovaCreateStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    NSString *urlString = command.arguments[1];
    NSString *queueName = [NSString stringWithFormat:@"%@ stream queue", urlString];
    
    //const char *cQueueName = [queueName cStringUsingEncoding:NSASCIIStringEncoding];
    
    //dispatch_queue_t streamQueue = dispatch_queue_create(cQueueName, NULL);
    
    //dispatch_async(streamQueue, ^{
        NSURL *url = [NSURL URLWithString:urlString];
        
        //AudioStreamerPlayerItem *item = [[AudioStreamerPlayerItem alloc] initWithURL:url];
        AVPlayer *item = [[AVPlayer alloc] initWithURL:url];
        [item addObserver:self forKeyPath:@"status" options:0 context:NULL];
        [item play];
        //item.mediaID = mediaID;
        //item.callbackID = command.callbackId;
        
        self.callbackDict[mediaID] = command.callbackId;
        self.audioPlayerDict[mediaID] = item;
    //});
}

- (void) cordovaPlayStream:(CDVInvokedUrlCommand *)command {
    [self.audioPlayer pause];
    NSString *mediaID = command.arguments[0];
    
    AVPlayer *itemToPlay = self.audioPlayerDict[mediaID];
    if (itemToPlay != self.audioPlayer) {
        self.audioPlayer = itemToPlay;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.audioPlayer currentItem]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.audioPlayer play];
    });
}

- (void) cordovaPauseStream:(CDVInvokedUrlCommand *)command {
    [self.audioPlayer pause];
}

- (void) cordovaDeleteStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    AVPlayer *itemToDelete = self.audioPlayerDict[mediaID];
    
    if (self.audioPlayer == itemToDelete) {
        [self.audioPlayer pause];
        self.audioPlayer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:itemToDelete];

    [self.audioPlayerDict removeObjectForKey:mediaID];
    [self.callbackDict removeObjectForKey:mediaID];
}


#pragma mark key value observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if ([object isKindOfClass:[AVPlayer class]]) {
            NSDictionary *jsonObj;
            
            // we assume that when initialized, the status of a AVPlayer is == AVPlayerStatusUnknown
            AVPlayer *item = (AVPlayer *)object;
            BOOL isAudioReadyToPlay = item.status == AVPlayerStatusReadyToPlay;
            
            jsonObj = @{ @"success": isAudioReadyToPlay ? @"true" : @"false"};
            
            CDVCommandStatus commandStatus = isAudioReadyToPlay ? CDVCommandStatus_OK : CDVCommandStatus_ERROR;
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:commandStatus];
            
            NSArray *objectsForItem = [self.audioPlayerDict allKeysForObject:item];
            NSString *mediaID = [objectsForItem firstObject];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackDict[mediaID]];
        }
    }
}


#pragma mark player item did reach end selector

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *item = [notification object];
    [item seekToTime:kCMTimeZero];
    [self.audioPlayer pause];
}

@end















