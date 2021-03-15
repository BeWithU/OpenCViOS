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

//检测图片，定位到四个顶点，然后做投影和矫正变换，返回变换后的图片
+ (UIImage *)detectWithImage:(UIImage *)srcImage;

/// 计算给定图片中最大的突四边形，返回四边形的四个顶点，顺序为左上，右上，右下，左下
/// @param srcImage 要计算的图片
+ (NSArray<NSValue *> *)verticesOfImage:(UIImage *)srcImage;

/// 将给定的图片中的四边形做投影变换，转换为原图片尺寸大小的矩形
/// @param srcImage 要计算的图片
/// @param points 图片中凸四边形的四个顶点，按顺时针顺序给出
+ (UIImage *)transformImage:(UIImage *)srcImage points:(NSArray<NSValue *> *)points;

@end

NS_ASSUME_NONNULL_END
