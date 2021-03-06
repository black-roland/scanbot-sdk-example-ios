//
//  CreditCardRecognitionDemoViewController.m
//  ScanbotSDKDemo
//
//  Created by Max Tymchiy on 2/25/16.
//  Copyright (c) 2016 doo GmbH. All rights reserved.
//

#import "CreditCardRecognitionDemoViewController.h"
#import "ScanbotSDKInclude.h"

@interface CreditCardRecognitionDemoViewController () <SBSDKCameraSessionDelegate>

@property (nonatomic, strong) SBSDKCameraSession *cameraSession;
@property (nonatomic, strong) SBSDKCreditCardRecognizer *wrapper;
@property (nonatomic, strong) SBSDKPolygonLayer *polygonLayer;

@property (atomic, assign) BOOL recognitionEnabled;

@end



@implementation CreditCardRecognitionDemoViewController

#pragma mark - Lazy instantiation

- (SBSDKCreditCardRecognizer *)wrapper {
    if (!_wrapper) {
        _wrapper =  [[SBSDKCreditCardRecognizer alloc] init];
    }
    return _wrapper;
}

- (SBSDKCameraSession *)cameraSession {
    if (!_cameraSession) {
        _cameraSession = [[SBSDKCameraSession alloc] initForFeature:FeatureCreditCardRecognition];
        _cameraSession.videoDelegate = self;
    }
    return _cameraSession;
}

- (SBSDKPolygonLayer *)polygonLayer {
    if (!_polygonLayer) {
        UIColor *color = [UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:1.0f];
        _polygonLayer = [[SBSDKPolygonLayer alloc] initWithLineColor:color];
    }
    return _polygonLayer;
}

#pragma mark - Life cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.view.layer addSublayer:self.cameraSession.previewLayer];
    [self.view.layer addSublayer:self.polygonLayer];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.cameraSession.previewLayer.frame = self.view.bounds;
    self.polygonLayer.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.cameraSession startSession];
    self.recognitionEnabled = YES;
}

- (void)showResult:(SBSDKCreditCardRecognizerResult *)result {
    
    self.polygonLayer.path = [result.polygon bezierPathForPreviewLayer:self.cameraSession.previewLayer].CGPath;
    
    if (result.number.length == 0) {
        return;
    }
    
    self.polygonLayer.path = nil;
    
    self.recognitionEnabled = NO;
    
    NSMutableString *message = [[NSMutableString alloc] init];
    if (result.holder.length > 0) {
        [message appendString:[NSString stringWithFormat:@"Holder: %@\n", result.holder]];
    }
    
    if (result.number.length > 0) {
        [message appendString:[NSString stringWithFormat:@"Number: %@\n", result.number]];
    }
    
    if (result.expirationDate.length > 0) {
        [message appendString:[NSString stringWithFormat:@"Valid until: %@\n", result.expirationDate]];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Recognized Credit Card"
                                                                   message:[message copy]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                self.recognitionEnabled = YES;
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - SBSDKCameraSessionDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if (!self.recognitionEnabled) {
        return;
    }
    
    AVCaptureVideoOrientation orientation = self.cameraSession.videoOrientation;
    SBSDKCreditCardRecognizerResult *result = [self.wrapper recognizeCreditCardInfoOnBuffer:sampleBuffer
                                                                                orientation:orientation];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showResult:result];
    });
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    switch (orientation) {
            
        case UIInterfaceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            
        default:
            break;
    }
    self.cameraSession.videoOrientation = videoOrientation;
}

@end
