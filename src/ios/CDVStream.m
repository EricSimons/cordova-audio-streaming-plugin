//
//  CDVStream.m
//
//  Created by sonny on 5/27/14.
//
//

#import <Cordova/CDV.h>
#import "CDVStream.h"

@interface CDVStream()

@property (nonatomic, strong) NSMutableDictionary *audioPlayerItemsDict;
@property (nonatomic, strong) NSMutableDictionary *callbackDict;

@property (nonatomic, strong) AVPlayerItem *currentlyPlayingItem;
@property (nonatomic, strong) AVPlayer *audioPlayer;

@end

@implementation CDVStream

#pragma mark lazy instantiation methods

- (NSMutableDictionary *)audioPlayerItemsDict {
    if (!_audioPlayerItemsDict) _audioPlayerItemsDict = [[NSMutableDictionary alloc] init];
    return _audioPlayerItemsDict;
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
    
    const char *cQueueName = [queueName cStringUsingEncoding:NSASCIIStringEncoding];
    
    dispatch_queue_t streamQueue = dispatch_queue_create(cQueueName, NULL);
    
    dispatch_async(streamQueue, ^{
        NSURL *url = [NSURL URLWithString:urlString];
        
        //AudioStreamerPlayerItem *item = [[AudioStreamerPlayerItem alloc] initWithURL:url];
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:url];
        [item addObserver:self forKeyPath:@"status" options:0 context:NULL];
        //item.mediaID = mediaID;
        //item.callbackID = command.callbackId;
        
        self.callbackDict[mediaID] = command.callbackId;
        self.audioPlayerItemsDict[mediaID] = item;
    });
}

- (void) cordovaPlayStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    AVPlayerItem *itemToPlay = self.audioPlayerItemsDict[mediaID];
    if (itemToPlay != self.currentlyPlayingItem) {
        [self.audioPlayer replaceCurrentItemWithPlayerItem:itemToPlay];
        self.currentlyPlayingItem = itemToPlay;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.audioPlayer currentItem]];
    
    [self.audioPlayer play];
}

- (void) cordovaPauseStream:(CDVInvokedUrlCommand *)command {
    [self.audioPlayer pause];
}

- (void) cordovaDeleteStream:(CDVInvokedUrlCommand *)command {
    NSString *mediaID = command.arguments[0];
    
    AVPlayerItem *itemToDelete = self.audioPlayerItemsDict[mediaID];
    
    if (self.currentlyPlayingItem == itemToDelete) {
        [self.audioPlayer pause];
        self.audioPlayer = nil;
        self.currentlyPlayingItem = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:itemToDelete];

    [self.audioPlayerItemsDict removeObjectForKey:mediaID];
    [self.callbackDict removeObjectForKey:mediaID];
}


#pragma mark key value observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if ([object isKindOfClass:[AVPlayerItem class]]) {
            NSDictionary *jsonObj;
            
            // we assume that when initialized, the status of a AVPlayerItem is == AVPlayerStatusUnknown
            AVPlayerItem *item = (AVPlayerItem *)object;
            BOOL isAudioReadyToPlay = item.status == AVPlayerStatusReadyToPlay;
            
            jsonObj = @{ @"success": isAudioReadyToPlay ? @"true" : @"false"};
            
            CDVCommandStatus commandStatus = isAudioReadyToPlay ? CDVCommandStatus_OK : CDVCommandStatus_ERROR;
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:commandStatus];
            
            NSArray *objectsForItem = [self.audioPlayerItemsDict allKeysForObject:item];
            NSString *mediaID = [objectsForItem firstObject];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackDict[mediaID]];
        }
    }
}


#pragma mark player item did reach end selector

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *item = [notification object];
    [item seekToTime:kCMTimeZero];
}

@end















