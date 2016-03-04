//
//  AZConvert.m
//  AZTableViewExample
//
//  Created by Arron Zhang on 16/3/4.
//  Copyright © 2016年 Arron Zhang. All rights reserved.
//

#import "AZConvert.h"
#import "YYModel.h"
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import "AZRoot.h"

@implementation AZConvert

+ (void) convertForModel:(id)model data:(NSDictionary *)data root:(AZRoot *)root{
    
    //root has the strong reference of row.
    //row has the strong reference of block.
    //Weak reference the root instance for block memory circle.
    __weak AZRoot *_root = root;
    
    NSDictionary *propertyInfos = [YYClassInfo classInfoWithClass:((id<YYModel>)model).class].propertyInfos;
    
    id (*convert)(id, SEL, id) = (typeof(convert))objc_msgSend;
    
    for (NSString *key in data) {
        id value = data[key];
        if (propertyInfos[key] && value != [NSNull null]) {
            YYClassPropertyInfo *prop = propertyInfos[key];
            switch ((prop.type & YYEncodingTypeMask)) {
                case YYEncodingTypeObject:{
                    //Convert number format date which YYModel ignore.
                    if ([prop.cls isSubclassOfClass:[NSDate class]] && [value isKindOfClass:[NSNumber class]]) {
                        [model setValue:[NSDate dateWithTimeIntervalSince1970:[value doubleValue] / 1000.0] forKey:key];
                    } else {
                        SEL sel = prop.cls ? NSSelectorFromString([NSString stringWithFormat:@"%@:", NSStringFromClass(prop.cls), nil]) : nil;
                        if (sel && [self respondsToSelector:sel]) {
                            id val = convert([self class], sel, value);
                            [model setValue:val forKey:key];
                        }
                    }
                } break;
                case YYEncodingTypeBlock:{
                    //Transform event block from string
                    if ([value isKindOfClass:[NSString class]]) {
                        [model setValue:^(AZRow *row, UIView *from, id val){
                            if (_root.onEvent) {
                                _root.onEvent(value, row, from, val);
                            }
                        } forKey:key];
                    }
                } break;
                case YYEncodingTypeInt64:{
                    //Transform enum number value from string
                    if ([value isKindOfClass:[NSString class]]) {
                        SEL sel = NSSelectorFromString([NSString stringWithFormat:@"enum_%@:", key, nil]);
                        if ([self respondsToSelector:sel]) {
                            id val = convert([self class], sel, value);
                            if (val) {
                                [model setValue:val forKey:key];
                            }
                        }
                    }
                } break;
                default:
                    break;
            }
        }
    }
}

+ (UIColor *)UIColor:(id)json{
    if (!json) {
        return nil;
    }
    if ([json isKindOfClass:[NSString class]]) {
        json = [json stringByReplacingOccurrencesOfString:@"'" withString:@""];
        if ([json hasPrefix:@"#"]) {
            const char *s = [json cStringUsingEncoding:NSASCIIStringEncoding];
            if (*s == '#') {
                ++s;
            }
            unsigned long long value = strtoll(s, nil, 16);
            int r, g, b, a;
            switch (strlen(s)) {
                case 2:
                    // xx
                    r = g = b = (int)value;
                    a = 255;
                    break;
                case 3:
                    // RGB
                    r = ((value & 0xf00) >> 8);
                    g = ((value & 0x0f0) >> 4);
                    b = ((value & 0x00f) >> 0);
                    r = r * 16 + r;
                    g = g * 16 + g;
                    b = b * 16 + b;
                    a = 255;
                    break;
                case 6:
                    // RRGGBB
                    r = (value & 0xff0000) >> 16;
                    g = (value & 0x00ff00) >>  8;
                    b = (value & 0x0000ff) >>  0;
                    a = 255;
                    break;
                default:
                    // RRGGBBAA
                    r = (value & 0xff000000) >> 24;
                    g = (value & 0x00ff0000) >> 16;
                    b = (value & 0x0000ff00) >>  8;
                    a = (value & 0x000000ff) >>  0;
                    break;
            }
            return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/255.0f];
        }
        else
        {
            json = [json stringByAppendingString:@"Color"];
            SEL colorSel = NSSelectorFromString(json);
            if ([UIColor respondsToSelector:colorSel]) {
                return [UIColor performSelector:colorSel];
            }
            return nil;
        }
    } else if([json isKindOfClass:[UIColor class]]){
        return (UIColor *)json;
    } else if ([json isKindOfClass:[NSNumber class]]) {
        NSUInteger argb = [json integerValue];
        CGFloat a = ((argb >> 24) & 0xFF) / 255.0;
        CGFloat r = ((argb >> 16) & 0xFF) / 255.0;
        CGFloat g = ((argb >> 8) & 0xFF) / 255.0;
        CGFloat b = (argb & 0xFF) / 255.0;
        return [UIColor colorWithRed:r green:g blue:b alpha:a];
    } else {
        return nil;
    }
}

/**
 row style
 */

AZ_ENUM_CONVERTER(style, (@{
                           @"default":       @(UITableViewCellStyleDefault),
                           @"subtitle":      @(UITableViewCellStyleSubtitle),
                           @"value1":        @(UITableViewCellStyleValue1),
                           @"value2":        @(UITableViewCellStyleValue2),
                           }))

@end