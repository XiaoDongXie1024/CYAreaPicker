//
//  CYAreaPickerView.h
//  CYAreaPicker
//
//  Created by 李承阳 on 2016/12/13.
//  Copyright © 2016年 李承阳. All rights reserved.
//

/*
 
 PickerAnimationType ： 弹框动画类型
 两个选择方式： 
 showCityView                   点击选择按钮选择
 showCityViewWithAutoSlected    滚动自动选择
 
 */

#import <UIKit/UIKit.h>

/*  地址选择器弹框动画  */
typedef NS_ENUM(NSInteger, PickerAnimationType) {
    PickerAnimationTypeAction,         // action风格
    PickerAnimationTypeAlert           // alert风格
};

/*  回调  */
typedef void(^AreaBlock)(NSString *proviceStr, NSString *cityStr, NSString * disStr, NSString *idNum);

@interface CYAreaPickerView : UIView

@property (nonatomic, copy) NSString *province;     ///< 省
@property (nonatomic, copy) NSString *city;         ///< 市
@property (nonatomic, copy) NSString *area;         ///< 区
@property (nonatomic, copy) NSString *idNum;        ///< 区号

- (void)showCityView:(AreaBlock)selectBlock;                    ///< 点击按钮选择地址
- (void)showCityViewWithAutoSlected:(AreaBlock)selectBlock;     ///< 滚动自动选择地址

- (instancetype)initWithFrame:(CGRect)frame selecteViewTitle:(NSString *)title withAnimationType:(PickerAnimationType)type;

@end
