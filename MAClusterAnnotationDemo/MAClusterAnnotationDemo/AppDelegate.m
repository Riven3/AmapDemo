//
//  AppDelegate.m
//  iOS_3D_ClusterAnnotation
//
//  Created by yi chen on 14-7-8.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import "AppDelegate.h"
#import "APIKey.h"
#import <MAMapKit/MAMapKit.h>
#import "AnnotationClusterViewController.h"

@implementation AppDelegate

- (void)configureAPIKey
{
    [AMapServices sharedServices].apiKey = @"apikey";
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [self configureAPIKey];
    
    AnnotationClusterViewController *mainViewController = [[AnnotationClusterViewController alloc] init];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}
							

@end
