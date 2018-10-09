//
//  KUSMLFormValuesPickerView.m
//  Kustomer
//
//  Created by BrainX Technologies on 03/10/2018.
//  Copyright © 2018 Kustomer. All rights reserved.
//

#import "KUSMLFormValuesPickerView.h"
#import "KUSColor.h"
#import "KUSImage.h"
#import "KUSFadingButton.h"
#import "KUSOptionPickerView.h"
#import "KUSMLSelectedValueCollectionViewCell.h"
#import "KUSLocalization.h"

static const CGSize kKUSMinimumCellSize = {50, 50};
static const CGFloat kKUSLineSpacing = 0.0;
static const CGFloat kKUSSendButtonSize = 50.0;
static const CGFloat kKUSCollectionViewCellTextPadding = 15.0;

static NSString *kCellIdentifier = @"MLSelectedValueCell";


@interface KUSMLFormValuesPickerView ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, KUSOptionPickerViewDelegate> {
    CGFloat optionPickerHeight;
    CGFloat mlCollectionViewHeight;
    UIView *_middleHorizontalSeparatorView;
}

@property(nonatomic, strong) KUSOptionPickerView *optionPickerView;
@property(nonatomic, strong) UICollectionView *mlSelectedValueCollectionView;
@property (nonatomic, strong, readwrite) UIButton *sendButton;
@property (nonatomic, copy) NSMutableArray<KUSMLNode *> *valuesTree;
@property (nonatomic, copy) NSMutableArray<KUSMLNode *> *currentOptionsToShow;
@property (nonatomic, copy) NSMutableArray<KUSMLNode *> *selectedValuesStack;
@property (nonatomic, copy) NSMutableArray<NSString *> *currentOptionsValues;
@property (nonatomic, assign) BOOL lastNodeRequired;
@property (nonatomic, assign) BOOL needOptionPicker;

@end

@implementation KUSMLFormValuesPickerView

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [KUSMLFormValuesPickerView class]) {
        KUSMLFormValuesPickerView *appearance = [KUSMLFormValuesPickerView appearance];
        [appearance setViewBackgroundColor: [UIColor whiteColor]];
        [appearance setHorizontalSeparatorColor:[KUSColor lightGrayColor]];
        [appearance setVerticalSeparatorColor:[KUSColor lightGrayColor]];
        [appearance setTextFont:[UIFont systemFontOfSize:14.0]];
        [appearance setSendButtonColor:[KUSColor blueColor]];
        [appearance setSelectedOptionsTextColor:[UIColor blackColor]];
        [appearance setHighlightedSelectedOptionTextColor:[[KUSColor blueColor] colorWithAlphaComponent:0.8]];
    }
}

#pragma mark - Lifecycle methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _optionPickerView = [[KUSOptionPickerView alloc] init];
        _optionPickerView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
        _optionPickerView.delegate = self;
        [self addSubview:_optionPickerView];
        
        _middleHorizontalSeparatorView = [[UIView alloc] init];
        [self addSubview:_middleHorizontalSeparatorView];
        
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        collectionViewLayout.itemSize = kKUSMinimumCellSize;
        collectionViewLayout.minimumInteritemSpacing = kKUSLineSpacing;
        collectionViewLayout.minimumLineSpacing = kKUSLineSpacing;
        _mlSelectedValueCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
        _mlSelectedValueCollectionView.alwaysBounceHorizontal = NO;
        _mlSelectedValueCollectionView.bounces = NO;
        _mlSelectedValueCollectionView.bouncesZoom = NO;
        _mlSelectedValueCollectionView.backgroundColor = [UIColor whiteColor];
        _mlSelectedValueCollectionView.showsHorizontalScrollIndicator = NO;
        _mlSelectedValueCollectionView.dataSource = self;
        _mlSelectedValueCollectionView.delegate = self;
        [_mlSelectedValueCollectionView registerClass:[KUSMLSelectedValueCollectionViewCell class] forCellWithReuseIdentifier:kCellIdentifier];
        [self addSubview:_mlSelectedValueCollectionView];
        
        _sendButton = [[UIButton alloc] init];
        [_sendButton addTarget:self action:@selector(_pressSend) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_sendButton];
        
        [self _updateSendButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL isRTL = [[KUSLocalization sharedInstance] isCurrentLanguageRTL];
    optionPickerHeight = _needOptionPicker ? [_optionPickerView desiredHeight] : 0;
    _optionPickerView.frame = (CGRect) {
        .origin.x = self.frame.origin.x,
        .origin.y = self.bounds.origin.y,
        .size.width = self.bounds.size.width,
        .size.height = optionPickerHeight
    };
    
    CGFloat horizontalSeparatorViewHeight = 1.0;
    CGFloat horizontalSeparatorViewY = self.bounds.origin.y + optionPickerHeight;
    _middleHorizontalSeparatorView.frame = (CGRect) {
        .origin.x = self.frame.origin.x,
        .origin.y = horizontalSeparatorViewY,
        .size.height = horizontalSeparatorViewHeight,
        .size.width = self.bounds.size.width
    };
    
    CGFloat mlCollectionViewY = horizontalSeparatorViewY + horizontalSeparatorViewHeight;
    mlCollectionViewHeight = [self getCollectionViewHeight];
    _mlSelectedValueCollectionView.frame = (CGRect) {
        .origin.x = self.frame.origin.x,
        .origin.y = mlCollectionViewY,
        .size.width = self.bounds.size.width - kKUSSendButtonSize,
        .size.height = mlCollectionViewHeight
    };
    
    self.sendButton.frame = (CGRect) {
        .origin.x = isRTL ? 0.0 : self.bounds.size.width - kKUSSendButtonSize,
        .origin.y = self.bounds.size.height - kKUSSendButtonSize,
        .size.width = kKUSSendButtonSize,
        .size.height = kKUSSendButtonSize
    };
    
}

#pragma mark - Public methods

- (CGFloat)desiredHeight
{
    return optionPickerHeight + mlCollectionViewHeight + 1;
}

- (void)setMLFormValuesPicker:(NSArray<KUSMLNode *> *)valueTree with:(BOOL)lastNodeRequired
{
    _valuesTree = [[NSMutableArray alloc] initWithArray:valueTree];
    _currentOptionsToShow = [[NSMutableArray alloc] initWithArray:valueTree];
    _selectedValuesStack = [[NSMutableArray alloc] init];
    _lastNodeRequired = lastNodeRequired;
    [self showCurrentOptionsAndUpdateView];
}

#pragma mark - Internal logic methods

- (CGSize)getCellSizeWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    [label setText:text];
    [label setFont:_textFont];
    [label sizeToFit];
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    CGSize size = label.bounds.size;
    size.height = MAX(size.height, kKUSMinimumCellSize.height);
    size.width = MAX(size.width + (2 * kKUSCollectionViewCellTextPadding), kKUSMinimumCellSize.width);
    return size;
}

- (CGFloat)getCollectionViewHeight
{
    CGSize size = [self getCellSizeWithText:@"FontHeight"];
    return size.height;
}

- (void)_updateSendButton
{
    BOOL shouldEnableSend = NO;
    if (_selectedValuesStack.count > 0) {
        shouldEnableSend = _lastNodeRequired ? _selectedValuesStack.lastObject.nodeChilds.count == 0 : YES;
    }
    _sendButton.userInteractionEnabled = shouldEnableSend;
    _sendButton.alpha = (shouldEnableSend ? 1.0 : 0.5);
}

- (void)updateLayout
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)_pressSend
{
    if ([self.delegate respondsToSelector:@selector(mlOptionPickerView:didSelect:with:)]) {
        [self.delegate mlOptionPickerView:self didSelect:_selectedValuesStack.lastObject.nodeDisplayName with:_selectedValuesStack.lastObject.nodeId];
    }
}

- (void)showCurrentOptionsAndUpdateView
{
    if (!(_currentOptionsToShow.count > 0)) {
        _needOptionPicker = NO;
    }
    else {
        _needOptionPicker = YES;
        _currentOptionsValues = [[NSMutableArray alloc]initWithCapacity:_currentOptionsToShow.count];
        for (KUSMLNode* option in _currentOptionsToShow)
        {
            [_currentOptionsValues addObject:option.nodeDisplayName];
        }
        [_optionPickerView setOptions:_currentOptionsValues];
    }
    [self updateLayout];
    if ([self.delegate respondsToSelector:@selector(viewHeightDidChange)]) {
        [self.delegate viewHeightDidChange];
    }
    [self _updateSendButton];
    [_mlSelectedValueCollectionView reloadData];
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:_selectedValuesStack.count inSection:0];
    [_mlSelectedValueCollectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (_selectedValuesStack.count > 0 ? _selectedValuesStack.count + 1: 1);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KUSMLSelectedValueCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    [cell setVerticalSeparatorColor:_verticalSeparatorColor];
    [cell setTextFont:_textFont];
    [cell setTextColor:_selectedOptionsTextColor];
    [cell setHighlightedTextColor:_highlightedSelectedOptionTextColor];
    [cell setCellBackgroundColor:_viewBackgroundColor];
    if (_selectedValuesStack.count == 0) {
        [cell setCellValue:@"Please select an item" withFirsCell:YES andLastCell:NO];
    }
    else {
        BOOL isFirst = indexPath.row == 0 ? YES : NO;
        BOOL isLast = indexPath.row == _selectedValuesStack.count;
        if (isFirst) {
            [cell setCellValue:@"Home" withFirsCell:isFirst andLastCell:isLast];
        }
        else {
            [cell setCellValue:_selectedValuesStack[indexPath.row-1].nodeDisplayName withFirsCell:isFirst andLastCell:isLast];
        }
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedValuesStack.count == 0) {
        return;
    }
    
    NSRange rangeToRemove = NSMakeRange(indexPath.row, _selectedValuesStack.count - indexPath.row);
    [_selectedValuesStack removeObjectsInRange:rangeToRemove];
    if (indexPath.row == 0) {
        _currentOptionsToShow = [[NSMutableArray alloc] initWithArray:_valuesTree];
    }
    else {
        _currentOptionsToShow = [[NSMutableArray alloc] initWithArray:_selectedValuesStack[indexPath.row - 1].nodeChilds];
    }
    
    [self showCurrentOptionsAndUpdateView];
}

#pragma mark - UICollectionViewFlowLayoutDelegate methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedValuesStack.count == 0) {
        return [self getCellSizeWithText:@"Please select an item"];
    }
    else {
        if (indexPath.row == 0) {
            return [self getCellSizeWithText:@"Home"];
        }
        else {
            return [self getCellSizeWithText:_selectedValuesStack[indexPath.row-1].nodeDisplayName];
        }
    }
}

#pragma mark - KUSOptionPickerViewDelegate methods

- (void)optionPickerView:(KUSOptionPickerView *)pickerView didSelectOption:(NSString *)option
{
    NSUInteger optionIndex = [pickerView.options indexOfObject:option];
    if (optionIndex != NSNotFound && optionIndex < _currentOptionsToShow.count) {
        [_selectedValuesStack addObject:_currentOptionsToShow[optionIndex]];
    }
    [_currentOptionsToShow removeAllObjects];
    if (_selectedValuesStack.count > 0 && _selectedValuesStack.lastObject.nodeChilds.count > 0) {
        _currentOptionsToShow = [[NSMutableArray alloc] initWithArray:_selectedValuesStack.lastObject.nodeChilds];
    }
    [self showCurrentOptionsAndUpdateView];
}

#pragma mark - UIAppearance methods

- (void)setHorizontalSeparatorColor:(UIColor *)horizontalSeparatorColor
{
    _horizontalSeparatorColor = horizontalSeparatorColor;
    _middleHorizontalSeparatorView.backgroundColor = _horizontalSeparatorColor;
}

- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
}

- (void)setVerticalSeparatorColor:(UIColor *)verticalSeparatorColor
{
    _verticalSeparatorColor = verticalSeparatorColor;
}

- (void)setSelectedOptionsTextColor:(UIColor *)selectedValueTextColor
{
    _selectedOptionsTextColor = selectedValueTextColor;
}

- (void)setHighlightedSelectedOptionTextColor:(UIColor *)lastSelectedValueTextColor
{
    _highlightedSelectedOptionTextColor = lastSelectedValueTextColor;
}

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor
{
    _viewBackgroundColor = viewBackgroundColor;
}

- (void)setSendButtonColor:(UIColor *)sendButtonColor
{
    _sendButtonColor = sendButtonColor;
    UIImage *sendButtonImage = [KUSImage sendImageWithSize:CGSizeMake(30.0, 30.0) color:_sendButtonColor];
    [_sendButton setImage:sendButtonImage forState:UIControlStateNormal];
}

@end
