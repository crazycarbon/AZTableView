//
//  AZRow.m
//  AZTableViewExample
//
//  Created by Arron Zhang on 16/3/2.
//  Copyright © 2016年 Arron Zhang. All rights reserved.
//

#import "AZRow.h"
#import "AZTableView.h"
#import "AZConvert.h"

@interface AZRow()

@property(nonatomic, retain) id realAccessoryView;

@end

@implementation AZRow

@synthesize identifier = _identifier, section, text, value, hidden, enabled, focusable, height, accessoryAction, action, valueChangedAction, key, data = _data, style = _style, detail, accessoryType, accessoryView = _accessoryView, selected = _selected, deletable, deletedAction, textFont, textFontSize, detailTextFont, detailTextFontSize, detailTextLine, accessibilityLabel, bindData;

@synthesize onSelect;

@synthesize textColor = _textColor, detailTextColor = _detailTextColor, backgroundColor = _backgroundColor;

@synthesize image, imageURL, selectedImage, imageCornerRadius;

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> text=%@", self.class, self, self.text, nil];
}

+(id)rowWithType:(NSString *)type{
        if ([type isKindOfClass:[NSString class]]) {
            //For extend
            Class cla = NSClassFromString(type);
            if (!cla) {
                if (type && [type length]>0) {
                    type = [type stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[type substringToIndex:1] capitalizedString]];
                }
                cla = NSClassFromString([NSString stringWithFormat:@"AZ%@Row", type]);
            }
            if (cla && [cla isSubclassOfClass:self]) {
                return [cla new];
            } else if(!cla){
                [NSException raise:@"Invalid row type" format:@"type of %@ is invalid", type];
            }
        }
    return [self new];
}

- (NSDictionary *)modelCustomPreTransformFromDictionary:(NSDictionary *)dic {
    if (dic[@"bind"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:dic];
        [data addEntriesFromDictionary:[AZRoot dataFromBind:dic[@"bind"] source:dic[@"bindData"] ? dic[@"bindData"] : (self.section.bindData ? self.section.bindData : self.section.root.bindData)]];
        return data;
    }
    return dic;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    [AZConvert convertForModel:self data:dic root:self.section.root];
    return YES;
}

- (id)init{
    if (self = [super init]) {
        self.enabled = true;
        self.identifier = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.style = UITableViewCellStyleDefault;
        self.detailTextLine = -1;
        self.height = -1;
        self.focusable = NO;
    }
    return self;
}

-(id)initWithSetting:(NSDictionary *)setting{
    if (self = [self init]) {
        [self update:setting];
    }
    return self;
}

-(void)setSelected:(BOOL)selected{
    if (self.section.selectable && !self.section.multiple && selected) {
        for (AZRow *row in self.section.rows) {
            if (row != self) {
                row.selected = NO;
            }
        }
    }
    _selected = selected;
}



- (void)update:(NSDictionary *)setting{
//    [super update:setting];
    //TODO: when reset accessoryAction to nil, the type is not changed.
    if (self.enabled && self.accessoryType == UITableViewCellAccessoryNone) {
        self.accessoryType = self.accessoryAction ? UITableViewCellAccessoryDetailDisclosureButton : (self.action ?  UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone);
    }
    //Auto set key
//    if (!self.key && self.bind && self.bind[@"value"]) {
//        self.key = self.bind[@"value"];
//    }
}

- (void)setAccessoryView:(id)accessoryView{
    _accessoryView = accessoryView;
    self.realAccessoryView = nil;
}

- (id)realAccessoryView{
    if (!_realAccessoryView && _accessoryView) {
        if ([self.accessoryView isEqual:@"loading"]) {
            UIActivityIndicatorView *activity = [UIActivityIndicatorView new];
            activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            [activity startAnimating];
            _realAccessoryView = activity;
        } else {
            //TODO:
//            _realAccessoryView = [AZAccessoryButton buttonWithSetting:self.accessoryView];
        }
    }
    if ([_realAccessoryView isKindOfClass:[UIActivityIndicatorView class]]) {
        [_realAccessoryView startAnimating];
    }
    return _realAccessoryView;
}



- (NSIndexPath *)indexPath{
    if (!self.section) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:[self.section indexForVisibleRow:self] inSection:[self.section.root indexForVisibleSection:self.section]];
}

-(void)willDisplayCell:(AZTableViewCell *)cell forTableView:(AZTableView *)tableView{
}

-(void)didEndDisplayingCell:(AZTableViewCell *)cell forTableView:(AZTableView *)tableView{
    
}


//TODO: move accessoryView to tableViewCell for cache

- (AZTableViewCell *)cellForTableView:(AZTableView *)tableView indexPath:(NSIndexPath *)indexPath{
    AZTableViewCell *cell = [self createCellForTableView:tableView];
    [self updateCell:cell tableView:tableView indexPath:indexPath];
    return cell;
}

- (void)updateCell:(AZTableViewCell *)cell tableView:(AZTableView *)tableView indexPath:(NSIndexPath *)indexPath{
    cell.textLabel.text = self.text;
    cell.selectionStyle = self.enabled && self.action ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    cell.accessoryType = self.accessoryType;
    cell.detailTextLabel.text = self.detail;
    cell.accessoryView = nil;
    cell.accessibilityLabel = self.accessibilityLabel;
    cell.accessoryView = self.realAccessoryView;
    cell.hideSeparator = self.hideSeparator;
//    if ([self.realAccessoryView respondsToSelector:@selector(clickHandler)]) {
//        __weak AZRow *row = self;
//        ((AZAccessoryButton *)self.realAccessoryView).clickHandler = ^(AZButton *button){
//            [row selectedAccessory:tableView indexPath:indexPath];
//        };
//    }
    
    if ([self.imageURL length]) {
        __weak UIImageView* imageView = cell.imageView;
        UIImage *_image = nil;
        if (self.image) {
            _image = [UIImage imageNamed:self.image];
        }
        CGSize size = _image.size;
//        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:self.imageURL] placeholderImage:_image completed:^(UIImage *img, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//            //Resize to placeholder size
//            if (img && size.width) {
//                imageView.image = [img resize:size];
//            }
//        }];
    } else if (self.image) {
        cell.imageView.image = [UIImage imageNamed:self.image];
    } else if (self.imageData) {
        cell.imageView.image = [UIImage imageWithData:[[NSData alloc] initWithBase64Encoding:self.imageData]];
    } else {
        cell.imageView.image = nil;
    }
    if (cell.imageView.image && self.imageCornerRadius) {
        cell.imageView.layer.cornerRadius = self.imageCornerRadius;
        cell.imageView.layer.masksToBounds = YES;
    }
    cell.loading = self.loading;
    cell.textLabel.enabled = self.enabled;
    cell.detailTextLabel.enabled = self.enabled;
    
    //Notice: need set all row color for reuse
    if (self.textColor) {
        [cell setTextColor:self.textColor style:self.style];
        
    }
    if(self.detailTextColor){
        [cell setDetailTextColor:self.detailTextColor style:self.style];
    }
    if(self.backgroundColor){
        cell.backgroundColor = self.backgroundColor;
    }
    
    if (self.textFont) {
        [cell setTextFont:self.textFont size:self.textFontSize style:self.style];
    }
    if (self.detailTextFont) {
        [cell setDetailTextFont:self.detailTextFont size:self.detailTextFontSize style:self.style];
    }
    cell.detailTextLabel.numberOfLines = self.detailTextLine >= 0 ? self.detailTextLine : 1;
    //For selectable
    if (self.section.selectable) {
        cell.selectionStyle = self.enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
        [self selected:self.selected forCell:cell];
    }
}

- (void)selected:(BOOL)selected forCell:(AZTableViewCell *)cell{
    if (self.selectedImage && self.image) {
        cell.imageView.image = [UIImage imageNamed: selected ? self.selectedImage : self.image];
    } else {
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
}

- (AZTableViewCell *)createCellForTableView:(AZTableView *)tableView{
    AZTableViewCell *cell;
    id class = [self cellClass];
    if ([class isKindOfClass:[NSString class]]) {
        NSString *identifier = [NSString stringWithFormat:@"%@%@", class, self.identifier ? [NSString stringWithFormat:@"-%@", self.identifier] : nil];
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil){
            [tableView registerNib:[UINib nibWithNibName:self.identifier ? self.identifier : class bundle:nil] forCellReuseIdentifier:identifier];
            cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        }
    } else {
        NSString *identifier = [NSString stringWithFormat:@"%@-%d%@", self.class, (int)self.style, self.identifier ? [NSString stringWithFormat:@"-%@", self.identifier] : nil];
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil){
            cell = [[class alloc] initWithStyle:self.style reuseIdentifier:identifier];
        }
    }
    cell.tableView = tableView;
    return cell;
}

- (id)cellClass{
    return [AZTableViewCell class];
}

//TODO: test ios6
- (CGFloat)heightForTableView:(AZTableView *)tableView{
    if (self.height < 0 && self.detailTextLine == 0) {
        BOOL ios7 = [[[UIDevice currentDevice] systemVersion] floatValue]>=7.f;
        float imageWidth = 0.f;
        if (self.image){
            imageWidth = [UIImage imageNamed:self.image].size.width + (ios7 ? 15.f : 20.f);
        }
        float padding = ios7 ? 30.f : (tableView.root.grouped ? 40.f : 20.f);
        float fontSize = ios7 ? 12.f : 14.f;
        CGSize constraint = CGSizeMake(tableView.frame.size.width - imageWidth - padding, 20000);
        UIFont *font = self.detailTextFont ? [UIFont fontWithName:self.detailTextFont size: self.detailTextFontSize > 0 ? self.detailTextFontSize : fontSize] : [UIFont systemFontOfSize:fontSize];
        CGSize  size= [self.detail sizeWithFont:font constrainedToSize:constraint lineBreakMode:NSLineBreakByTruncatingTail];
        //        NSLog(@"font %@, size %@ cons %@", font, NSStringFromCGSize(size), NSStringFromCGSize(constraint));
        CGFloat predictedHeight = size.height + 27.0f;
        if (self.text)
            predictedHeight += 20;
        return predictedHeight;
    }
    return self.height >= 0 ? self.height : 44;
}

-(NSDictionary *)extraData:(NSIndexPath *)indexPath{
    return @{
             @"section": @(indexPath.section),
             @"row": @(indexPath.row),
             @"value": self.value ? self.value : [NSNull null],
             @"key": self.key ? self.key : [NSNull null],
             @"data": self.data ? self.data : [NSNull null],
             };
}

- (void)selectedAccessory:(AZTableView *)tableView indexPath:(NSIndexPath *)indexPath{
    if (self.accessoryAction && self.enabled) {
//        tableView.action.delegate.clickOrigin = [tableView cellForRowAtIndexPath:indexPath];
        [tableView action:self.accessoryAction data:self.data extra:[self extraData:indexPath]];
    }
}

- (void)selected:(AZTableView *)tableView indexPath:(NSIndexPath *)indexPath{
    
    //Handle selected
    if (self.section.selectable && self.enabled) {
        AZTableViewCell *cell = (AZTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        if (!self.section.multiple) {
            NSInteger ind = indexPath.section;
            for (NSIndexPath *path in [tableView indexPathsForVisibleRows]) {
                if (path.section == ind && path.row != indexPath.row) {
                    [self selected:NO forCell:(AZTableViewCell *)[tableView cellForRowAtIndexPath:path]];
                }
            }
        }
        self.selected = !self.selected;
        [self selected:self.selected forCell:cell];
        if (self.valueChangedAction) {
            [tableView action:self.valueChangedAction data:@(self.selected) extra:[self extraData:indexPath]];
        }
        [tableView deselect];
    }
    if (self.onSelect && self.enabled) {
        self.onSelect(self, [tableView cellForRowAtIndexPath:indexPath], self.data);
    }
    
    if (self.action && self.enabled) {
//        tableView.action.delegate.clickOrigin = [tableView cellForRowAtIndexPath:indexPath];
        [tableView action:self.action data: self.section.selectable ? @(self.selected) : self.data extra:[self extraData:indexPath]];
    }
}


+(NSDictionary*)styles {
    static NSDictionary *kStyles = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kStyles = @{
                    @"default":       @(UITableViewCellStyleDefault),
                    @"subtitle":      @(UITableViewCellStyleSubtitle),
                    @"value1":        @(UITableViewCellStyleValue1),
                    @"value2":        @(UITableViewCellStyleValue2),
                    };
    });
    return kStyles;
}

+(NSDictionary*)accessoryTypes {
    static NSDictionary *kAccessoryTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAccessoryTypes = @{
                            @"none":                    @(UITableViewCellAccessoryNone),
                            @"checkmark":               @(UITableViewCellAccessoryCheckmark),
                            @"detailDisclosureButton":  @(UITableViewCellAccessoryDetailDisclosureButton),
                            @"disclosureIndicator":     @(UITableViewCellAccessoryDisclosureIndicator),
                            @"detailButton":            @(UITableViewCellAccessoryDetailButton),
                            };
    });
    return kAccessoryTypes;
}
@end