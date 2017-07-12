//
//  ViewController.m
//  FSLineChart
//
//  Created by Arthur GUIBERT on 30/09/2014.
//  Copyright (c) 2014 Arthur GUIBERT. All rights reserved.
//

#import "FSLineDoubleViewController.h"
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"

@interface FSLineDoubleViewController ()

@property (nonatomic, strong) IBOutlet FSLineChart *chartWithDates;

@end

@implementation FSLineDoubleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadChartWithDates];
}

#pragma mark - Setting up the chart

- (void)loadChartWithDates {
    // Generating some dummy data
    NSMutableArray* chartData = [[NSMutableArray alloc] init];
    for(int i=0;i<5;i++) {
        chartData[i] = [NSNumber numberWithFloat: (float)i / 30.0f + (float)(rand() % 100) / 500.0f];
    }
    NSMutableArray* twoDData = [[NSMutableArray alloc] init];
    for(int i=0;i<5;i++) {
        twoDData[i] = [NSNumber numberWithFloat: (float)i / 30.0f + (float)(rand() % 100) / 500.0f];
    }
    
    NSArray* months = @[@"January", @"February", @"March", @"April", @"May", @"June", @"July"];
    
    
    // Setting up the line chart
    _chartWithDates.animationDuration = 2;
    _chartWithDates.verticalGridStep = 6;
    _chartWithDates.horizontalGridStep = 2;
    _chartWithDates.fillColor = nil;
    _chartWithDates.displayDataPoint = YES;
    _chartWithDates.bezierSmoothing = NO;
    //_chartWithDates.fillColor = [UIColor blueColor];
    _chartWithDates.dataPointColor = [UIColor fsOrange];
    _chartWithDates.dataPointBackgroundColor = [UIColor fsOrange];
    _chartWithDates.dataPointRadius = 2;
    _chartWithDates.color = [_chartWithDates.dataPointColor colorWithAlphaComponent:0.3];
    _chartWithDates.secondLineColor = [UIColor blueColor];
    _chartWithDates.valueLabelPosition = ValueLabelLeftMirrored;
    //_chartWithDates.maxYAxis = (CGFloat)0.5;
    //_chartWithDates.horizontalShift = 0;
    
    _chartWithDates.labelForIndex = ^(NSUInteger item) {
        return months[item];
    };
    
    _chartWithDates.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.02f €", value];
    };
    
    //[_chartWithDates setChartData:chartData];
    
    [_chartWithDates setTwoChartDataSets:chartData second:twoDData];
    
}

@end
