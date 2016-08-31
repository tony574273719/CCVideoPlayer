//
//  SCTools.h
//
//
//  Created by tech on 16/2/2.
//  Copyright © 2016年 tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCTools : NSObject

/**
 *  播放器转换为格式 00:00:00
 */
+ (NSString *)formatSecondsToString:(NSInteger)seconds;

/**
 *  切换横竖屏
 *
 *  @param orientation ：UIInterfaceOrientation
 */
+ (void)forceOrientation: (UIInterfaceOrientation)orientation;

/**
 *  判断是否竖屏
 *
 *  @return 布尔值
 */
+ (BOOL)isOrientationLandscape;



@end
