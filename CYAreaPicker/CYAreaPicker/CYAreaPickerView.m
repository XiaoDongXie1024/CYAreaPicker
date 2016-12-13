//
//  CYAreaPickerView.m
//  CYAreaPicker
//
//  Created by 李承阳 on 2016/12/13.
//  Copyright © 2016年 李承阳. All rights reserved.
//

#import "CYAreaPickerView.h"
#define displayScale    (nativeScale() / 2)
#define kViewW          self.frame.size.width
#define kViewH          self.frame.size.height
#define kSelectBtnTag   100
#define kCancelBtnTag   101
#define kBtnW           60  *displayScale
#define kToolH          40  *displayScale
#define kBgViewH        220 *displayScale

// 屏幕适配
CGFloat nativeScale(void);

CGFloat nativeScale(void) {
    static CGFloat scale = 0.0f;
    if (scale == 0.0f) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        scale = width / 375.0f;
    }
    return scale * 2;
}

@interface CYAreaPickerView () <UIPickerViewDelegate,UIPickerViewDataSource>
/******** 辅助视图 ***********/
@property (nonatomic, strong) UIView                *backgroundView;    // 背景View
@property (nonatomic, strong) UIView                *tool;              // 工具条(确认,取消)
@property (nonatomic, strong) UIPickerView          *pickView;
@property (nonatomic, copy  ) NSString              *title;             // pickerView 标题
@property (nonatomic, assign) PickerAnimationType   type;               // 选中动画类型

/******** 省市区相关数组 ******/
@property (nonatomic, copy  ) NSArray               *allArr;            // plist中最外层数组
@property (nonatomic, strong) NSMutableArray        *provinceAry;
@property (nonatomic, strong) NSMutableArray        *cityAry;
@property (nonatomic, strong) NSMutableArray        *disAry;
@property (nonatomic, strong) NSMutableArray        *areaCodeAry;         // 区号
@property (nonatomic, strong) NSMutableArray        *selectedArray;     // 选中数组

/******** 回调 ******/
@property (nonatomic, copy) AreaBlock addBlock;
@property (nonatomic, copy) AreaBlock autoBlock;

@end

@implementation CYAreaPickerView

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame selecteViewTitle:(NSString *)title withAnimationType:(PickerAnimationType)type {
    if (self == [super initWithFrame:frame]) {
        _title  = title;
        _type   = type;
        
        // 解析数据 plist
        [self parseData];
        // 初始化UI
        [self setupUIViews];
    }
    return self;
}

- (NSMutableArray *)selectedArray {
    if (!_selectedArray) {
        self.selectedArray = [@[] mutableCopy];
    }
    return _selectedArray;
}

#pragma mark - 解析数据
- (void)parseData {
    _provinceAry    = [NSMutableArray array];
    _cityAry        = [NSMutableArray array];
    _disAry         = [NSMutableArray array];
    _areaCodeAry    = [NSMutableArray array];
    
    _allArr = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Province&City&District" ofType:@"plist"]];
    if (_allArr.count == 0) {
        NSLog(@"无相关数据");
    }
    
    [_allArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.provinceAry addObject:obj[@"name"]];
    }];
    
    [[_allArr firstObject][@"cities"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dictCity, NSUInteger idx, BOOL * _Nonnull stop) {
         [self.cityAry addObject:dictCity[@"name"]];
    }];

    [[_allArr firstObject][@"cities"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dictCity, NSUInteger idx, BOOL * _Nonnull stop) {
        [dictCity[@"areas"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dictarea, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.disAry        addObject:dictarea[@"name"]];
            [self.areaCodeAry   addObject:dictarea[@"id"]];
        }];
    }];
}

#pragma mark - 设置UI
- (void)setupUIViews {
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }];
    
    // 背景View
    _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, kViewH, kViewW, kBgViewH)];
    [self addSubview:_backgroundView];
    
    // 工具栏
    _tool                   = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, kViewW, kToolH)];
    _tool.backgroundColor   = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]; // 白色
    [_backgroundView addSubview:_tool];
    
    // tool上的按钮
    if (_type == PickerAnimationTypeAlert) {
        [self addToolBtnsWithFrame:CGRectMake(0, 0, _tool.frame.size.width/2, kToolH) title:@"取消" tag:kCancelBtnTag];
        [self addToolBtnsWithFrame:CGRectMake(_tool.frame.size.width/2, 0, _tool.frame.size.width/2, kToolH) title:@"选择" tag:kSelectBtnTag];
    }else {
        [self addToolBtnsWithFrame:CGRectMake(0, 0, kBtnW, kToolH) title:@"取消" tag:kCancelBtnTag];
        [self addToolBtnsWithFrame:CGRectMake(kViewW-kBtnW, 0, kBtnW, kToolH) title:@"选择" tag:kSelectBtnTag];
        // 标题
        UILabel *titeLabel      = [[UILabel alloc]initWithFrame:CGRectMake(kBtnW, 0, kViewW - (kBtnW * 2), kToolH)];
        titeLabel.text          = _title;
        titeLabel.textColor     = [UIColor darkGrayColor];
        titeLabel.textAlignment = NSTextAlignmentCenter;
        titeLabel.font          = [UIFont systemFontOfSize:16*displayScale];
        [_tool addSubview:titeLabel];
    }
    
    // pickView选择器
    _pickView                   = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, kViewW, kBgViewH)];
    _pickView.delegate          = self;
    _pickView.dataSource        = self;
    _pickView.backgroundColor   = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1.0];
    
    [_backgroundView addSubview:_pickView];
    [_backgroundView sendSubviewToBack:_pickView];
    // 加这句可出现中间的两根选择状态横向，屏蔽可取消
    [_pickView selectRow:0 inComponent:0 animated:YES];
    
    // alert 布局
    if (_type == PickerAnimationTypeAlert) {
        _backgroundView.frame = CGRectMake(15*displayScale, (kViewH - kBgViewH)/2, kViewW-30*displayScale, kBgViewH);
        _backgroundView.layer.cornerRadius = 5.0f;
        _backgroundView.layer.masksToBounds = YES;
        
        _pickView.frame             = CGRectMake(0, 0, _backgroundView.frame.size.width, kBgViewH-kToolH);
        _pickView.backgroundColor   = [UIColor whiteColor];
        _tool.frame                 = CGRectMake(0, CGRectGetMaxY(_pickView.frame), _backgroundView.frame.size.width, kToolH);
    }
}

- (void)addToolBtnsWithFrame:(CGRect)rect title:(NSString *)btnTitle tag:(NSInteger)tag {
    UIButton *cancelBtn         = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.tag               = tag;
    cancelBtn.frame             = rect;
    cancelBtn.titleLabel.font   = [UIFont systemFontOfSize:16*displayScale];
    
    [cancelBtn setTitle:btnTitle forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [_tool addSubview:cancelBtn];
}

#pragma mark - Action
- (void)btnClick:(UIButton *)sender {
    // 选择第一行
    if (!self.province && !self.city && !self.area) {
        self.province   = [self.provinceAry firstObject];
        self.city       = [self.cityAry firstObject];
        self.area       = 0 == self.disAry.count        ? @"" : [self.disAry firstObject];
        self.idNum      = 0 == self.areaCodeAry.count   ? @"" : [self.areaCodeAry firstObject];
    }
    
    if (sender.tag == kSelectBtnTag) { // 选择
        if (_addBlock) {
            _addBlock(self.province, self.city, self.area, self.idNum);
        }
        
        if (self.autoBlock) {
            _autoBlock(self.province, self.city, self.area, self.idNum);
        }
    }
    
    [self hiddenMethod];
}

#pragma mark - 隐藏和显示相关
- (void)hiddenMethod {
    __weak typeof (self)     weakSelf   = self;
    __weak typeof (UIView *) weakBgView = _backgroundView;
    
    __block NSInteger BlockH            = kViewH;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect bgViewFrame = weakBgView.frame;
        bgViewFrame.origin.y    = BlockH;
        weakBgView.frame        = bgViewFrame;
        weakSelf.alpha          = 0.1;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

- (void)showMethod {
    __weak typeof (UIView *)weakBgView  = _backgroundView;
    __block NSInteger BlockH            = kViewH;
    __block NSInteger BlockBjH          = kBgViewH;
    if (self.type == PickerAnimationTypeAlert) {
        // alert动画
        _backgroundView.transform = CGAffineTransformMakeScale(0, 0);
        
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:kCancelBtnTag options:UIViewAnimationOptionOverrideInheritedOptions animations:^{
            weakBgView.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            
        }];
        
    }else {
        // action动画
        [UIView animateWithDuration:0.3 animations:^{
            CGRect bgViewFrame      = weakBgView.frame;
            bgViewFrame.origin.y    = BlockH - BlockBjH;
            weakBgView.frame        = bgViewFrame;
        }];
    }
}

- (void)showCityView:(AreaBlock)selectBlock {
    self.addBlock = selectBlock;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self showMethod];
}

- (void)showCityViewWithAutoSlected:(AreaBlock)selectBlock {
    self.autoBlock = selectBlock;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self showMethod];
}

#pragma mark - pickView的代理和数据源
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *lb         = [UILabel new];
    lb.numberOfLines    = 0;
    lb.textAlignment    = NSTextAlignmentCenter;
    lb.font             = [UIFont systemFontOfSize:16*displayScale];
    lb.text             = [self pickerView:pickerView titleForRow:row forComponent:component];
    return lb;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        return _provinceAry[row];
        
    }else if (component == 1) {
        return _cityAry[row];
        
    }else if (component == 2){
        return _disAry[row];
        
    }
    return nil;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return _provinceAry.count;
        
    }else if (component == 1) {
        return _cityAry.count;
        
    }else if (component == 2){
        return _disAry.count;
        
    }
    return 0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  3;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSArray *provinceArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Province&City&District" ofType:@"plist"]];
    
    if (0 == component) {
        self.selectedArray  = provinceArray[row][@"cities"];
        self.cityAry        = [NSMutableArray array];
        [self.selectedArray enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.cityAry addObject:dict[@"name"]];
        }];

        self.disAry         = [NSMutableArray array];
        self.areaCodeAry    = [NSMutableArray array];

        [[self.selectedArray firstObject][@"areas"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dictName, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.disAry        addObject:dictName[@"name"]];
            [self.areaCodeAry   addObject:dictName[@"id"]];
        }];
        
        [pickerView reloadComponent:1];
        [pickerView selectRow:0 inComponent:1 animated:YES];
        
        [pickerView reloadComponent:2];
        [pickerView selectRow:0 inComponent:2 animated:YES];
        NSLog(@"选择第1个");
    }else if (1 == component) {
        if (0 == self.selectedArray.count) {
            self.selectedArray = [provinceArray firstObject][@"cities"];
        }
        self.disAry         = [NSMutableArray array];
        self.areaCodeAry    = [NSMutableArray array];

        [[self.selectedArray objectAtIndex:row][@"areas"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.disAry addObject:dict[@"name"]];
            [self.areaCodeAry addObject:dict[@"id"]];
        }];
        
        [pickerView reloadComponent:2];
        [pickerView selectRow:0 inComponent:2 animated:YES];

    }else if (component==2){
        if (0 == self.selectedArray.count) {
            self.selectedArray = [provinceArray firstObject][@"cities"];
        }
    }
    
    NSInteger provinces = [_pickView selectedRowInComponent:0];
    NSInteger city      = [_pickView selectedRowInComponent:1];
    NSInteger area      = [_pickView selectedRowInComponent:2];
    
    self.province = self.provinceAry[provinces];
    if (self.cityAry.count!=0) {
        self.city = self.cityAry[city];
    }
    if (self.areaCodeAry.count!=0) {
        self.idNum = self.areaCodeAry[area];
    }
    if (self.disAry.count!=0) {
        self.area = 0 == self.disAry.count ? @"" : self.disAry[area];
    }
    
    if (self.autoBlock) {
        self.autoBlock(self.province, self.city, self.area, self.idNum);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.type == PickerAnimationTypeAction) {
        CGPoint point = [[touches anyObject] locationInView:self];
        if (!CGRectContainsPoint(_backgroundView.frame, point)) {
            [self hiddenMethod];
        }
    }
    
}

@end
