//
//  AnnotationClusterViewController.m
//  officialDemo2D
//
//  Created by yi chen on 14-5-15.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "AnnotationClusterViewController.h"
//#import "PoiDetailViewController.h"
#import "CoordinateQuadTree.h"
#import "ClusterAnnotation.h"
#import "ClusterAnnotationView.h"
#import <AMapSearchKit/AMapSearchObj.h>


#define kCalloutViewMargin -4

@interface AnnotationClusterViewController ()<UITableViewDelegate>

@property (nonatomic, strong) CoordinateQuadTree* coordinateQuadTree;

@end

@implementation AnnotationClusterViewController

#pragma mark - update Annotation

/* 更新annotation. */
- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations
{
    /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
     

    
    /* 保留仍然位于屏幕内的annotation. */
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    /* 需要添加的annotation. */
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    /* 删除位于屏幕外的annotation. */
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    /* 更新. */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    });
}

- (void)addAnnotationsToMapView:(MAMapView *)mapView
{
    NSLog(@"calculate annotations.");
    if (self.coordinateQuadTree.root == nil)
    {
        NSLog(@"tree is not ready.");
        return;
    }

    /* 根据当前zoomLevel和zoomScale 进行annotation聚合. */
    double zoomScale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;

    NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapRect:mapView.visibleMapRect
                                                                        withZoomScale:zoomScale
                                                                         andZoomLevel:mapView.zoomLevel];
    /* 更新annotation. */
    [self updateMapViewAnnotationsWithAnnotations:annotations];
}

/* annotation弹出的动画. */
- (void)addBounceAnnimationToView:(UIView *)view
{

    //3ClusterAnnotationView *dd = (ClusterAnnotationView *)view
    CGRect frame  = view.frame;
    view.frame = CGRectMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height, 0, 0);
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        view.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
//    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
//
//    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
//    bounceAnimation.duration = 0.6;
//
//    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
//    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++)
//    {
//        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
//    }
//    [bounceAnimation setTimingFunctions:timingFunctions.copy];
//
//    bounceAnimation.removedOnCompletion = NO;
//
//    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    /* mapView区域变化时重算annotation. */
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//    });
    [self addAnnotationsToMapView:self.mapView];

}

//- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
//    id<MAAnnotation> annotation = view.annotation;
//
//    if ([annotation isKindOfClass:[ClusterAnnotation class]])
//    {
//        ClusterAnnotation *clusterAnnotation = (ClusterAnnotation*)annotation;
//
//        PoiDetailViewController *detail = [[PoiDetailViewController alloc] init];
//        detail.poi = [clusterAnnotation.pois lastObject];
//
//         进入POI详情页面.
//        [self.navigationController pushViewController:detail animated:YES];
//    }
//}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[ClusterAnnotation class]])
    {
        /* dequeue重用annotationView. */
        static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";
        
        ClusterAnnotationView *annotationView = (ClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];
        
        if (!annotationView)
        {
            annotationView = [[ClusterAnnotationView alloc] initWithAnnotation:annotation
                                                               reuseIdentifier:AnnotatioViewReuseID];
        }
        
        /* 设置annotationView的属性. */
        annotationView.annotation = annotation;
        annotationView.count = [(ClusterAnnotation *)annotation count];
        
        /* 设置annotationView的callout属性和calloutView. */
        annotationView.canShowCallout = YES;
        if (annotationView.count == 1)
        {
            annotationView.rightCalloutAccessoryView    = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    /* 为新添的annotationView添加弹出动画. */
    for (UIView *view in views)
    {
        [self addBounceAnnimationToView:view];
    }
}

#pragma mark - SearchPOI

 //搜索POI.
- (void)searchPoiWithKeyword:(NSString *)keyword
{
    
//    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
//    request.searchType          = AMapSearchType_PlaceKeyword;
//    request.keywords            = keyword;
//    request.city                = @[@"010"];
//    request.requireExtension    = YES;

    AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
    request.keywords = keyword;
    request.city = @"北京";
    request.requireExtension = YES;
    
    [self.search AMapPOIKeywordsSearch:request];
}

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    if (response.pois.count == 0) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /* 建立四叉树. */
        [self.coordinateQuadTree buildTreeWithPOIs:response.pois];

        dispatch_async(dispatch_get_main_queue(), ^{
            /* 建树完成，计算当前mapView区域内需要显示的annotation. */
            NSLog(@"First time calculate annotations.");
            [self addAnnotationsToMapView:self.mapView];

        });
    });

    /* 如果只有一个结果，设置其为中心点. */
    if (response.pois.count == 1)
    {
        
        //self.mapView.centerCoordinate = response.pois.firstObject
        self.mapView.centerCoordinate = CLLocationCoordinate2DMake([response.pois[0] location].latitude, [response.pois[0] location].longitude);
    }
    /* 如果有多个结果, 设置地图使所有的annotation都可见. */
    else
    {
        [self.mapView showAnnotations:self.mapView.annotations animated:NO];
    }
    
}


#pragma mark - Life Cycle

- (id)init
{
    if (self = [super init])
    {
        self.coordinateQuadTree = [[CoordinateQuadTree alloc] init];
        
        [self setTitle:@"Cluster Annotations"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self searchPoiWithKeyword:@"学校|火锅|医院"];
}

//- (void)viewDidUnload
//{
//    [super viewDidUnload];
//    [self.coordinateQuadTree clean];
//}

- (void)dealloc
{
    [self.coordinateQuadTree clean];
}

@end
