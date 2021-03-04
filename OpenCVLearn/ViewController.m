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

    UIImage *docImg = [UIImage imageNamed:@"doc1"];

    UIImageView *oriImageView = [[UIImageView alloc] initWithImage:docImg];
    [self.view addSubview:oriImageView];
    oriImageView.contentMode = UIViewContentModeScaleAspectFit;
    oriImageView.frame = CGRectMake(0, 0, 300, 400);

    UIImage *cannyImg = [OpenCV cannyWithImage:docImg];
    UIImageView *cannyImageView = [[UIImageView alloc] initWithImage:cannyImg];
    [self.view addSubview:cannyImageView];
    cannyImageView.contentMode = UIViewContentModeScaleAspectFit;
    cannyImageView.frame = CGRectMake(0, 420, 300, 400);
}


@end
