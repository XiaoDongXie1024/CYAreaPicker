//
//  ViewController.m
//  CYAreaPicker
//
//  Created by 李承阳 on 2016/12/13.
//  Copyright © 2016年 李承阳. All rights reserved.
//

#import "ViewController.h"
#import "CYAreaPickerView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lb_address;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)selectedAddClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    // 如只需一种自行提取,只需导入头文件调用if其中一支分支
    if (sender.selected) {
        CYAreaPickerView *view =[[CYAreaPickerView alloc] initWithFrame:self.view.bounds selecteViewTitle:@"小东邪省市区选择" withAnimationType:PickerAnimationTypeAlert];
        [view showCityView:^(NSString *proviceStr, NSString *cityStr, NSString *disStr, NSString *idNum) {
            _lb_address.text = [NSString stringWithFormat:@"%@%@%@%@",proviceStr,cityStr,disStr,idNum];
        }];
    }else {
        CYAreaPickerView *view =[[CYAreaPickerView alloc] initWithFrame:self.view.bounds selecteViewTitle:@"小东邪省市区选择器" withAnimationType:PickerAnimationTypeAction];
        [view showCityViewWithAutoSlected:^(NSString *proviceStr, NSString *cityStr, NSString *disStr, NSString *idNum) {
            _lb_address.text = [NSString stringWithFormat:@"%@%@%@%@",proviceStr,cityStr,disStr,idNum];
            
        }];
    }
}

@end
