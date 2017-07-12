//
//  FSLineChart.m
//  FSLineChart
//
//  Created by Arthur GUIBERT on 30/09/2014.
//  Copyright (c) 2014 Arthur GUIBERT. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <QuartzCore/QuartzCore.h>
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"

@interface FSLineChart ()

@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) NSMutableArray* secondData;
@property (nonatomic, strong) NSMutableArray* xPos;
@property (nonatomic, strong) NSMutableArray* xPos2;
@property (nonatomic, strong) NSMutableArray* layers;

@property (nonatomic) CGFloat min;
@property (nonatomic) CGFloat max;
@property (nonatomic) CGMutablePathRef initialPath;
@property (nonatomic) CGMutablePathRef newPath;

@end

@implementation FSLineChart

#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    _layers = [NSMutableArray array];
    self.backgroundColor = [UIColor whiteColor];
    [self setDefaultParameters];
}

- (void)setDefaultParameters
{
    _color = [UIColor fsLightBlue];
    _secondLineColor = [UIColor fsRed];
    _fillColor = [_color colorWithAlphaComponent:0.25];
    _verticalGridStep = 3;
    _horizontalGridStep = 3;
    _margin = 5.0f;
    _axisWidth = self.frame.size.width - 2 * _margin;
    _axisHeight = self.frame.size.height - 2 * _margin;
    _axisColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    _innerGridColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _drawInnerGrid = YES;
    _bezierSmoothing = YES;
    _bezierSmoothingTension = 0.2;
    _lineWidth = 1;
    _innerGridLineWidth = 0.5;
    _axisLineWidth = 1;
    _animationDuration = 0.5;
    _displayDataPoint = NO;
    _dataPointRadius = 1;
    _dataPointColor = _color;
    _dataPointBackgroundColor = _color;
    
    // Labels attributes
    _indexLabelBackgroundColor = [UIColor clearColor];
    _indexLabelTextColor = [UIColor grayColor];
    _indexLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10];
    
    _valueLabelBackgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
    _valueLabelTextColor = [UIColor grayColor];
    _valueLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:11];
    _valueLabelPosition = ValueLabelRight;
}

- (void)layoutSubviews
{
    _axisWidth = self.frame.size.width - 2 * _margin;
    _axisHeight = self.frame.size.height - 2 * _margin;
    
    // Removing the old label views as well as the chart layers.
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    [self.layers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CALayer* layer = (CALayer*)obj;
        [layer removeFromSuperlayer];
    }];
    
    
    [self layoutChart];
    [super layoutSubviews];
}

- (void)layoutChart
{
    if(_data == nil) {
        return;
    }
    
    [self computeBounds];
    
    // No data
    if(isnan(_max)) {
        _max = 1;
    }
    
    [self strokeChart];
    
    if(_displayDataPoint) {
        [self strokeDataPoints];
    }
    
    if(_labelForValue) {
        for(int i=0;i<_verticalGridStep;i++) {
            UILabel* label = [self createLabelForValue:i];
            
            if(label) {
                [self addSubview:label];
            }
        }
    }
    
    if(_labelForIndex) {
        for(int i=0;i<_horizontalGridStep + 1;i++) {
            UILabel* label = [self createLabelForIndex:i];
            
            if(label) {
                [self addSubview:label];
            }
        }
    }
    
    [self setNeedsDisplay];
}

- (void)setChartData:(NSArray *)chartData
{
    if (chartData == nil || chartData.count == 0) {
        return;
    }
    
    _data = [NSMutableArray arrayWithArray:chartData];
    
    [self layoutChart];
    
}

- (void)setChartDataWithXPos:(NSArray *)chartData xPos: (NSArray *)xPos
{
    if (chartData == nil || chartData.count == 0) {
        NSLog(@"Need an array of numbers for the chart data");
        return;
    }
    
    if (xPos == nil || xPos.count == 0) {
        NSLog(@"This initalizer function uses a second set of data to set the x positions for the chart data.  Please include a second array the same size as the chartData filled with x posotion numbers for each data point or use the setChartData initializer.");
        return;
    }
    
    if (xPos.count != chartData.count){
        NSLog(@"chartData and xPos must be arrays of the same size.");
        return;
    }
    
    _xPos = [NSMutableArray arrayWithArray:xPos];
    
    _data = [NSMutableArray arrayWithArray:chartData];
    
    [self layoutChart];
    
}

- (void)setTwoChartDataSets: (NSArray *)chartData second: (NSArray *)secondChartData
{
    if (chartData == nil || chartData.count == 0) {
        return;
    }
    
    _data = [NSMutableArray arrayWithArray:chartData];
    
    _secondData = [NSMutableArray arrayWithArray:secondChartData];
    
    [self layoutChart];
    
}

- (void)setTwoChartDataSetsWithXPos: (NSArray *)chartData second: (NSArray *)secondChartData xPos: (NSArray *)xPos secondXPos: (NSArray *)secondXPos{
    if (chartData == nil || chartData.count == 0) {
        NSLog(@"Need an array of numbers for the chart data");
        return;
    }
    
    if (xPos == nil || xPos.count == 0) {
        NSLog(@"This initalizer function uses a second set of data to set the x positions for the chart data.  Please include a second array the same size as the chartData filled with x posotion numbers for each data point or use the setChartData initializer.");
        return;
    }
    
    if (xPos.count != chartData.count){
        NSLog(@"chartData and xPos must be arrays of the same size.");
        return;
    }
    
    if (secondChartData == nil || secondChartData.count == 0) {
        NSLog(@"Need an array of numbers for the second set of chart data");
        return;
    }
    
    if (secondXPos == nil || secondXPos.count == 0) {
        NSLog(@"This initalizer function uses a second set of data to set the x positions for the chart's second data set.  Please include a second array the same size as the secondChartData filled with x posotion numbers for each data point or use the setChartData initializer.");
        return;
    }
    
    if (secondXPos.count != secondChartData.count){
        NSLog(@"secondChartData and secondXPos must be arrays of the same size.");
        return;
    }
    
    _data = [NSMutableArray arrayWithArray:chartData];
    
    _secondData = [NSMutableArray arrayWithArray:secondChartData];
    
    _xPos = [NSMutableArray arrayWithArray:xPos];
    
    _xPos2 = [NSMutableArray arrayWithArray:secondXPos];
    
    [self layoutChart];
}

#pragma mark - Labels creation

- (UILabel*)createLabelForValue: (NSUInteger)index
{
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    
    CGPoint p = CGPointMake(_margin + (_valueLabelPosition == ValueLabelRight ? _axisWidth : 0), _axisHeight + _margin - (index + 1) * _axisHeight / _verticalGridStep);
    
    NSString* text = _labelForValue(minBound + (maxBound - minBound) / _verticalGridStep * (index + 1));
    
    if(!text)
    {
        return nil;
    }
    
    CGRect rect = CGRectMake(_margin, p.y + 2, self.frame.size.width - _margin * 2 - 4.0f, 14);
    
    float width = [text boundingRectWithSize:rect.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{ NSFontAttributeName:_valueLabelFont }
                                     context:nil].size.width;
    
    CGFloat xPadding = 6;
    CGFloat xOffset = width + xPadding;
    
    if (_valueLabelPosition == ValueLabelLeftMirrored) {
        xOffset = -xPadding;
    }
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(p.x - xOffset, p.y + 2, width + 2, 14)];
    label.text = text;
    label.font = _valueLabelFont;
    label.textColor = _valueLabelTextColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = _valueLabelBackgroundColor;
    
    return label;
}

- (UILabel*)createLabelForIndex: (NSUInteger)index
{
    CGFloat scale = [self horizontalScale];
    NSInteger q = (int)_data.count / _horizontalGridStep;
    NSInteger itemIndex = q * index;
    
    if(itemIndex >= _data.count)
    {
        itemIndex = _data.count - 1;
    }
    
    NSString* text = _labelForIndex(itemIndex);
    
    if(!text)
    {
        return nil;
    }
    
    CGPoint p = CGPointMake(_margin + index * (_axisWidth / _horizontalGridStep) * scale, _axisHeight + _margin);
    
    CGRect rect = CGRectMake(_margin, p.y + 2, self.frame.size.width - _margin * 2 - 4.0f, 14);
    
    float width = [text boundingRectWithSize:rect.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{ NSFontAttributeName:_indexLabelFont }
                                     context:nil].size.width;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(p.x - 4.0f, p.y + 2, width + 2, 14)];
    label.text = text;
    label.font = _indexLabelFont;
    label.textColor = _indexLabelTextColor;
    label.backgroundColor = _indexLabelBackgroundColor;
    
    return label;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    if (_data.count > 0) {
        [self drawGrid];
    }
}

- (void)drawGrid
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGContextSetLineWidth(ctx, _axisLineWidth);
    CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
    
    // draw coordinate axis
    CGContextMoveToPoint(ctx, _margin, _margin);
    CGContextAddLineToPoint(ctx, _margin, _axisHeight + _margin + 3);
    CGContextStrokePath(ctx);
    
    CGFloat scale = [self horizontalScale];
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    
    // draw grid
    if(_drawInnerGrid) {
        for(int i=0;i<_horizontalGridStep;i++) {
            CGContextSetStrokeColorWithColor(ctx, [_innerGridColor CGColor]);
            CGContextSetLineWidth(ctx, _innerGridLineWidth);
            
            CGPoint point = CGPointMake((1 + i) * _axisWidth / _horizontalGridStep * scale + _margin, _margin);
            
            CGContextMoveToPoint(ctx, point.x, point.y);
            CGContextAddLineToPoint(ctx, point.x, _axisHeight + _margin);
            CGContextStrokePath(ctx);
            
            CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
            CGContextSetLineWidth(ctx, _axisLineWidth);
            CGContextMoveToPoint(ctx, point.x - 0.5f, _axisHeight + _margin);
            CGContextAddLineToPoint(ctx, point.x - 0.5f, _axisHeight + _margin + 3);
            CGContextStrokePath(ctx);
        }
        
        for(int i=0;i<_verticalGridStep + 1;i++) {
            // If the value is zero then we display the horizontal axis
            CGFloat v = maxBound - (maxBound - minBound) / _verticalGridStep * i;
            
            if(v == 0) {
                CGContextSetLineWidth(ctx, _axisLineWidth);
                CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
            } else {
                CGContextSetStrokeColorWithColor(ctx, [_innerGridColor CGColor]);
                CGContextSetLineWidth(ctx, _innerGridLineWidth);
            }
            
            CGPoint point = CGPointMake(_margin, (i) * _axisHeight / _verticalGridStep + _margin);
            
            CGContextMoveToPoint(ctx, point.x, point.y);
            CGContextAddLineToPoint(ctx, _axisWidth + _margin, point.y);
            CGContextStrokePath(ctx);
        }
    }
    
    UIGraphicsPopContext();
}

- (void)clearChartData
{
    for (CAShapeLayer *layer in self.layers) {
        [layer removeFromSuperlayer];
    }
    [self.layers removeAllObjects];
}

- (void)strokeChart
{
    CGFloat minBound = [self minVerticalBound];
    CGFloat scale = [self verticalScale];
    
    UIBezierPath *noPath = [self getLinePath:0 withSmoothing:_bezierSmoothing close:NO];
    UIBezierPath *path = [self getLinePath:scale withSmoothing:_bezierSmoothing close:NO];
    
    UIBezierPath *noFill = [self getLinePath:0 withSmoothing:_bezierSmoothing close:YES];
    UIBezierPath *fill = [self getLinePath:scale withSmoothing:_bezierSmoothing close:YES];
    
    if(_fillColor) {
        CAShapeLayer* fillLayer = [CAShapeLayer layer];
        fillLayer.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + minBound * scale, self.bounds.size.width, self.bounds.size.height);
        fillLayer.bounds = self.bounds;
        fillLayer.path = fill.CGPath;
        fillLayer.strokeColor = nil;
        fillLayer.fillColor = _fillColor.CGColor;
        fillLayer.lineWidth = 0;
        fillLayer.lineJoin = kCALineJoinRound;
        fillLayer.fillMode = kCAFillModeForwards;
        
        [self.layer addSublayer:fillLayer];
        [self.layers addObject:fillLayer];
        
        CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        fillAnimation.duration = _animationDuration;
        fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        fillAnimation.fillMode = kCAFillModeForwards;
        fillAnimation.fromValue = (id)noFill.CGPath;
        fillAnimation.toValue = (id)fill.CGPath;
        [fillLayer addAnimation:fillAnimation forKey:@"path"];
    }
    
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + minBound * scale, self.bounds.size.width, self.bounds.size.height);
    pathLayer.bounds = self.bounds;
    pathLayer.path = path.CGPath;
    pathLayer.strokeColor = [_color CGColor];
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = _lineWidth;
    pathLayer.lineJoin = kCALineJoinRound;
    pathLayer.fillMode = kCAFillModeForwards;
    
    [self.layer addSublayer:pathLayer];
    [self.layers addObject:pathLayer];
    
    if(_fillColor) {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.duration = _animationDuration;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue = (__bridge id)(noPath.CGPath);
        pathAnimation.toValue = (__bridge id)(path.CGPath);
        [pathLayer addAnimation:pathAnimation forKey:@"path"];
    } else {
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = _animationDuration;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [pathLayer addAnimation:pathAnimation forKey:@"path"];
    }
    
    if (_secondData) {
        
        NSLog(@"Found ourself a second data set");
        
        UIBezierPath *noPathSecond = [self getSecondLinePath:0 withSmoothing:_bezierSmoothing close:NO];
        UIBezierPath *pathSecond = [self getSecondLinePath:scale withSmoothing:_bezierSmoothing close:NO];
        
        CAShapeLayer *secondPathLayer = [CAShapeLayer layer];
        secondPathLayer.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + minBound * scale, self.bounds.size.width, self.bounds.size.height);
        secondPathLayer.bounds = self.bounds;
        secondPathLayer.path = pathSecond.CGPath;
        secondPathLayer.strokeColor = [_secondLineColor CGColor];
        secondPathLayer.fillColor = nil;
        secondPathLayer.lineWidth = _lineWidth;
        secondPathLayer.lineJoin = kCALineJoinRound;
        secondPathLayer.fillMode = kCAFillModeForwards;
        
        [self.layer addSublayer:secondPathLayer];
        [self.layers addObject:secondPathLayer];
        
        if(_fillColor) {
            CABasicAnimation *secondPathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
            secondPathAnimation.duration = _animationDuration;
            secondPathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            secondPathAnimation.fromValue = (__bridge id)(noPathSecond.CGPath);
            secondPathAnimation.toValue = (__bridge id)(pathSecond.CGPath);
            [secondPathLayer addAnimation:secondPathAnimation forKey:@"path"];
        } else {
            CABasicAnimation *secondPathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            secondPathAnimation.duration = _animationDuration;
            secondPathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            secondPathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
            secondPathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
            [secondPathLayer addAnimation:secondPathAnimation forKey:@"path"];
        }
    }
}

- (void)strokeDataPoints
{
    CGFloat minBound = [self minVerticalBound];
    CGFloat scale = [self verticalScale];
    
    for(int i=0;i<_data.count;i++) {
        CGPoint p = [self getPointForIndex:i withScale:scale];
        p.y +=  minBound * scale;
        
        UIBezierPath* circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - _dataPointRadius, p.y - _dataPointRadius, _dataPointRadius * 2, _dataPointRadius * 2)];
        
        CAShapeLayer *fillLayer = [CAShapeLayer layer];
        fillLayer.frame = CGRectMake(p.x, p.y, _dataPointRadius, _dataPointRadius);
        fillLayer.bounds = CGRectMake(p.x, p.y, _dataPointRadius, _dataPointRadius);
        fillLayer.path = circle.CGPath;
        fillLayer.strokeColor = _dataPointColor.CGColor;
        fillLayer.fillColor = _dataPointBackgroundColor.CGColor;
        fillLayer.lineWidth = 1;
        fillLayer.fillMode = kCAFillModeForwards;
        fillLayer.lineJoin = kCALineJoinRound;
        
        [self.layer addSublayer:fillLayer];
        [self.layers addObject:fillLayer];
    }
    
    if (_secondData) {
        for(int i=0;i<_secondData.count;i++) {
            CGPoint p = [self getSecondDataPointForIndex:i withScale:scale withShift:_horizontalShift];
            p.y +=  minBound * scale;
            
            UIBezierPath* circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - _dataPointRadius, p.y - _dataPointRadius, _dataPointRadius * 2, _dataPointRadius * 2)];
            
            CAShapeLayer *secondFillLayer = [CAShapeLayer layer];
            secondFillLayer.frame = CGRectMake(p.x, p.y, _dataPointRadius, _dataPointRadius);
            secondFillLayer.bounds = CGRectMake(p.x, p.y, _dataPointRadius, _dataPointRadius);
            secondFillLayer.path = circle.CGPath;
            secondFillLayer.strokeColor = _dataPointColor.CGColor;
            secondFillLayer.fillColor = _dataPointBackgroundColor.CGColor;
            secondFillLayer.lineWidth = 1;
            secondFillLayer.fillMode = kCAFillModeForwards;
            secondFillLayer.lineJoin = kCALineJoinRound;
            
            [self.layer addSublayer:secondFillLayer];
            [self.layers addObject:secondFillLayer];
        }
    }
}

#pragma mark - Chart scale & boundaries

- (CGFloat)horizontalScale
{
    CGFloat scale = 1.0f;
    NSInteger q = (int)_data.count / _horizontalGridStep;
    
    if(_data.count > 1) {
        scale = (CGFloat)(q * _horizontalGridStep) / (CGFloat)(_data.count - 1);
    }
    
    return scale;
}

- (CGFloat)verticalScale
{
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    CGFloat spread = maxBound - minBound;
    CGFloat scale = 0;
    
    if (spread != 0) {
        scale = _axisHeight / spread;
    }
    
    return scale;
}

- (CGFloat)minVerticalBound
{
    return MIN(_min, 0);
}

- (CGFloat)maxVerticalBound
{
    return MAX(_max, 0);
}

- (void)computeBounds
{
    _min = MAXFLOAT;
    _max = -MAXFLOAT;
    
    for(int i=0;i<_data.count;i++) {
        NSNumber* number = _data[i];
        if([number floatValue] < _min)
            _min = [number floatValue];
        
        if([number floatValue] > _max)
            _max = [number floatValue];
    }
    
    // The idea is to adjust the minimun and the maximum value to display the whole chart in the view, and if possible with nice "round" steps.
    _max = [self getUpperRoundNumber:_max forGridStep:_verticalGridStep];
    
    if (_maxYAxis){
        _max = _maxYAxis;
    }
    
    if(_min < 0) {
        // If the minimum is negative then we want to have one of the step to be zero so that the chart is displayed nicely and more comprehensively
        float step;
        
        if(_verticalGridStep > 3) {
            step = fabs(_max - _min) / (float)(_verticalGridStep - 1);
        } else {
            step = MAX(fabs(_max - _min) / 2, MAX(fabs(_min), fabs(_max)));
        }
        
        step = [self getUpperRoundNumber:step forGridStep:_verticalGridStep];
        
        float newMin,newMax;
        
        if(fabs(_min) > fabs(_max)) {
            int m = ceilf(fabs(_min) / step);
            
            newMin = step * m * (_min > 0 ? 1 : -1);
            newMax = step * (_verticalGridStep - m) * (_max > 0 ? 1 : -1);
            
        } else {
            int m = ceilf(fabs(_max) / step);
            
            newMax = step * m * (_max > 0 ? 1 : -1);
            newMin = step * (_verticalGridStep - m) * (_min > 0 ? 1 : -1);
        }
        
        if(_min < newMin) {
            newMin -= step;
            newMax -=  step;
        }
        
        if(_max > newMax + step) {
            newMin += step;
            newMax +=  step;
        }
        
        _min = newMin;
        _max = newMax;
        
        if(_max < _min) {
            float tmp = _max;
            _max = _min;
            _min = tmp;
        }
        
    }
}

#pragma mark - Chart utils

- (CGFloat)getUpperRoundNumber:(CGFloat)value forGridStep:(int)gridStep
{
    if(value <= 0)
        return 0;
    
    // We consider a round number the following by 0.5 step instead of true round number (with step of 1)
    CGFloat logValue = log10f(value);
    CGFloat scale = powf(10, floorf(logValue));
    CGFloat n = ceilf(value / scale * 4);
    
    int tmp = (int)(n) % gridStep;
    
    if(tmp != 0) {
        n += gridStep - tmp;
    }
    
    return n * scale / 4.0f;
}

- (void)setGridStep:(int)gridStep
{
    _verticalGridStep = gridStep;
    _horizontalGridStep = gridStep;
}

- (CGPoint)getPointForIndex:(NSUInteger)idx withScale:(CGFloat)scale
{
    if(idx >= _data.count) {
        return CGPointZero;
    }
    
    NSInteger shift = 0;
    
    if (_horizontalShift){
        shift = _horizontalShift;
    }
    
    // Compute the point position in the view from the data with a set scale value
    NSNumber* number = _data[idx];
    
    if(_data.count < 2) {
        return CGPointMake(_margin, _axisHeight + _margin - [number floatValue] * scale);
    } else {
        if (_xPos){
            NSNumber* xPos = _xPos[idx];
            return CGPointMake(_margin + ([xPos floatValue] + shift) * (_axisWidth / (_data.count + shift - 1)), _axisHeight + _margin - [number floatValue] * scale);
        }else{
            return CGPointMake(_margin + (idx + shift) * (_axisWidth / (_data.count + shift - 1)), _axisHeight + _margin - [number floatValue] * scale);
        }
    }
}

- (CGPoint)getSecondDataPointForIndex:(NSUInteger)idx withScale:(CGFloat)scale
{
    return [self getSecondDataPointForIndex:idx withScale:scale withShift:0];
}

- (CGPoint)getSecondDataPointForIndex:(NSUInteger)idx withScale:(CGFloat)scale withShift: (NSInteger)shift
{
    if(idx >= _secondData.count) {
        return CGPointZero;
    }
    
    // Compute the point position in the view from the data with a set scale value
    NSNumber* number = _secondData[idx];
    
    if(_secondData.count < 2) {
        return CGPointMake(_margin, _axisHeight + _margin - [number floatValue] * scale);
    } else {
        return CGPointMake(_margin + (idx + shift) * (_axisWidth / (_secondData.count + shift - 1)), _axisHeight + _margin - [number floatValue] * scale);
    }
}

- (UIBezierPath*)getLinePath:(float)scale withSmoothing:(BOOL)smoothed close:(BOOL)closed
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    if(smoothed) {
        for(int i=0;i<_data.count - 1;i++) {
            CGPoint controlPoint[2];
            CGPoint p = [self getPointForIndex:i withScale:scale];
            
            // Start the path drawing
            if(i == 0)
                [path moveToPoint:p];
            
            CGPoint nextPoint, previousPoint, m;
            
            // First control point
            nextPoint = [self getPointForIndex:i + 1 withScale:scale];
            previousPoint = [self getPointForIndex:i - 1 withScale:scale];
            m = CGPointZero;
            
            if(i > 0) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (nextPoint.x - p.x) / 2;
                m.y = (nextPoint.y - p.y) / 2;
            }
            
            controlPoint[0].x = p.x + m.x * _bezierSmoothingTension;
            controlPoint[0].y = p.y + m.y * _bezierSmoothingTension;
            
            // Second control point
            nextPoint = [self getPointForIndex:i + 2 withScale:scale];
            previousPoint = [self getPointForIndex:i withScale:scale];
            p = [self getPointForIndex:i + 1 withScale:scale];
            m = CGPointZero;
            
            if(i < _data.count - 2) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (p.x - previousPoint.x) / 2;
                m.y = (p.y - previousPoint.y) / 2;
            }
            
            controlPoint[1].x = p.x - m.x * _bezierSmoothingTension;
            controlPoint[1].y = p.y - m.y * _bezierSmoothingTension;
            
            [path addCurveToPoint:p controlPoint1:controlPoint[0] controlPoint2:controlPoint[1]];
        }
        
    } else {
        for(int i=0;i<_data.count;i++) {
            if(i > 0) {
                [path addLineToPoint:[self getPointForIndex:i withScale:scale]];
            } else {
                [path moveToPoint:[self getPointForIndex:i withScale:scale]];
            }
        }
    }
    
    if(closed) {
        // Closing the path for the fill drawing
        [path addLineToPoint:[self getPointForIndex:_data.count - 1 withScale:scale]];
        [path addLineToPoint:[self getPointForIndex:_data.count - 1 withScale:0]];
        [path addLineToPoint:[self getPointForIndex:0 withScale:0]];
        [path addLineToPoint:[self getPointForIndex:0 withScale:scale]];
    }
    
    return path;
}

- (UIBezierPath*)getSecondLinePath:(float)scale withSmoothing:(BOOL)smoothed close:(BOOL)closed
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    if(smoothed) {
        for(int i=0;i<_secondData.count - 1;i++) {
            CGPoint controlPoint[2];
            CGPoint p = [self getSecondDataPointForIndex:i withScale:scale withShift:_horizontalShift];
            
            // Start the path drawing
            if(i == 0)
                [path moveToPoint:p];
            
            CGPoint nextPoint, previousPoint, m;
            
            // First control point
            nextPoint = [self getSecondDataPointForIndex:i + 1 withScale:scale withShift:_horizontalShift];
            previousPoint = [self getSecondDataPointForIndex:i - 1 withScale:scale withShift:_horizontalShift];
            m = CGPointZero;
            
            if(i > 0) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (nextPoint.x - p.x) / 2;
                m.y = (nextPoint.y - p.y) / 2;
            }
            
            controlPoint[0].x = p.x + m.x * _bezierSmoothingTension;
            controlPoint[0].y = p.y + m.y * _bezierSmoothingTension;
            
            // Second control point
            nextPoint = [self getSecondDataPointForIndex:i + 2 withScale:scale withShift:_horizontalShift];
            previousPoint = [self getSecondDataPointForIndex:i withScale:scale withShift:_horizontalShift];
            p = [self getSecondDataPointForIndex:i + 1 withScale:scale withShift:_horizontalShift];
            m = CGPointZero;
            
            if(i < _secondData.count - 2) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (p.x - previousPoint.x) / 2;
                m.y = (p.y - previousPoint.y) / 2;
            }
            
            controlPoint[1].x = p.x - m.x * _bezierSmoothingTension;
            controlPoint[1].y = p.y - m.y * _bezierSmoothingTension;
            
            [path addCurveToPoint:p controlPoint1:controlPoint[0] controlPoint2:controlPoint[1]];
        }
        
    } else {
        for(int i=0;i<_secondData.count;i++) {
            if(i > 0) {
                [path addLineToPoint:[self getSecondDataPointForIndex:i withScale:scale withShift:_horizontalShift]];
            } else {
                [path moveToPoint:[self getSecondDataPointForIndex:i withScale:scale withShift:_horizontalShift]];
            }
        }
    }
    
    if(closed) {
        // Closing the path for the fill drawing
        [path addLineToPoint:[self getSecondDataPointForIndex:_secondData.count - 1 withScale:scale withShift:_horizontalShift]];
        [path addLineToPoint:[self getSecondDataPointForIndex:_secondData.count - 1 withScale:0 withShift:_horizontalShift]];
        [path addLineToPoint:[self getSecondDataPointForIndex:0 withScale:0 withShift:_horizontalShift]];
        [path addLineToPoint:[self getSecondDataPointForIndex:0 withScale:scale withShift:_horizontalShift]];
    }
    
    return path;
}



@end
