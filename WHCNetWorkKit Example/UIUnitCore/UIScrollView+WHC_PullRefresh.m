//
//  UIScrollView+WHC_PullRefresh.m
//  PhoneBookBag
//
//  Created by 吴海超 on 14/8/20.
//  Copyright (c) 2014年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOS大神qq群:460122071
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "UIScrollView+WHC_PullRefresh.h"
#import "UIView+WHC_ViewProperty.h"
#import <objc/runtime.h>

#define kWHC_Margin              (5.0)                //上下边距
#define kWHC_WaterDropSize       (30.0)               //水滴尺寸
#define kWHC_PullHeight          (80.0)               //下拉高度
#define kWHC_BreakRadius         (5.0)                //断开半径
#define kWHC_OffsetAnimationTime (0.2)                //偏移动画时间
#define kWHC_FontSize            (14.0)               //字体大小
#define kWHC_ContentOffset       (@"contentOffset")   //监听路径
#define kWHC_ContentInset        (@"contentInset")
#define kWHC_ContentSize         (@"contentSize")
#define kWHC_RefreshFinishTxt    (@"刷新完成")
#define kWHC_LoadMoreTxt         (@"加载更多")
#define kWHC_LoadingTxt          (@"正在加载")
#define kWHC_RefreshingHeight    (kWHC_WaterDropSize + 2.0 * kWHC_Margin)    //刷新视图的高度

//加载器渐变开始颜色
#define KWHC_StartColor      ([UIColor colorWithRed:255.0 / 255.0\
                                              green:255.0 / 255.0\
                                               blue:255.0 / 255.0\
                                               alpha:1.0].CGColor)
//加载器渐变结束颜色
#define KWHC_EndColor        ([UIColor colorWithRed:38.0  / 255.0\
                                              green:110.0 / 255.0\
                                              blue:239.0  / 255.0\
                                              alpha:1.0].CGColor)
//水滴颜色
#define kWHC_WaterBackColor  (([UIColor colorWithRed:38.0  / 255.0\
                                                green:110.0 / 255.0\
                                                blue:239.0  / 255.0\
                                                alpha:1.0].CGColor))

//刷新头部提示文字颜色
#define kWHC_HeaderLableTxtColor  ([UIColor blackColor])

//刷新头部百分比标签文字颜色
#define kWHC_HeaderPercentLabTxtColor ([UIColor whiteColor])

//刷新底部提示文字颜色
#define kWHC_FooterLableTxtColor  ([UIColor blackColor])

//刷新底部百分比标签文字颜色
#define kWHC_FooterPercentLabTxtColor ([UIColor grayColor])
typedef enum{
    NoneRefresh = 3,        //没有刷新
    WillRefresh,            //将要刷新
    DoingRefresh,           //正在刷新
    DidRefreshed            //完成刷新
}WHCRefreshStatus;

#pragma mark - 上拉刷新视图 -

@interface WHC_PullFooterView : UIView
@property (nonatomic , assign)BOOL                    canRequest;                 //是否能够请求
@property (nonatomic , assign)BOOL                    isSetOffset;                //是否已经设置了偏移
@property (nonatomic , assign)WHCRefreshStatus        currentRefreshState;        //当前刷新状态
@property (nonatomic , assign)UIEdgeInsets            superOriginalContentInset;  //super原始偏移值
- (void)setProgressValue:(CGFloat)progressValue;
- (void)updatePostion;
@end

@interface WHC_PullFooterView (){
    UIView             *           _backView;                    //背景视图
    UILabel            *           _loadLab;                     //加载标签
    UILabel            *           _percentLab;                  //百分比标签
    UIImageView        *           _progressBarImageView;        //进度条
    CAGradientLayer    *           _gradientProgressBar;         //渐变进度条层
    CAShapeLayer       *           _progressBar;                 //进度条层
    id                             _delegate;                    //刷新代理
    UIScrollView       *           _superView;                   //父视图
    
    BOOL                           _isDidSendRequest;            //是否已经发生请求
}
@end

@implementation WHC_PullFooterView

- (instancetype)initWithFrame:(CGRect)frame  delegate:(id<WHC_PullRefreshDelegate>)delegate{
    self = [super initWithFrame:frame];
    if(self){
        _delegate = delegate;
        [self initData];
    }
    return self;
}

- (void)setDelegate:(id<WHC_PullRefreshDelegate>)delegate{
    _delegate = delegate;
}

- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    [_superView cancelledObsever];
    if(newSuperview){
        [_superView addObserver];
    }
}

+ (CGFloat)stringWidth:(NSString *)content constrainedHeight:(CGFloat)height fontSize:(CGFloat)fontSize{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    CGSize contentSize = [content sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(MAXFLOAT , height)];
#pragma clang diagnostic pop
    return contentSize.width;
}

- (void)initData{
    _canRequest = YES;
    _currentRefreshState = NoneRefresh;
    CGFloat   loadingLabWidth = [WHC_PullFooterView stringWidth:kWHC_LoadMoreTxt constrainedHeight:self.height fontSize:17.0];
    CGFloat   sumWidth = loadingLabWidth + kWHC_WaterDropSize +kWHC_Margin;
    _backView = [[UIView alloc]initWithFrame:CGRectMake((self.width - sumWidth) / 2.0, kWHC_Margin, kWHC_WaterDropSize, kWHC_WaterDropSize)];
    _loadLab = [[UILabel alloc]initWithFrame:CGRectMake(_backView.maxX + kWHC_Margin, 0, loadingLabWidth, self.height)];
    _loadLab.text = kWHC_LoadMoreTxt;
    _loadLab.textColor = kWHC_FooterLableTxtColor;
    _loadLab.font = [UIFont systemFontOfSize:kWHC_FontSize];
    [self addSubview:_loadLab];
    [self addSubview:_backView];
    
    _percentLab = [[UILabel alloc]initWithFrame:_backView.bounds];
    _percentLab.textAlignment = NSTextAlignmentCenter;
    _percentLab.font = [UIFont systemFontOfSize:10.0];
    _percentLab.textColor = kWHC_FooterPercentLabTxtColor;
    _percentLab.text = @"0";
    [_backView addSubview:_percentLab];
    
    _gradientProgressBar = [CAGradientLayer layer];
    _gradientProgressBar.frame = _backView.bounds;
    _gradientProgressBar.backgroundColor = [UIColor clearColor].CGColor;
    _gradientProgressBar.colors = @[(id)KWHC_StartColor , (id)KWHC_EndColor];
    _gradientProgressBar.locations = @[@(0.0) , @(1.0)];
    
    _progressBar = [CAShapeLayer layer];
    _progressBar.frame = _backView.bounds;
    _progressBar.backgroundColor = [UIColor clearColor].CGColor;
    _progressBar.fillColor = [UIColor clearColor].CGColor;
    _progressBar.strokeColor = [UIColor blueColor].CGColor;
    _progressBar.lineWidth = 5.0;
    _gradientProgressBar.mask = _progressBar;
    
    [_backView.layer addSublayer:_gradientProgressBar];
    
    _progressBarImageView = [[UIImageView alloc]initWithFrame:_backView.frame];
}

- (void)updateProgressBarWithValue:(CGFloat)value{
    value = value < 0 ? 0 : value;
    CGFloat  endAngle = value / kWHC_RefreshingHeight;
    if(endAngle > 1.0){
        endAngle = 1.0;
    }
    CGMutablePathRef  path = CGPathCreateMutable();
    CGPathAddArc(path, NULL,
                 _progressBar.frame.size.width / 2.0, _progressBar.frame.size.height / 2.0, kWHC_WaterDropSize / 2.0 - 3.0, -M_PI / 2.0, endAngle * M_PI * 2.0 - M_PI / 2.0, NO);
    _progressBar.path = path;
    _percentLab.text = [NSString stringWithFormat:@"%.0f",endAngle * 100.0];
    CGPathRelease(path);
}

- (UIImage *)getProgressBarImage{
    UIGraphicsBeginImageContext(_gradientProgressBar.frame.size);
    CGContextRef  context  = UIGraphicsGetCurrentContext();
    [_gradientProgressBar renderInContext:context];
    return UIGraphicsGetImageFromCurrentImageContext();
}

- (void)setImageProgressBarAnimation{
    CABasicAnimation  * ba = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    ba.fromValue = @(0);
    ba.toValue = @(M_PI * 2.0);
    ba.duration = 1.0;
    ba.cumulative = YES;
    ba.repeatCount = INFINITY;
    [_progressBarImageView.layer addAnimation:ba forKey:@""];
}
- (void)setSuperView:(UIScrollView *)superView{
    _superView = superView;
}

- (void)setUpRefreshDidFinished{
    _canRequest = NO;
    _isDidSendRequest = NO;
    _currentRefreshState = DidRefreshed;
    if([self.subviews containsObject:_progressBarImageView]){
        [_progressBarImageView.layer removeAllAnimations];
        [_progressBarImageView removeFromSuperview];
    }
    if(![self.subviews containsObject:_backView]){
        [self addSubview:_backView];
    }
    self.hidden = YES;
}

- (void)resetUpRefreshState{
    _isSetOffset = NO;
    _canRequest = YES;
    _currentRefreshState = NoneRefresh;
    _loadLab.text = kWHC_LoadMoreTxt;
}

- (void)sendUpRefreshCommand{
    if(!_isDidSendRequest){
        _isDidSendRequest = YES;
        if(_delegate && [_delegate respondsToSelector:@selector(WHCUpPullRequest)]){
            [_delegate WHCUpPullRequest];
        }
    }
}

- (void)updatePostion{
    CGFloat  superHeight = _superView.height - _superView.contentInset.top - _superView.contentInset.bottom;
    self.y = MAX(superHeight, _superView.contentSize.height);
}

- (void)setProgressValue:(CGFloat)progressValue{
    if(_canRequest){
        if(_currentRefreshState == DoingRefresh || _currentRefreshState == DidRefreshed){
            return;
        }
        _superOriginalContentInset = _superView.contentInset;
        CGFloat  actualHeight = _superView.height - _superOriginalContentInset.bottom - _superOriginalContentInset.top;
        CGFloat  beyondHeight = _superView.contentSize.height - actualHeight;
        CGFloat  showFooterOffset = beyondHeight - _superOriginalContentInset.top;
        if(beyondHeight < 0){
            showFooterOffset = -_superOriginalContentInset.top;
        }
        CGFloat  actualOffset = progressValue - showFooterOffset;
        if(actualOffset > kWHC_RefreshingHeight && _currentRefreshState == WillRefresh && _superView.isDragging){
            _currentRefreshState = DoingRefresh;
        }else if(_superView.isDragging){
            if(self.hidden){
                self.hidden = NO;
            }
            _currentRefreshState = WillRefresh;
        }
        switch (_currentRefreshState) {
            case NoneRefresh:
            case WillRefresh:
                if(![self.subviews containsObject:_backView]){
                    [self addSubview:_backView];
                }
                [self updateProgressBarWithValue:actualOffset];
                break;
            case DoingRefresh:
                if([self.subviews containsObject:_backView]){
                    [_backView removeFromSuperview];
                    [self updateProgressBarWithValue:kWHC_RefreshingHeight];
                }
                if(![self.subviews containsObject:_progressBarImageView]){
                    [self addSubview:_progressBarImageView];
                    if(_progressBarImageView.image == nil){
                        _progressBarImageView.image = [self getProgressBarImage];
                    }
                    [self setImageProgressBarAnimation];
                    _loadLab.text = kWHC_LoadingTxt;
                }
                break;
            default:
                break;
        }
        if(_superView.isDragging && _currentRefreshState == DoingRefresh){
            [self sendUpRefreshCommand];
        }
    }else{
        if(self.hidden == NO){
            self.hidden = YES;
        }
    }
}

@end

#pragma mark - 下拉刷新视图 -

@interface WHC_PullHeaderView : UIView
@property (nonatomic , assign)CGFloat                 defualtOffset;              //默认偏移
@property (nonatomic , assign)WHCRefreshStatus        currentRefreshState;        //当前刷新状态
@property (nonatomic , assign)BOOL                    isCloseHeader;              //是否关闭头
@property (nonatomic , assign)BOOL                    isRequestEndNOInit;         //请求结束但没有初始化
@property (nonatomic , assign)BOOL                    canRequest;                 //可以请求
@property (nonatomic , assign)UIEdgeInsets            superOriginalContentInset;  //super原始偏移值
- (void)setProgressValue:(CGFloat)progressValue;
- (void)setProgressBarEndDragPostion;
@end

@interface WHC_PullHeaderView (){
    UIView             *   _backView;                    //背景视图
    CAGradientLayer    *   _gradientProgressBar;         //渐变进度条层
    CAShapeLayer       *   _progressBar;                 //进度条层
    UIImageView        *   _progressBarImageView;        //图片进度条
    UILabel            *   _percentLab;                  //百分比
    UILabel            *   _refreshAlertLab;             //刷新提示
    UIScrollView       *   _superView;                   //父视图
    id                     _delegate;                    //刷新代理
    BOOL                   _isBreak;                     //水滴是否断开
    BOOL                   _isSetDefualtOffset;          //是否已经设置默认偏移
    BOOL                   _isDidRefresh;                //已经刷新过了
    BOOL                   _isDidSendRequest;            //是否已经发生请求
    CGFloat                _currentRadius;               //当前水滴半径
}
@end

@implementation WHC_PullHeaderView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<WHC_PullRefreshDelegate>)delegate{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        _delegate = delegate;
        [self initData];
    }
    return self;
}

- (void)setDelegate:(id<WHC_PullRefreshDelegate>)delegate{
    _delegate = delegate;
}

- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    [_superView cancelledObsever];
    if(newSuperview){
        [_superView addObserver];
    }
}

- (void)setSuperView:(UIScrollView *)superView{
    _superView = superView;
}


- (UIView *)createView{
    UIView * view = [UIView new];
    view.size = CGSizeMake(kWHC_WaterDropSize, kWHC_WaterDropSize);
    view.center = CGPointMake(self.centerX, self.height - kWHC_WaterDropSize / 2.0);
    view.backgroundColor = [UIColor colorWithCGColor:kWHC_WaterBackColor];
    view.layer.cornerRadius = kWHC_WaterDropSize / 2.0;
    view.clipsToBounds = YES;
    return view;
}

- (void)initData{
    _canRequest = YES;
    _defualtOffset = 0;
    _isSetDefualtOffset = NO;
    _currentRadius = kWHC_WaterDropSize / 2.0;
    _backView = [self createView];
    [self addSubview:_backView];
    
    _gradientProgressBar = [CAGradientLayer layer];
    _gradientProgressBar.frame = _backView.bounds;
    _gradientProgressBar.backgroundColor = [UIColor clearColor].CGColor;
    _gradientProgressBar.colors = @[(id)KWHC_StartColor , (id)KWHC_EndColor];
    _gradientProgressBar.locations = @[@(0.0) , @(1.0)];
    
    _progressBar = [CAShapeLayer layer];
    _progressBar.frame = _backView.bounds;
    _progressBar.backgroundColor = [UIColor clearColor].CGColor;
    _progressBar.fillColor = [UIColor clearColor].CGColor;
    _progressBar.strokeColor = [UIColor blueColor].CGColor;
    _progressBar.lineWidth = 5.0;
    _gradientProgressBar.mask = _progressBar;
    [_backView.layer addSublayer:_gradientProgressBar];
    
    _percentLab = [[UILabel alloc]initWithFrame:_backView.bounds];
    _percentLab.textAlignment = NSTextAlignmentCenter;
    _percentLab.textColor = kWHC_HeaderPercentLabTxtColor;
    _percentLab.font = [UIFont systemFontOfSize:10.0];
    [_backView addSubview:_percentLab];
    
    _progressBarImageView = [[UIImageView alloc]initWithFrame:_backView.frame];
    _progressBarImageView.centerY = _progressBarImageView.width / 2.0;
    
    _refreshAlertLab = [[UILabel alloc]initWithFrame:self.bounds];
    _refreshAlertLab.height = kWHC_WaterDropSize;
    _refreshAlertLab.center = _backView.center;
    _refreshAlertLab.textColor = kWHC_HeaderLableTxtColor;
    _refreshAlertLab.font = [UIFont systemFontOfSize:kWHC_FontSize];
    _refreshAlertLab.textAlignment = NSTextAlignmentCenter;
    _refreshAlertLab.text = kWHC_RefreshFinishTxt;
}

- (void)updateProgressBarWithValue:(CGFloat)value{
    CGFloat  endAngle = value / kWHC_PullHeight;
    if(endAngle > 1.0){
        endAngle = 1.0;
    }
    CGMutablePathRef  path = CGPathCreateMutable();
    CGPathAddArc(path, NULL,
                 _progressBar.frame.size.width / 2.0, _progressBar.frame.size.height / 2.0, kWHC_WaterDropSize / 2.0 - 2.5, M_PI / 2.0, endAngle * M_PI * 2.0 + M_PI / 2.0, NO);
    _progressBar.path = path;
    CGPathRelease(path);
    _percentLab.text = [NSString stringWithFormat:@"%.0f",endAngle * 100.0];
}

- (UIImage *)getProgressBarImage{
    UIGraphicsBeginImageContext(_gradientProgressBar.frame.size);
    CGContextRef  context  = UIGraphicsGetCurrentContext();
    [_gradientProgressBar renderInContext:context];
    return UIGraphicsGetImageFromCurrentImageContext();
}

- (void)setImageProgressBarAnimation{
    if(_progressBarImageView.image == nil){
        _progressBarImageView.image = [self getProgressBarImage];
    }
    _progressBarImageView.centerY = _progressBarImageView.height / 2.0;
    if(![self.subviews containsObject:_progressBarImageView]){
        [self addSubview:_progressBarImageView];
    }
    CABasicAnimation  * ba = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    ba.fromValue = @(0);
    ba.toValue = @(M_PI * 2.0);
    ba.duration = 1.0;
    ba.cumulative = YES;
    ba.repeatCount = INFINITY;
    [_progressBarImageView.layer addAnimation:ba forKey:@""];
}

- (void)setProgressValue:(CGFloat)progressValue{
    if(_canRequest){
        if(_currentRefreshState != DoingRefresh && _currentRefreshState != DidRefreshed){
            _superOriginalContentInset = _superView.contentInset;
        }
        CGFloat   actualOffset = progressValue + _superOriginalContentInset.top;
        CGFloat   absActualOffset = -actualOffset;
        if(!_superView.isDragging){
            if(_currentRefreshState == WillRefresh || _currentRefreshState == NoneRefresh){
                if(absActualOffset > kWHC_RefreshingHeight && absActualOffset <= kWHC_PullHeight){
                    _backView.centerY = self.height - (absActualOffset - kWHC_RefreshingHeight) - kWHC_WaterDropSize / 2.0;
                    _currentRadius = (1.0 - (absActualOffset - kWHC_RefreshingHeight) / (kWHC_PullHeight - kWHC_Margin)) * kWHC_WaterDropSize / 2.0;
                }else{
                    _currentRadius = kWHC_WaterDropSize / 2.0;
                    _backView.centerY = self.height - kWHC_WaterDropSize / 2.0;
                }
            }
            [self updateProgressBarWithValue:absActualOffset];
            [self setNeedsDisplay];
        }else{
            if(actualOffset < 0 && _currentRefreshState != DoingRefresh && _currentRefreshState != DidRefreshed){
                if(_backView.hidden){
                    _backView.hidden = NO;
                }
                if(absActualOffset > kWHC_RefreshingHeight){
                    if(absActualOffset <= kWHC_PullHeight){
                        _isBreak = NO;
                        _backView.centerY = self.height - (absActualOffset - kWHC_RefreshingHeight) - kWHC_WaterDropSize / 2.0;
                        _currentRadius = (1.0 - (absActualOffset - kWHC_RefreshingHeight) / (kWHC_PullHeight - kWHC_Margin)) * kWHC_WaterDropSize / 2.0;
                        _currentRefreshState = WillRefresh;
                        if(_currentRadius < kWHC_BreakRadius){
                            _isBreak = YES;
                            _currentRefreshState = DoingRefresh;
                            _currentRadius = kWHC_BreakRadius;
                        }
                    }else{
                        _isBreak = YES;
                        _currentRadius = kWHC_BreakRadius;
                        _currentRefreshState = DoingRefresh;
                        _backView.centerY = kWHC_RefreshingHeight / 2.0;
                    }
                    
                }
                [self updateProgressBarWithValue:absActualOffset];
                [self setNeedsDisplay];
                
                switch (_currentRefreshState) {
                    case NoneRefresh:
                    case WillRefresh:
                        if(![self.subviews containsObject:_backView]){
                            [self addSubview:_backView];
                        }
                        break;
                    case DoingRefresh:{
                        if([self.subviews containsObject:_backView]){
                            [_backView removeFromSuperview];
                            [self setImageProgressBarAnimation];
                        }
                    }
                        break;
                    case DidRefreshed:
                        break;
                    default:
                        break;
                }
                if(_superView.isDragging && _currentRefreshState == DoingRefresh){
                    [self sendDownRefreshCommand];
                }
            }
        }
    }else{
        if(_backView.hidden == NO){
            _backView.hidden = YES;
        }
    }
}

- (void)setDefualtOffset:(CGFloat)defualtOffset{
    if(!_isSetDefualtOffset){
        _defualtOffset = defualtOffset;
        _isSetDefualtOffset = YES;
    }
}

- (void)setDownRefreshDidFinished{
    _currentRefreshState = DidRefreshed;
    _isDidRefresh = YES;
    _canRequest = NO;
    if([self.subviews containsObject:_progressBarImageView]){
        _refreshAlertLab.centerY = _progressBarImageView.centerY;
        [_progressBarImageView removeFromSuperview];
        [self addSubview:_refreshAlertLab];
    }
}

- (void)resetDownRefreshState{
    [self updateProgressBarWithValue:0];
    [_progressBarImageView.layer removeAllAnimations];
    _progressBarImageView.centerY = _progressBarImageView.height / 2.0;
    _refreshAlertLab.centerY = _refreshAlertLab.height / 2.0;
    if([self.subviews containsObject:_progressBarImageView]){
        [_progressBarImageView removeFromSuperview];
    }
    if([self.subviews containsObject:_refreshAlertLab]){
        [_refreshAlertLab removeFromSuperview];
    }
    if(![self.subviews containsObject:_backView]){
        [self addSubview:_backView];
    }
    _isRequestEndNOInit = NO;
    _isDidSendRequest = NO;
    _backView.centerY = self.height - kWHC_WaterDropSize / 2.0;
    if(_currentRefreshState == WillRefresh){
        _backView.hidden = NO;
    }else if(_currentRefreshState == DidRefreshed){
        _backView.hidden = YES;
        _isCloseHeader = NO;
    }
    _isBreak = NO;
    _currentRefreshState = NoneRefresh;
    [self setNeedsDisplay];
}

- (void)setProgressBarEndDragPostion{
    _progressBarImageView.centerY = self.height - kWHC_RefreshingHeight / 2.0;
}

- (void)sendDownRefreshCommand{
    if(![self.subviews containsObject:_progressBarImageView]){
        [self addSubview:_progressBarImageView];
    }
    _progressBarImageView.centerY = self.height - kWHC_RefreshingHeight / 2.0;
    if(!_isDidSendRequest){
        _isDidSendRequest = YES;
        if(_delegate && [_delegate respondsToSelector:@selector(WHCDownPullRequest)]){
            [_delegate WHCDownPullRequest];
        }
    }
}

- (void)drawRect:(CGRect)rect{
    if(_isBreak && (_currentRefreshState == DoingRefresh || _currentRefreshState == DidRefreshed)){
        return;
    }
    CGPoint  a     = CGPointMake(_backView.x + 0.5, _backView.centerY),
             b     = CGPointMake(_backView.maxX - 0.5, _backView.centerY),
             c     = CGPointMake(_backView.centerX + _currentRadius - 0.5, self.height - _currentRadius),
             d     = CGPointMake(_backView.centerX - _currentRadius + 0.5, self.height - _currentRadius),
             ctr1  = CGPointMake(d.x, d.y - (self.height - _currentRadius - _backView.centerY) / 2.0),
             ctr2  = CGPointMake(c.x, c.y - (self.height - _currentRadius - _backView.centerY) / 2.0);
    
    UIBezierPath * bezierPath = [UIBezierPath bezierPath];
    bezierPath.lineJoinStyle = kCGLineJoinRound;
    bezierPath.lineCapStyle = kCGLineCapRound;
    [bezierPath moveToPoint:a];
    [bezierPath addQuadCurveToPoint:d controlPoint:ctr1];
    [bezierPath addLineToPoint:c];
    [bezierPath addQuadCurveToPoint:b controlPoint:ctr2];
    [bezierPath moveToPoint:a];
    [bezierPath closePath];
    
    CGContextRef  context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, kWHC_WaterBackColor);
    CGContextSetFillColorWithColor(context, kWHC_WaterBackColor);
    CGContextSetLineWidth(context, 1.0);
    if(_backView.hidden == NO){
        CGContextAddArc(context, d.x + _currentRadius - 0.5, d.y, _currentRadius - 0.5, 0, M_PI * 2.0, NO);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        CGContextAddPath(context, bezierPath.CGPath);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    UIGraphicsEndImageContext();
}

@end

#pragma mark - 滚动视图分类 -

@implementation UIScrollView (WHC_PullRefresh)
const char WHCHeaderMask = '8';
const char WHCFooterMask = '9';

- (void)createHeaderViewWithDelegate:(id<WHC_PullRefreshDelegate>)delegate{
    for (WHC_PullHeaderView * view in self.subviews) {
        if([view isKindOfClass:[WHC_PullHeaderView class]]){
            return;
        }
    }
    WHC_PullHeaderView   *  headerView = [[WHC_PullHeaderView alloc]initWithFrame:CGRectMake(0, -kWHC_PullHeight, CGRectGetWidth([UIScreen mainScreen].bounds), kWHC_PullHeight) delegate:delegate];
    headerView.backgroundColor = self.backgroundColor;
    [headerView setSuperView:self];
    objc_setAssociatedObject(self, &WHCHeaderMask, headerView, OBJC_ASSOCIATION_RETAIN);
    [self insertSubview:headerView atIndex:0];
}

- (void)createFooterViewWithDelegate:(id<WHC_PullRefreshDelegate>)delegate{
    for (WHC_PullFooterView * view in self.subviews) {
        if([view isKindOfClass:[WHC_PullFooterView class]]){
            return;
        }
    }
    WHC_PullFooterView   *  footerView = [[WHC_PullFooterView alloc]initWithFrame:CGRectMake(0, self.height, CGRectGetWidth([UIScreen mainScreen].bounds), kWHC_RefreshingHeight) delegate:delegate];
    [footerView setSuperView:self];
    footerView.backgroundColor = self.backgroundColor;
    objc_setAssociatedObject(self, &WHCFooterMask, footerView, OBJC_ASSOCIATION_RETAIN);
    [self insertSubview:footerView atIndex:0];
}

- (void)setWHCRefreshStyle:(WHCPullRefreshStyle)refreshStyle  delegate:(id<WHC_PullRefreshDelegate>)delegate{
    [self removeHeaderView];
    [self removeFooterView];
    if(refreshStyle != NoneRefresh){
        [self addObserver];
        switch (refreshStyle) {
            case AllStyle:
                [self createFooterViewWithDelegate:delegate];
                [self createHeaderViewWithDelegate:delegate];
                break;
            case FooterStyle:
                [self removeHeaderView];
                [self createFooterViewWithDelegate:delegate];
                break;
            case HeaderStyle:
                [self createHeaderViewWithDelegate:delegate];
                break;
            default:
                break;
        }
    }
}

- (void)removeHeaderView{
    WHC_PullHeaderView  * headerView = [self getHeaderView];
    if(headerView){
        self.contentInset = UIEdgeInsetsMake(self.contentInset.top, 0, self.contentInset.bottom, 0);
        [headerView setDelegate:nil];
        if([self.subviews containsObject:headerView]){
            [headerView removeFromSuperview];
            headerView = nil;
        }
    }
}

- (void)removeFooterView{
    WHC_PullFooterView  * footerView = [self getFooterView];
    if(footerView){
        self.contentInset = UIEdgeInsetsMake(self.contentInset.top, 0, self.contentInset.bottom, 0);
        [footerView setDelegate:nil];
        if([self.subviews containsObject:footerView]){
            [footerView removeFromSuperview];
            footerView = nil;
        }
    }
}

- (WHC_PullHeaderView *)getHeaderView{
    return objc_getAssociatedObject(self, &WHCHeaderMask);
}

- (WHC_PullFooterView *)getFooterView{
    return objc_getAssociatedObject(self, &WHCFooterMask);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:kWHC_ContentOffset]){
        [self scrollViewDidScroll:[change[NSKeyValueChangeNewKey] CGPointValue]];
    }else if ([keyPath isEqualToString:kWHC_ContentSize]){
        WHC_PullFooterView  * footerView = [self getFooterView];
        if(footerView){
            [footerView updatePostion];
        }
    }
}

- (void)WHCDidCompletedWithRefreshIsDownPull:(BOOL)isDown{
    __weak  typeof(self)  sf = self;
    if(isDown){
        WHC_PullHeaderView  * headerView = [self getHeaderView];
        if(headerView){
            [headerView setDownRefreshDidFinished];
            double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [UIView animateWithDuration:kWHC_OffsetAnimationTime delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    sf.contentInset = UIEdgeInsetsMake(headerView.superOriginalContentInset.top, 0, headerView.superOriginalContentInset.bottom, 0);
                } completion:^(BOOL finished) {
                    if(!self.isDragging){
                        [headerView resetDownRefreshState];
                    }else{
                        headerView.isRequestEndNOInit = YES;
                    }
                    headerView.canRequest = YES;
                }];
            });
        }
    }else{
        WHC_PullFooterView  * footerView = [self getFooterView];
        if(footerView){
            [footerView setUpRefreshDidFinished];
            [UIView animateWithDuration:kWHC_OffsetAnimationTime delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                sf.contentInset = UIEdgeInsetsMake(footerView.superOriginalContentInset.top, 0, footerView.superOriginalContentInset.bottom, 0);
            } completion:^(BOOL finished) {
                footerView.isSetOffset = NO;
                if(!self.isDragging){
                    [footerView resetUpRefreshState];
                }
            }];
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint )contentOffset{
    CGFloat  defaultOffset = 0.0;
    WHC_PullHeaderView  * headerView = [self getHeaderView];
    WHC_PullFooterView  * footerView = [self getFooterView];
    if(headerView){
        defaultOffset = headerView.superOriginalContentInset.top;
    }else if(footerView){
        defaultOffset = footerView.superOriginalContentInset.top;
    }
    __weak  typeof(self)  sf = self;
    if(contentOffset.y < -defaultOffset && headerView){
        if(!self.isDragging){
            [self scrollViewDidEndDraggingWithwillDecelerate:YES isUp:NO];
        }else{
            if(-contentOffset.y < self.contentInset.top){
                if(!headerView.isCloseHeader && headerView.currentRefreshState == DoingRefresh){
                    headerView.isCloseHeader = YES;
                    [UIView animateWithDuration:kWHC_OffsetAnimationTime delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        sf.contentInset = UIEdgeInsetsMake(headerView.superOriginalContentInset.top, 0, headerView.superOriginalContentInset.bottom, 0);
                    } completion:nil];
                    
                }
            }else if(-contentOffset.y >= self.contentInset.top + kWHC_RefreshingHeight){
                if(headerView.isCloseHeader && headerView.currentRefreshState == DoingRefresh){
                    headerView.isCloseHeader = NO;
                    [UIView animateWithDuration:kWHC_OffsetAnimationTime delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        sf.contentInset = UIEdgeInsetsMake(headerView.superOriginalContentInset.top + kWHC_RefreshingHeight, 0, headerView.superOriginalContentInset.bottom, 0);
                    } completion:nil];
                }
            }
        }
        if(footerView && footerView.currentRefreshState == DidRefreshed){
            [footerView resetUpRefreshState];
        }
        [headerView setProgressValue:contentOffset.y];
    }else{
        if(!self.isDragging){
            [self scrollViewDidEndDraggingWithwillDecelerate:YES isUp:YES];
        }
        
        if(headerView && headerView.currentRefreshState == DidRefreshed){
            [headerView resetDownRefreshState];
        }
        if(footerView){
            [footerView setProgressValue:contentOffset.y];
        }
    }
}

- (void)scrollViewDidEndDraggingWithwillDecelerate:(BOOL)decelerate isUp:(BOOL)isUp{
    __weak  typeof(self)  sf = self;
    if(isUp){
        WHC_PullFooterView  * footerView = [self getFooterView];
        if(footerView){
            if(footerView.currentRefreshState == DoingRefresh  && !footerView.isSetOffset){
                footerView.isSetOffset = YES;
                [UIView animateWithDuration:kWHC_OffsetAnimationTime delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    sf.contentInset = UIEdgeInsetsMake(footerView.superOriginalContentInset.top, 0, kWHC_RefreshingHeight + footerView.superOriginalContentInset.bottom, 0);
                } completion:nil];
            }else if (!footerView.isSetOffset){
                [footerView resetUpRefreshState];
            }
        }
    }else{
        WHC_PullHeaderView  * headerView = [self getHeaderView];
        if(headerView){
            if(headerView.currentRefreshState == DoingRefresh){
                if(!headerView.isCloseHeader){
                    sf.contentInset = UIEdgeInsetsMake(kWHC_RefreshingHeight + headerView.superOriginalContentInset.top, 0, headerView.superOriginalContentInset.bottom, 0);
                }
                [headerView setProgressBarEndDragPostion];
//            }[headerView resetDownRefreshState];
            }else if(headerView.currentRefreshState != DidRefreshed || headerView.isRequestEndNOInit){
                [headerView resetDownRefreshState];
            }
        }
    }
}

- (void)addObserver{
    [self addObserver:self forKeyPath:kWHC_ContentOffset options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:kWHC_ContentSize options:NSKeyValueObservingOptionNew context:nil];
}

- (void)cancelledObsever{

}
@end
