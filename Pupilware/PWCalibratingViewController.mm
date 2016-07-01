//
//  PWCalibratingViewController
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/24/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWCalibratingViewController.h"
#import <opencv2/videoio/cap_ios.h>

#import "MyCvVideoCamera.h"
#import "VideoAnalgesic.h"
#import "Libraries/ObjCAdapter.h"

#import "Pupilware-Swift.h"
//#import "constants.h"

@class DataModel;

/*---------------------------------------------------------------
 Pupilware Core Header
 ---------------------------------------------------------------*/
#import "PupilwareCore/preHeader.hpp"
#import "PupilwareCore/PupilwareController.hpp"
#import "PupilwareCore/Algorithm/IPupilAlgorithm.hpp"
#import "PupilwareCore/Algorithm/MDStarbustNeo.hpp"
#import "PupilwareCore/Algorithm/MDStarbust.hpp"
#import "PupilwareCore/ImageProcessing/SimpleImageSegmenter.hpp"
#import "PupilwareCore/IOS/IOSFaceRecognizer.h"

#import "PupilwareCore/PWVideoWriter.hpp"
#import "PupilwareCore/PWCSVExporter.hpp"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWCalibratingViewController ()

@property (strong, nonatomic) VideoAnalgesic *videoManager;         /* Manage iOS Video input      */
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;    /* recognize face from ICImage */
@property (strong,nonatomic) DataModel *model;                      /* Connect with Swift UI       */

@property NSUInteger currentFrameNumber;
@property Boolean    buffering;

- (IBAction)startBtnClicked:(id)sender;

@end


@implementation PWCalibratingViewController
{
    std::shared_ptr<pw::PupilwareController> pupilwareController;
    std::shared_ptr<pw::MDStarbustNeo> pwAlgo;

    pw::PWVideoWriter videoWriter;
    pw::PWCSVExporter csvExporter;
    
    std::vector<cv::Mat> videoFrameBuffer;
    std::vector<pw::PWFaceMeta> faceMetaBuffer;
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////    Instantiation    //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        _videoManager = [VideoAnalgesic captureManager];
        _videoManager.preset = AVCaptureSessionPresetMedium;
        [_videoManager setCameraPosition:AVCaptureDevicePositionFront];

    }
    return _videoManager;
    
}

-(DataModel*)model{
    if(!_model){
        _model = [DataModel sharedInstance];
    }
    return _model;
}


/////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////    UI View Events Handler    /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self initSystem];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startVideoManager];

}


-(void)viewWillDisappear:(BOOL)animated
{
    [self stopVideoManager];
    
    [super viewWillDisappear:animated];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)startBtnClicked:(id)sender {
    
    [self toggleBuffering];
    
    if(self.buffering)
    {
        [sender setTitle:@"Stop" forState: UIControlStateNormal];
    }
    else
    {
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////    Objective C Implementation     /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////



-(void)startVideoManager
{
    if(![self.videoManager isRunning])
    {
        [self.videoManager start];
    }
}


-(void)stopVideoManager
{
    if([self.videoManager isRunning])
    {
        [self.videoManager stop];
    }
}


-(void) toggleBuffering{
    
    if(self.buffering)
    {
        [self stopBuffering];
    }
    else
    {
        [self startBuffering];
    }

}


-(void) startBuffering
{
    if(!self.buffering)
    {
        self.currentFrameNumber = 0;
        self.buffering = true;
        
        [self clearBuffer];
        
    }
}


-(void) stopBuffering
{
    if(self.buffering)
    {
        self.buffering = false;
        
        [self calibrate];
        NSLog(@"Number of buffering frame %lu", videoFrameBuffer.size());
        
        [self clearBuffer];
        
    }
}


- (void) initSystem
{
    [self initVideoManager];
    [self initPupilwareCtrl];

}


-(void)initPupilwareCtrl
{
    
    self.currentFrameNumber = 0;
    
    pupilwareController = pw::PupilwareController::Create();
    pwAlgo = std::make_shared<pw::MDStarbustNeo>("StarbustNeo");
    
    pupilwareController->setPupilSegmentationAlgorihtm( pwAlgo );
    
    /*! 
     * If there is no a face segmentation algorithm,
     * we have to manually give Face Meta data to the system.
     */
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
//    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
//    
//    NSLog(@"%s", filePath);
//    pupilwareController->setFaceSegmentationAlgoirhtm(std::make_shared<pw::SimpleImageSegmenter>(filePath));
    

    // TODO: Load default setting
    
    /* Load Initial Setting to the Pupilware Controller*/
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    processor->eyeDistance_ud       = self.model.getDist;
//    processor->baselineStart_ud     = self.model.getBaseStart;
//    processor->baselineEnd_ud       = self.model.getBaseEnd;
//    processor->baseline             = self.model.getBaseline;
//    processor->cogHigh              = self.model.getCogHigh;
//    
//    // Following four parameters are optimal parameters resulting from the calibration process
//    
//    processor->windowSize_ud        = (int)[defaults integerForKey:kWindowSize];
//    processor->mbWindowSize_ud      = (int)[defaults integerForKey:kMbWindowSize];
//    processor->threshold_ud         = (int)[defaults integerForKey:kThreshold];
//    processor->markCost             = (int)[defaults integerForKey:kMarkCost];
//    
//    
//    NSLog(@"Default values in PWViewCOntroller");
//    NSLog(@"Eye Distance %f, window size %d, mbWindowsize %d, baseline start %d, basline end %d, threshold %d, mark cost %d, Baseline %f, coghigh %f", processor->eyeDistance_ud, processor->windowSize_ud, processor->mbWindowSize_ud, processor->baselineStart_ud, processor->baselineEnd_ud, processor->threshold_ud, processor->markCost, processor->baseline, processor->cogHigh);
    
}



- (void)initVideoManager
{
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    
    /* Use IOS Face Recoginizer */
    self.faceRecognizer = [[IOSFaceRecognizer alloc] initWithContext:self.videoManager.ciContext];
    
    
    __weak typeof(self) weakSelf = self;
    
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        
        auto returnImage = [weakSelf _segmentFaceAndBuffering:cameraImage
                                                  frameNumber:weakSelf.currentFrameNumber
                                                      context:weakSelf.videoManager.ciContext];
        
        weakSelf.currentFrameNumber += 1;
        
        return returnImage;
     
    }];

}


/* 
 * This function will be called in sided Video Manager callback.
 * It's used for process a camera image with Pupilware system.
 */
-(CIImage*)_segmentFaceAndBuffering:(CIImage*)cameraImage
                   frameNumber:(NSUInteger)frameNumber
                       context:(CIContext*)context
{
  
    if (!self.buffering) {
        return cameraImage;
    }
    
    cv::Mat cvFrame = [ObjCAdapter IGImage2Mat:cameraImage
                                   withContext:context];
    
    
    /* The source image is upside down, so It need to be rotated up. */
    [ObjCAdapter Rotate90:cvFrame withFlag:1];
    
    
    /* 
     * Since we use iOS Face Recongizer, we need to inject faceMeta manually.
     */
    auto faceMeta = [self.faceRecognizer recognize:cameraImage];
    faceMeta.setFrameNumber( (int) self.currentFrameNumber);
    

    videoFrameBuffer.push_back(cvFrame);
    faceMetaBuffer.push_back( faceMeta );
    
    
    return cameraImage;
}





-(void) calibrate
{
    // - Start calibration loop
    // TODO, Buffering the entire frame consume a lot of memory
    for (int l=0; l<10; ++l) {
    
        if(!pupilwareController->hasStarted())
        {
            /* init pupilware stage */
            pupilwareController->start();
            
            // TODO set init parameter here.
            
            /* process actual frame */
            /* !!! Make sure video and face meta are in the same direction */
            for (int i=0; i<videoFrameBuffer.size(); ++i) {
                pupilwareController->setFaceMeta(faceMetaBuffer[i]);
                pupilwareController->processFrame(videoFrameBuffer[i], i);
            }
            
            
            // - Get Pupil Signal
            
            /* TODO Warning Storage contain a lot of zeros,
               I will distort statistics calculation */
            auto rawPupilSize = pupilwareController->getRawPupilSignal();
            NSLog(@"[%d] Pupil Signal Size %lu", l, rawPupilSize.size());
            
            /* clear stage and do processing */
            pupilwareController->stop();
            
            // - Evaluate signal
            // - store result
        
        }
    
    }
    
    // - return best parameter set.

}

-(void)clearBuffer{
    videoFrameBuffer.clear();
    faceMetaBuffer.clear();
}

@end