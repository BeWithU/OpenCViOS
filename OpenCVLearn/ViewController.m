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

    UIImage *docImg = [UIImage imageNamed:@"doc"];

    UIImageView *oriImageView = [[UIImageView alloc] initWithImage:docImg];
    [self.view addSubview:oriImageView];
    oriImageView.contentMode = UIViewContentModeScaleAspectFit;
    oriImageView.frame = CGRectMake(0, 0, 300, 400);

    __block NSArray<NSValue *> *points;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        points = [OpenCV verticesOfImage:docImg];
        dispatch_async(dispatch_get_main_queue(), ^{
            [points enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj,
                                                 NSUInteger idx,
                                                 BOOL * _Nonnull stop) {
                CGPoint p = [obj CGPointValue];
                //返回的是PT，所以这里要根据尺寸和UIImageView的大小算一个比例
                //300，400是我随便写的，开发中要根据真实view来算
                CGFloat x = p.x / docImg.size.width * 300;
                CGFloat y = p.y / docImg.size.height * 400;
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
        });
    });

    UIImage *cannyImg = [OpenCV detectWithImage:docImg];
    UIImageView *cannyImageView = [[UIImageView alloc] initWithImage:cannyImg];
    [self.view addSubview:cannyImageView];
    cannyImageView.contentMode = UIViewContentModeScaleAspectFit;
    cannyImageView.frame = CGRectMake(0, 420, 300, 400);
}


@end
