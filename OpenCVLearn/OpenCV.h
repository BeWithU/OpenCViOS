//
//  OpenCV.h
//  OpenCVLearn
//
//  Created by BanZhiqiang on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCV : NSObject

+ (UIImage *)cannyWithImage:(UIImage *)srcImage;

@end

NS_ASSUME_NONNULL_END
