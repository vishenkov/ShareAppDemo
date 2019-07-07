//
//  ShareViewController.m
//  ShareDemoEx
//
//  Created by Kirill on 07/07/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "ShareViewController.h"
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText
#define VIDEO_IDENTIFIER_MPEG_4 @"public.mpeg-4"
#define VIDEO_IDENTIFIER_QUICK_TIME_MOVIE @"com.apple.quicktime-movie"

NSString *VideoIdentifier;

NSExtensionContext* extensionContext;

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

- (UIView*) shareView {
  NSURL *jsCodeLocation;
  
  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"share.ios" fallbackResource:nil];
  
  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"ShareDemoEx"
                                               initialProperties:nil
                                                   launchOptions:nil];
  rootView.backgroundColor = nil;
  return rootView;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
  [super viewDidLoad];
  extensionContext = self.extensionContext;
  UIView *rootView = [self shareView];
  if (rootView.backgroundColor == nil) {
    rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
  }
  
  self.view = rootView;
}


RCT_EXPORT_METHOD(close) {
  [extensionContext completeRequestReturningItems:nil
                                completionHandler:nil];
}



RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  [self extractDataFromContext: extensionContext withCallback:^(NSString* val, NSString* contentType, NSException* err) {
    if(err) {
      reject(@"error", err.description, nil);
    } else {
      resolve(@{
                @"type": contentType,
                @"value": val
                });
    }
  }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSString *value, NSString* contentType, NSException *exception))callback {
  @try {
    NSExtensionItem *item = [context.inputItems firstObject];
    NSArray *attachments = item.attachments;
    
    __block NSItemProvider *urlProvider = nil;
    __block NSItemProvider *imageProvider = nil;
    __block NSItemProvider *textProvider = nil;
    __block NSItemProvider *videoProvider = nil;
    
    [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
      if([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER]) {
        urlProvider = provider;
        *stop = YES;
      } else if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER]){
        textProvider = provider;
        *stop = YES;
      } else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
        imageProvider = provider;
        *stop = YES;
      } else if ([provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_MPEG_4]) {
        videoProvider = provider;
        VideoIdentifier = VIDEO_IDENTIFIER_MPEG_4;
        *stop = YES;
      } else if([provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]) {
        videoProvider = provider;
        VideoIdentifier = VIDEO_IDENTIFIER_QUICK_TIME_MOVIE;
        *stop = YES;
      }
    }];
    
    if(urlProvider) {
      [urlProvider loadItemForTypeIdentifier:URL_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
        NSURL *url = (NSURL *)item;
        
        if(callback) {
          callback([url absoluteString], @"text/plain", nil);
        }
      }];
    } else if (imageProvider) {
      [imageProvider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
        NSURL *url = (NSURL *)item;
        
        if(callback) {
          callback([url absoluteString], [[[url absoluteString] pathExtension] lowercaseString], nil);
        }
      }];
    } else if (videoProvider) {
        [videoProvider loadItemForTypeIdentifier:VideoIdentifier options:nil completionHandler:^(NSURL *path,NSError *error){
          if (path)
          {
            dispatch_async(dispatch_get_main_queue(), ^{
              NSLog(@"Path");
              if(callback) {
                
                AVAsset *asset = [AVAsset assetWithURL:path];
                AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
                CMTime time = CMTimeMake(1, 1);
                CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
                UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                
                NSString *base64Image = [UIImagePNGRepresentation(thumbnail) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

                callback([path absoluteString], [[[path absoluteString] pathExtension] lowercaseString], nil);
              }
            });
          }
        }];
    } else if (textProvider) {
      [textProvider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
        NSString *text = (NSString *)item;
        
        if(callback) {
          callback(text, @"text/plain", nil);
        }
      }];
      
    } else {
      if(callback) {
        callback(nil, nil, [NSException exceptionWithName:@"Error" reason:@"couldn't find provider" userInfo:nil]);
      }
    }
  }
  @catch (NSException *exception) {
    if(callback) {
      callback(nil, nil, exception);
    }
  }
}

@end
