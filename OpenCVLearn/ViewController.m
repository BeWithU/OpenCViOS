//
//  ViewController.m
//  OpenCVLearn
//
//  Created by BanZhiqiang on 2021/3/3.
//

#import "ViewController.h"
#import "OpenCV.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    UIImage *docImg = [UIImage imageNamed:@"tixing"];

    UIImageView *oriImageView = [[UIImageView alloc] initWithImage:docImg];
    [self.view addSubview:oriImageView];
    oriImageView.contentMode = UIViewContentModeScaleAspectFit;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSValue *> *points = [OpenCV verticesOfImage:docImg];
        UIImage *cannyImg = [OpenCV transformImage:docImg points:points];
        dispatch_async(dispatch_get_main_queue(), ^{
            [points enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj,
                                                 NSUInteger idx,
                                                 BOOL * _Nonnull stop) {
                CGPoint p = [obj CGPointValue];
                //返回的是PT，所以这里要根据尺寸和UIImageView的大小算一个比例
                CGFloat x = p.x / docImg.size.width * oriImageView.frame.size.width;
                CGFloat y = p.y / docImg.size.height * oriImageView.frame.size.height;
                UIView *pv = [[UIView alloc] initWithFrame:CGRectMake(x, y, 5, 5)];
                pv.backgroundColor = UIColor.redColor;
                pv.layer.cornerRadius = 2.5;
                [oriImageView addSubview:pv];
                //用数字标识顶点的顺序，确认排序和后面的映射是正确的
                //左上角应该是1，然后顺时针2，3，4
                UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(x+1, y+1, 22, 22)];
                lbl.textColor = UIColor.redColor;
                lbl.text = [NSString stringWithFormat:@"%zd", idx+1];
                [oriImageView addSubview:lbl];
            }];

            UIImageView *cannyImageView = [[UIImageView alloc] initWithImage:cannyImg];
            [self.view addSubview:cannyImageView];
            cannyImageView.contentMode = UIViewContentModeScaleAspectFit;
            CGRect frame = cannyImageView.frame;
            frame.origin.y = 500;
            cannyImageView.frame = frame;
        });
    });


}


@end
