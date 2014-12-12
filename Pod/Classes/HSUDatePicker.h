//
//  DatePicker.h
//  DatePicker
//
//  Created by Jason Hsu on 13-9-17.
//  Copyright (c) 2013年 Jason Hsu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HSUDatePickerDelegate;
@interface HSUDatePicker : UIViewController

@property (nonatomic, strong) UIColor *todayColor;
@property (nonatomic, strong) UIColor *touchColor;
@property (nonatomic, strong) UIColor *weekdayColor;
@property (nonatomic, strong) UIColor *weekendColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *disabledColor;
@property (nonatomic, assign) BOOL allowPastDateSelection;
@property (nonatomic, strong) UIImage *customCancelButtonImage;

@property (nonatomic, assign) NSInteger startYear;
@property (nonatomic, assign) NSInteger endYear;

@property (nonatomic, assign, getter = isSupportMultiSelection) BOOL supportMultiSelection;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) NSDateComponents *selectedDateComponents;
@property (nonatomic, weak) id<HSUDatePickerDelegate> delegate;

- (id)initWithStartYear:(NSInteger)startYear endYear:(NSInteger)endYear;
- (id)initFromCurrentYearWithYears:(NSInteger)years;

@end

@protocol HSUDatePickerDelegate <NSObject>

- (void)datePicker:(HSUDatePicker *)datePicker didSelectDate:(NSDate *)date;
- (void)datePickerDidCancelSelect:(HSUDatePicker *)datePicker;

@end