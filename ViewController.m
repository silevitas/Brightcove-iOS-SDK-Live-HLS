//
//  ViewController.m
//  Testing App
//
//  Created by Simon @ Brightcove on 27/05/2015.
//  Copyright (c) 2015 Brightcove. All rights reserved.
//

#import "ViewController.h"

// Read API Token with URL Access
static NSString * const kViewControllerCatalogToken = @"TOKEN";

// Live video
static NSString * const kViewControllerVideoID = @"VIDEO_ID";

// VOD video
//static NSString * const kViewControllerVideoID = @"VIDEO_ID";

// Account ID for analytics
static NSString * const kPublisherID = @"ACCOUNT_ID";


@interface ViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@end

@implementation ViewController

#pragma mark Setup Methods

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    _playbackController = [manager createPlaybackControllerWithViewStrategy:[manager defaultControlsViewStrategy]];
    
    _playbackController.analytics.account = kPublisherID;
    
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;
    
    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.playbackController.view.frame = self.videoContainer.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer addSubview:self.playbackController.view];
    
    [self requestContentFromCatalog];
}


- (void)requestContentFromCatalog
{
    // Load Video
    [self.catalogService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        // If a video object is returned
        if (video)
        {
            // Get the HLSURL from the JSON response
            NSString *hlsUrlStr = [[video properties] objectForKey:@"HLSURL"];
            // Get the FLVFullLength from the JSON response
            NSDictionary *flvFullLength = [[video properties] objectForKey:@"FLVFullLength"];
            // Get the videoContainer from the JSON response
            NSString *videoContainer = flvFullLength[@"videoContainer"];
            NSURL *hlsUrl = NULL;
            
            // If the container is M2TS (HLS) - only applies to live/remote assets
            if ([videoContainer isEqualToString:@"M2TS"]) {
                hlsUrlStr = flvFullLength[@"url"];
                hlsUrl = [NSURL URLWithString:hlsUrlStr];
                
                // Create a "fixedVideo" object with a valid HLS URL
                BCOVVideo *fixedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {
                    BCOVSource *hlsSource = [[BCOVSource alloc]
                                             initWithURL:hlsUrl
                                             deliveryMethod:kBCOVSourceDeliveryHLS
                                             properties:nil];
                    mutableVideo.sources = [NSArray arrayWithObject:hlsSource];
                }];
                
                // Load the "fixed" video
                [self.playbackController setVideos: @[fixedVideo]];
            }
            // If the container is not M2TS, function as normal (loads HLS for VOD, with fallback to MP4 as needed)
            else
            {
               [self.playbackController setVideos: @[video]];
            }
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video: `%@`", error);
        }
    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end