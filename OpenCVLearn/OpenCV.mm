//
//  OpenCV.m
//  OpenCVLearn
//
//  Created by BanZhiqiang on 2021/3/3.
//

#import "OpenCV.h"
#import <opencv2/opencv.hpp>

#ifdef __cplusplus

using namespace cv;
using namespace std;

#endif

@implementation OpenCV

//https://qjx.app/posts/opencv-notes/ 矩形边缘检测算法
+ (UIImage *)cannyWithImage:(UIImage *)srcImage {
    Mat srcMat = [self cvMatFromUIImage:srcImage];
    if (srcMat.empty()) {
        return nil;
    }

    //降噪
    Mat blurMat;
    medianBlur(srcMat, blurMat, 9);
    //灰度化，边缘检测
    Mat grayMat;
    cvtColor(blurMat, grayMat, COLOR_BGR2GRAY);
    Mat cannyMat;
    Canny(grayMat, cannyMat, 100, 300);

    //膨胀边缘
    dilate(cannyMat, cannyMat, Mat(), cv::Point(-1, -1));

    //查找轮廓
    vector<vector<cv::Point>> contours;
    vector<cv::Vec4i> hireachy;
    findContours(cannyMat, contours, hireachy, RETR_LIST, CHAIN_APPROX_SIMPLE);

    //多边形拟合
    int contourIdx = 0;
    double maxArea = 0.0;
    vector<cv::Point> poly;
    for(int i=0;i<contours.size();++i) {
        vector<cv::Point> approx;
        approxPolyDP(contours[i], approx, arcLength(contours[i], true)*.02, true);
        if (approx.size() >= 4) {
            double area = fabs(contourArea(approx));
            if (area > maxArea) {
                maxArea = area;
                contourIdx = i;
                poly = approx;
            }
        }
    }

    //计算凸包，并从中选四个点围成的面积最大
    vector<cv::Point> hull;
    convexHull(poly, hull);
// 画凸包
//    for(int i=0;i<hull.size();++i) {
//        circle(srcMat, hull[i], 10, Scalar(0,255, 0), 4);
//        line(srcMat, hull[i], hull[(i+1)%4], Scalar(0,255, 0), 4);
//    }

    int hullCount = (int)hull.size();
    vector<cv::Point> rectPoints(4); //最终需要的四个点
    if (hullCount == 4) {
        rectPoints = hull;
    } else if (hullCount < 4) {
        RotatedRect rect = minAreaRect(hull);
        Point2f pts[4];
        rect.points(pts);
        for(int i=0;i<4;++i) {
            cv::Point p(pts[i].x, pts[i].y);
            rectPoints[i] = p;
        }
    } else {
        maxArea = 0.0;
        vector<cv::Point> res;
        for(int p0=0;p0<hullCount;++p0) {
            for(int p1=p0+1;p1<hullCount;++p1) {
                for(int p2=p1+1;p2<hullCount;++p2) {
                    for(int p3=p2+1;p3<hullCount;++p3) {
                        vector<cv::Point> cv = {hull[p0], hull[p1], hull[p2], hull[p3]};
                        double area = fabs(contourArea(cv));
                        if (area > maxArea) {
                            maxArea = area;
                            rectPoints = cv;
                        }
                    }
                }
            }
        }
    }

    //将cvPoint转为CGPoint形式的数组，要传出
    NSMutableArray *cgPoints = [NSMutableArray arrayWithCapacity:4];
    for(int i=0;i<rectPoints.size();++i) {
        //draw
        circle(srcMat, rectPoints[i], 10, Scalar(255,0,0), 2);
        line(srcMat, rectPoints[i], rectPoints[(i+1)%4], Scalar(0,0,225), 2);

        CGPoint cgPoint = CGPointMake(rectPoints[i].x*1.0, rectPoints[i].y*1.0);
        cgPoints[i] = [NSValue valueWithCGPoint:cgPoint];
    }



    //四边形投影
    //TODO 找到原图和变换之后的四个点，位置对应
    vector<cv::Point> srcPoints;
    vector<cv::Point> dstPoints;
    Mat transMat = getPerspectiveTransform(srcPoints, dstPoints);
    warpPerspective(srcMat, srcMat, transMat, srcMat.size());

    UIImage *resImg = [self UIImageFromCVMat:srcMat];
    return resImg;
}


#pragma mark  - private

//brg
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace =CGColorSpaceCreateDeviceRGB();

  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);

    Mat dst;
    Mat src;
    cvtColor(cvMat, dst, COLOR_RGBA2BGRA);
    cvtColor(dst, src, COLOR_BGRA2BGR);

  return src;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
//    mat 是brg 而 rgb
    Mat src;
    NSData *data=nil;
    CGBitmapInfo info =kCGImageAlphaNone|kCGBitmapByteOrderDefault;
    CGColorSpaceRef colorSpace;
    if (cvMat.depth()!=CV_8U) {
        Mat result;
        cvMat.convertTo(result, CV_8U,255.0);
        cvMat = result;
    }
  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
      data= [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  } else if(cvMat.elemSize() == 3){
      cvtColor(cvMat, src, COLOR_BGR2RGB);
       data= [NSData dataWithBytes:src.data length:src.elemSize()*src.total()];
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }else if(cvMat.elemSize() == 4){
      colorSpace = CGColorSpaceCreateDeviceRGB();
      cvtColor(cvMat, src, COLOR_BGRA2RGBA);
      data= [NSData dataWithBytes:src.data length:src.elemSize()*src.total()];
      info =kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
  }else{
      NSLog(@"[error:] 错误的颜色通道");
      return nil;
  }
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                     kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentAbsoluteColorimetric                   //intent
                                     );
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  return finalImage;
 }

@end
