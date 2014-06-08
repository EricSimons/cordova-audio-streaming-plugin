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
@property (nonatomic, strong) NSMutableDictionary *continuousCallbackDict;
@property (nonatomic, strong) NSMutableDictionary *continuousCallbackIDDict;


@property (nonatomic, strong) AVPlayer *audioPlayer;

@end

@implementation CDVStream

#pragma mark lazy instantiation methods

- (NSMutableDictionary *)audioPlayerDict {
    if (!_audioPlayerDict) _audioPlayerDict = [[NSMutableDictionary alloc] init];
    return _audioPlayerDict;
}


- (NSMutableDictionary *)callbackDict {
    if (!_callbackDict) _callbackDict = [[NSMutableDictionary alloc] init];
    
    return _callbackDict;
}

- (NSMutableDictionary *)continuousCallbackDict {
    if (!_continuousCallbackDict) _continuousCallbackDict = [[NSMutableDictionary alloc] init];
    
    return _continuousCallbackDict;
}

- (NSMutableDictionary *)continuousCallbackIDDict {
    if (!_continuousCallbackIDDict) _continuousCallbackIDDict = [[NSMutableDictionary alloc] init];
    
    return _continuousCallbackIDDict;
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
    //NSString *queueName = [NSString stringWithFormat:@"%@ stream queue", urlString];
    //const char *cQueueName = [queueName cStringUsingEncoding:NSASCIIStringEncoding];
    //dispatch_queue_t streamQueue = dispatch_queue_create(cQueueName, NULL);
    //dispatch_async(streamQueue, ^{
    //[self.commandDelegate runInBackground:^{
        NSURL *url = [NSURL URLWithString:urlString];
        AVPlayer *item = [[AVPlayer alloc] initWithURL:url];
        [item addObserver:self forKeyPath:@"status" options:0 context:NULL];
        [item play];
        [item pause];
        
        self.callbackDict[mediaID] = command.callbackId;
        self.audioPlayerDict[mediaID] = item;
    //}];
    
        //AudioStreamerPlayerItem *item = [[AudioStreamerPlayerItem alloc] initWithURL:url];

        //item.mediaID = mediaID;
        //item.callbackID = command.callbackId;
        

    //});
}


- (void) cordovaPlayStream:(CDVInvokedUrlCommand *)command {
    [self.audioPlayer pause];
    NSString *mediaID = command.arguments[0];
    
    AVPlayer *itemToPlay = self.audioPlayerDict[mediaID];
    if ([itemToPlay currentItem] != [self.audioPlayer currentItem]) {
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


- (void) cordovaStopStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    AVPlayer *itemToStop = self.audioPlayerDict[mediaID];
    
    if ([itemToStop currentItem] == [self.audioPlayer currentItem]) {
        [self.audioPlayer pause];
    }
    
    [self.audioPlayer seekToTime:kCMTimeZero];
}


- (void) cordovaDestroyStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    AVPlayer *itemToDelete = self.audioPlayerDict[mediaID];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:itemToDelete];
    
    if ([self.audioPlayer currentItem] == [itemToDelete currentItem]) {
        [self.audioPlayer pause];
        self.audioPlayer = nil;
    }

    [self.audioPlayerDict removeObjectForKey:mediaID];
    [self.callbackDict removeObjectForKey:mediaID];
}


- (void) cordovaSeekToPositionInStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    NSInteger timeInMilliseconds = [command.arguments[1] integerValue];
    
    CMTime timeToSeekTo = CMTimeMake(timeInMilliseconds, 1000);
    
    AVPlayer *itemToSeek = self.audioPlayerDict[mediaID];
    
    [itemToSeek seekToTime:timeToSeekTo completionHandler:^(BOOL finished) {
        CDVCommandStatus status = finished ? CDVCommandStatus_OK : CDVCommandStatus_ERROR;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:status];
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}


- (void) cordovaAddCallbackFunctionForInterval:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    AVPlayer *player = self.audioPlayerDict[mediaID];
    
    self.continuousCallbackIDDict[mediaID] = command.callbackId;
    
    NSUInteger maxSeconds = floor(CMTimeGetSeconds([[[player currentItem] asset] duration]));
    
    NSMutableArray *timesArray = [[NSMutableArray alloc] initWithCapacity:maxSeconds];
    
    for (NSUInteger i = 1; i <= maxSeconds; i++) {
        timesArray[i - 1] = [NSValue valueWithCMTime:CMTimeMake((NSUInteger)i, 1)];
    }
    
    const char *queueName = [[NSString stringWithFormat:@"callback %@", mediaID] UTF8String];
    
    self.continuousCallbackDict[mediaID] = [player addBoundaryTimeObserverForTimes:timesArray queue:dispatch_queue_create(queueName, NULL) usingBlock:^{
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:self.continuousCallbackIDDict[mediaID]];
    }];
}

- (void) cordovaRemoveCallbackFunctionForInterval:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    id boundaryObj = self.continuousCallbackDict[mediaID];
    
    AVPlayer *player = self.audioPlayerDict[mediaID];
    
    [player removeTimeObserver:boundaryObj];
}


#pragma mark KVO delegate methods

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













