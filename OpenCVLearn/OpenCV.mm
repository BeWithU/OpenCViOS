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
+ (UIImage *)detectWithImage:(UIImage *)srcImage {
    if (!srcImage) {
        return nil;
    }
    Mat srcMat = [self cvMatFromImage:srcImage];
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
    //腐蚀边缘
    erode(cannyMat, cannyMat, Mat(), cv::Point(-1, -1));

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
    convexHull(poly, hull); //求出凸包
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
//        circle(srcMat, rectPoints[i], 10, Scalar(255,0,0), 5);
//        line(srcMat, rectPoints[i], rectPoints[(i+1)%4], Scalar(0,0,225), 2);

        CGPoint cgPoint = CGPointMake(rectPoints[i].x*1.0, rectPoints[i].y*1.0);
        cgPoints[i] = [NSValue valueWithCGPoint:cgPoint];
    }


    //四边形投影
    //找到原图和变换之后的四个点，顺序是左上，右上，左下，右下
    vector<cv::Point> srcPoints = [self sortedPoints:rectPoints];
    vector<cv::Point2f> srcPoints2f(srcPoints.size());
    for(int i=0;i<srcPoints.size();++i) {
        cv::Point p = srcPoints[i];
        Point2f p2f(p.x * 1.0, p.y * 1.0);
        srcPoints2f[i] = p2f;
    }
    //这里以图片的四个点为投影后的目标点 TODO 这种做法不是很准确，但是目前未找到更好的办法
    CGFloat scale = srcImage.scale;
    float w = srcImage.size.width * scale;
    float h = srcImage.size.height * scale;
    vector<cv::Point2f> dstPoints = {
        cv::Point2f(0, 0),
        cv::Point2f(w, 0),
        cv::Point2f(w, h),
        cv::Point2f(0, h)
    };
    Mat transMat = getPerspectiveTransform(srcPoints2f, dstPoints);
    warpPerspective(srcMat, srcMat, transMat, srcMat.size());

    UIImage *resImg = [self imageFromCVMat:srcMat];
    return resImg;
}

+ (NSArray<NSValue *> *)verticesOfImage:(UIImage *)srcImage {
    NSMutableArray<NSValue *> *cgPoints = [NSMutableArray arrayWithCapacity:4];
    if (!srcImage) {
        return [cgPoints copy];
    }

    Mat srcMat = [self cvMatFromImage:srcImage];
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
    //腐蚀边缘
    erode(cannyMat, cannyMat, Mat(), cv::Point(-1, -1));

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
    convexHull(poly, hull); //求出凸包
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

    rectPoints = [self sortedPoints:rectPoints];

    for(int i=0;i<rectPoints.size();++i) {
        CGPoint cgPoint = CGPointMake(rectPoints[i].x*1.0, rectPoints[i].y*1.0);
        cgPoints[i] = [NSValue valueWithCGPoint:cgPoint];
    }

    return [cgPoints copy];
}

+ (UIImage *)transformImage:(UIImage *)srcImage points:(NSArray<NSValue *> *)points {
    if (!srcImage) {
        return nil;
    }
    if (points.count != 4) {
        return nil;
    }
    Mat srcMat = [self cvMatFromImage:srcImage];
    if (srcMat.empty()) {
        return nil;
    }

    vector<cv::Point2f> srcPoints;
    for(NSValue *value : points) {
        CGPoint cgPoint = [value CGPointValue];
        srcPoints.push_back(cv::Point2f(cgPoint.x, cgPoint.y));
    }
    //这里以图片的四个点为投影后的目标点 TODO banzhiqiang 这种做法不是很准确，但是目前未找到更好的办法
    CGFloat scale = srcImage.scale;
    float w = srcImage.size.width * scale;
    float h = srcImage.size.height * scale;
    vector<cv::Point2f> dstPoints = {
        cv::Point2f(0, 0),
        cv::Point2f(w, 0),
        cv::Point2f(w, h),
        cv::Point2f(0, h)
    };
    Mat transMat = getPerspectiveTransform(srcPoints, dstPoints);
    warpPerspective(srcMat, srcMat, transMat, srcMat.size());

    UIImage *resImg = [self imageFromCVMat:srcMat];
    return resImg;
}

#pragma mark  - private
+ (cv::Mat)cvMatFromImage:(UIImage *)image {
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

+ (UIImage *)imageFromCVMat:(cv::Mat)cvMat {
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

/*
 返回顺时针排序好的点，以左上角顶点为起点
 判断每个顶点属于哪个位置，规则如下:
 1，先找出最上面和最下面的顶点，如果y值相等，那就取x值较小的一个，分别设为top，bottom
 2，两点连线，根据剩下两个点和当前两个点的相对位置，有几种情况：
    1）都在左侧，或者都在右侧，那top和bottom就分别是右上右下，或者左上左下
    2）分布在两侧，则top和bottom是对角线。两个点x值较小的则认为是左侧的点，否则即为右侧
 */
+ (vector<cv::Point>)sortedPoints:(vector<cv::Point>)points {
    if (points.size() != 4) {
        NSAssert(NO, @"点数量不对");
        return  points;
    }

    //先找最上面的点
    int pointIdx = 0;
    cv::Point top = points[0];
    for(int i=1;i<points.size();++i) {
        cv::Point p = points[i];
        if (p.y < top.y || (p.y == top.y && p.x < top.x)) {
            top = p;
            pointIdx = i;
        }
    }
    points.erase(points.begin() + pointIdx);

    //找最下面的点
    pointIdx = 0;
    cv::Point bottom = points[0];
    for(int i=1;i<points.size();++i) {
        cv::Point p = points[i];
        if (p.y > bottom.y || (p.y == bottom.y && p.x )) {
            bottom = p;
            pointIdx = i;
        }
    }
    points.erase(points.begin() + pointIdx);

    //找到最高点和最低点后，剩下的两个点按y值升序排序，方便后面判断
    if (points[0].y > points[1].y) {
        swap(points[0], points[1]);
    }

    //用求出来的两点构建二元一次方程，判断剩余两点和连线的位置关系
    int x1 = top.x;
    int y1 = top.y;
    int x2 = bottom.x;
    int y2 = bottom.y;
    int A = y2 - y1;
    int B = x1 - x2;
    int C = x2 * y1 - x1 * y2;
    vector<bool> isLeftOfLine(2);
    for(int i=0;i<2;++i) {
        cv::Point p = points[i];
        int Pos = A * p.x + B * p.y + C;
        isLeftOfLine[i] = Pos > 0;
    }

    vector<cv::Point> resPoints(4);
    if (isLeftOfLine[0] && isLeftOfLine[1]) {
        resPoints[0] = top;
        resPoints[1] = points[0];
        resPoints[2] = points[1];
        resPoints[3] = bottom;
    } else if (!isLeftOfLine[0] && !isLeftOfLine[1]) {
        resPoints[0] = points[0];
        resPoints[1] = top;
        resPoints[2] = bottom;
        resPoints[3] = points[1];
    } else {
        //两点分别在上下，让points[0]在线上面
        //然后根据B值来设置四个顶点
        if (isLeftOfLine[1]) {
            swap(points[0], points[1]);
        }
        if (B < 0) {
            resPoints[0] = top;
            resPoints[1] = points[0];
            resPoints[2] = bottom;
            resPoints[3] = points[1];
        } else {
            resPoints[0] = points[0];
            resPoints[1] = top;
            resPoints[2] = points[1];
            resPoints[3] = bottom;
        }
    }
    return resPoints;
}

@end
