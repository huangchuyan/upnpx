//
//  PlayBack.m
//  upnpxdemo
//
//  Created by Bruno Keymolen on 03/03/12.
//  Copyright 2012 Bruno Keymolen. All rights reserved.
//

#import "PlayBack.h"
#import "NSString+UPnPExtentions.h"

static PlayBack *_playback = nil;

@implementation PlayBack

@synthesize renderer;
@synthesize server;
@synthesize playlist;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        pos = 0;
        renderer = nil;
        server = nil;
    }
    
    return self;
}


+(PlayBack*)GetInstance{
	if(_playback == nil){
		_playback = [[PlayBack alloc] init];
	}
	return _playback;
}

-(void)setRenderer:(MediaRenderer1Device*)rend{
    
    MediaRenderer1Device* old = renderer;
    
    //Remove the Old Observer, if any
    if(old!=nil){
         if([[old avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == YES){
             [[old avTransportService] removeObserver:(BasicUPnPServiceObserver*)self]; 
         }
    }

    renderer = rend;

    //Add New Observer, if any
    if(renderer!=nil){
        if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO){
            [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self]; 
        }
    }
    
    
}


-(int)Play:(NSMutableArray*)playList position:(NSInteger)position{
    [self setPlaylist:playList];
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO){
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self]; 
    }
    
    //Play
    return [self Play:position];
}


-(int)Play:(NSInteger)position{
    //Do we have a Renderer & a playlist ?
    if(renderer == nil || playlist == nil){
        return -1;
    }
    
    if(position >= [playlist count]){
        position = 0; //Loop
    }
    
    pos = position;

    //Is it a Media1ServerItem ?
    if(![playlist[pos] isContainer]){
        MediaServer1ItemObject *item = playlist[pos];
        
        //A few things are missing here:
        // - Find the right URI based on MIME type, do this via: [item resources], also check render capabilities 
        // = The InstanceID is set to @"0", find the right one via: "ConnetionManager PrepareForConnection"
        
        
        //Find the right URI & Instance ID
        NSString *uri = [item uri];
        NSString *iid = @"0";
        
        
        //Play
        [[renderer avTransport] SetPlayModeWithInstanceID:iid NewPlayMode:@"NORMAL"];
        [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:@""];
        [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];        
        
    }
    
    return 0;
}

- (void)playWithUri:(NSString *)uri
{
    NSString *iid = @"0";
    NSString *metadata = [self getmetaDataWithurl:uri];
    metadata = [self XMLEscapeString:metadata];
    //Play
    [[renderer avTransport] SetPlayModeWithInstanceID:iid NewPlayMode:@"NORMAL"];
    [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:metadata];
    [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];
}

- (NSString *)getmetaDataWithurl:(NSString *)urlStr
{
    /**
     * AVTransportURIMetaData的FORMAT，按顺序的变量为:<br/>
     * %s id <br/>
     * %s title <br/>
     * %s artist <br/>
     * %d size <br/>
     * %s duration 00:00:00.000 <br/>
     * %s mimetype <br/>
     * %s url<br/>
     * %s kg:hash<br/>
     * %s kg:username 用户名<br/>
     * %s kg:phonename 机器名<br/>
     * %s kg:current <br />
     */
    
    NSString *idStr = @"";
    NSString *title = @"musicName";
    NSString *artist = @"singerName";
    NSInteger size = 123;
    NSString *duration = @"00:00:00";
    NSString *mimetype = @"";
    NSString *url = urlStr;
    NSString *hash = @"strFileHash";
    NSString *userName = @"userName";
    NSString *phoneName = @"iphone";
    NSString *current = @"00:00:00";
    
    phoneName = [UIDevice currentDevice].model;
    
    NSString *METADATA_FORMAT = @"<DIDL-Lite xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:av=\"urn:schemas-sony-com:av\" xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0/\" xmlns:sec=\"http://www.sec.co.kr/\" xmlns:pv=\"http://www.pv.com/pvns/\" xmlns:kg=\"http://www.kugou.com/\"><item id=\"%@\"parentID=\"-1\"restricted=\"1\"><dc:title><![CDATA[%@]]></dc:title><upnp:class>object.item.audioItem.musicTrack</upnp:class><upnp:artist><![CDATA[%@]]></upnp:artist><res size=\"%d\" duration=\"%@\" protocolInfo=\"http-get:*:%@:*\">%@</res><kg:hash>%@</kg:hash><kg:username><![CDATA[%@]]></kg:username><kg:phonename><![CDATA[%@]]></kg:phonename><kg:current>%@</kg:current></item></DIDL-Lite>";
    
    NSString *metadata = [NSString stringWithFormat:METADATA_FORMAT, idStr  , title, artist, size, duration, mimetype, url, hash, userName, phoneName, current];
    
    return metadata;
}

- (NSString*)XMLEscapeString:(NSString *)string
{
    if([string length] < 2){
        return string;
    }
    
    NSString *returnStr = nil;
    
    @autoreleasepool {
        //First remove all eventually escape codes because it makes it impossible to distinguish during unescape
        returnStr = [ string stringByReplacingOccurrencesOfString:@"&amp;" withString: @"."  ];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&quot;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&#x27;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&#x39;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&#x92;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&#x96;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&gt;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&lt;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&#10;" withString:@"."];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&#13;" withString:@"."];
        
        //Escape
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"&" withString: @"&amp;"  ];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"'" withString:@"&#x27;"];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"\n" withString:@"&#10;"];
        returnStr = [ returnStr stringByReplacingOccurrencesOfString:@"\r" withString:@"&#13;"];
        
        returnStr = [ [ NSString alloc ] initWithString:returnStr];
        
    }
    
    return returnStr;
}

//BasicUPnPServiceObserver
-(void)UPnPEvent:(BasicUPnPService*)sender events:(NSDictionary*)events{
    if(sender == [renderer avTransportService]){
        NSString *newState = events[@"TransportState"];
        NSLog(@"event:%@",events);
        if([newState isEqualToString:@"STOPPED"]){
            //Do your stuff, play next song etc...
            NSLog(@"Event: 'STOPPED', Play next track of playlist.");
           [self Play:pos+1]; //Next
        }
    }
}



- (void)getTransportInfo
{
    NSString *iid = @"0";
    NSMutableString *state = [NSMutableString new];
    NSMutableString *status = [NSMutableString new];
    NSMutableString *speed = [NSMutableString new];
    
    [[renderer avTransport] GetTransportInfoWithInstanceID:iid OutCurrentTransportState:state OutCurrentTransportStatus:status OutCurrentSpeed:speed];
    NSLog(@"state:%@, %@, %@", state, status, speed);
    
}

- (void)getPositionInfo
{
    NSString *iid = @"0";
    NSMutableString *track = [NSMutableString new];
    NSMutableString *duration = [NSMutableString new];
    NSMutableString *metaData = [NSMutableString new];
    NSMutableString *trackURI = [NSMutableString new];
    NSMutableString *relTime = [NSMutableString new];
    NSMutableString *absTime = [NSMutableString new];
    NSMutableString *relCount = [NSMutableString new];
    NSMutableString *absCount = [NSMutableString new];
    
    [[renderer avTransport]GetPositionInfoWithInstanceID:iid OutTrack:track OutTrackDuration:duration OutTrackMetaData:metaData OutTrackURI:trackURI OutRelTime:relTime OutAbsTime:absTime OutRelCount:relCount OutAbsCount:absCount];
    
    NSLog(@"track:%@, duration:%@, metaData:%@, trackURI:%@, relTime:%@, absTime:%@, relCount:%@, absCount:%@", track, duration, metaData, trackURI, relTime, absTime, relCount, absCount);

}

- (void)seek:(float)timeValue
{
    NSString *target = [NSString stringWithFormat:@"%02d:%02d:%02d",
     (int)(timeValue / 3600.0),
     (int)(fmod(timeValue, 3600.0) / 60.0),
     (int)fmod(timeValue, 60.0)];
    [[renderer avTransport]SeekWithInstanceID:@"0" Unit:@"REL_TIME" Target:target];
}

@end
