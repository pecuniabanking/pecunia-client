/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "GraphicsAdditions.h"

/**
 * Creates a CGColorRef from an NSColor. The caller is reponsible for releasing the result
 * using CGColorRelease.
 */
CGColorRef CGColorCreateFromNSColor(NSColor *color)
{
    // First convert the given color to a color with an RGB colorspace in case we use a pattern
    // or named color space. No-op if the color is already using RGB.
    NSColor         *deviceColor = [color colorUsingColorSpace: [NSColorSpace genericRGBColorSpace]];
    CGColorSpaceRef colorspace = [[deviceColor colorSpace] CGColorSpace];
    const NSInteger nComponents = [deviceColor numberOfComponents];

    CGFloat components[nComponents];
    [deviceColor getComponents: components];

    return CGColorCreate(colorspace, components);
}

@implementation NSColor (PecuniaAdditions)

static NSMutableDictionary *defaultColors;
static NSMutableDictionary *userColors;

+ (void)loadApplicationColors
{
    // Generate our random seed.
    srandom(time(NULL));

    defaultColors = [NSMutableDictionary dictionaryWithCapacity: 10];
    userColors = [NSMutableDictionary dictionaryWithCapacity: 10];

    NSString *path = [[NSBundle mainBundle] resourcePath];
    path = [path stringByAppendingString: @"/Colors.acf"];

    NSError  *error = nil;
    NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
    if (error) {
        NSLog(@"Error reading applicaton colors file at %@\n%@", path, [error localizedFailureReason]);
    } else {
        // Lines can be separated by Windows linebreaks, so we need to check explicitly.
        NSArray      *lines = [s componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n"]];
        NSEnumerator *enumerator = [lines objectEnumerator];
        NSString     *line = [[enumerator nextObject] stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
        if (([lines count] > 3) && [line isEqualToString: @"ACF 1.0"]) {
            // Scan for data start.
            while ((line = [enumerator nextObject]) != nil) {
                line = [line stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                if ([line isEqualToString: @"Data:"]) {
                    break;
                }
            }

            // Read color values.
            while (true) {
                while ((line = [enumerator nextObject]) != nil) {
                    line = [line stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                    if (line.length > 0) {
                        break;
                    }
                }
                if (line == nil) {
                    break;
                }

                NSArray *components = [line componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                while ((line = [enumerator nextObject]) != nil) {
                    line = [line stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                    if (line.length > 0) {
                        break;
                    }
                }
                if (line == nil) {
                    break;
                }

                NSColor *color = [NSColor colorWithDeviceRed: [components[0] intValue] / 65535.0
                                                       green: [components[1] intValue] / 65535.0
                                                        blue: [components[2] intValue] / 65535.0
                                                       alpha: 1];
                defaultColors[line] = color;
            }
        }
    }

    // Load colors overwritten by the user.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary   *colors = [defaults objectForKey: @"colors"];
    for (NSString *key in colors.allKeys) {
        NSData *colorData = colors[key];
        userColors[key] = [NSKeyedUnarchiver unarchiveObjectWithData: colorData];
    }
}

/**
 * Returns the next available default color for accounts. These colors are taken from a list
 * of default colors. If this list is exhausted random colors are returned.
 */
+ (NSColor *)nextDefaultAccountColor
{
    if (defaultColors == nil) {
        [self loadApplicationColors];
    }

    static int nextAccountColorIndex = 1;

    NSString *key = [NSString stringWithFormat: @"Default Account Color %i", nextAccountColorIndex];
    NSColor  *color = defaultColors[key];
    if (color != nil) {
        nextAccountColorIndex++;
        return color;
    }

    // No default colors left. Generate a random one (here with an accent on blue).
    return [NSColor colorWithDeviceRed: (96 + random() % 64) / 255.0
                                 green: (96 + random() % 64) / 255.0
                                  blue: (192 + random() % 63) / 255.0
                                 alpha: 1];
}

/**
 * Like nextDefaultAccountColor but for categories.
 */
+ (NSColor *)nextDefaultCategoryColor
{
    if (defaultColors == nil) {
        [self loadApplicationColors];
    }

    static int nextCategoryColorIndex = 1;

    NSString *key = [NSString stringWithFormat: @"Default Category Color %i", nextCategoryColorIndex];
    NSColor  *color = defaultColors[key];
    if (color != nil) {
        nextCategoryColorIndex++;
        return color;
    }

    // Also here, if no default colors are left generate random ones. Take back the blue component a bit
    // so we can use bluish tints rather for account colors.
    return [NSColor colorWithDeviceRed: (32 + random() % 200) / 255.0
                                 green: (32 + random() % 200) / 255.0
                                  blue: (32 + random() % 100) / 255.0
                                 alpha: 1];
}

+ (NSColor *)nextDefaultTagColor
{
    if (defaultColors == nil) {
        [self loadApplicationColors];
    }

    static int nextTagColorIndex = 1;

    NSString *key = [NSString stringWithFormat: @"Default Tag Color %i", nextTagColorIndex];
    NSColor  *color = defaultColors[key];
    if (color != nil) {
        nextTagColorIndex++;
        return color;
    }

    return [NSColor colorWithDeviceRed: (64 + random() % 190) / 255.0
                                 green: (64 + random() % 190) / 255.0
                                  blue: (64 + random() % 190) / 255.0
                                 alpha: 1];
}

+ (NSColor *)nextDefaultStockGraphColor
{
    if (defaultColors == nil) {
        [self loadApplicationColors];
    }

    static int nextStockColorIndex = 1;

    NSString *key = [NSString stringWithFormat: @"Default Stock Graph Color %i", nextStockColorIndex];
    NSColor  *color = defaultColors[key];
    if (color != nil) {
        nextStockColorIndex++;
        return color;
    }

    return [NSColor colorWithDeviceRed: (64 + random() % 190) / 255.0
                                 green: (64 + random() % 190) / 255.0
                                  blue: (64 + random() % 190) / 255.0
                                 alpha: 1];
}

/**
 * Returns a predefined application color named by the given key. This key is the same as used
 * in the "Pecunia Colors.html" chart. The color can be overridden by a user specified color for
 * the same name.
 * Returns black if the given key could not be found.
 */
+ (NSColor *)applicationColorForKey: (NSString *)key
{
    if (defaultColors == nil) {
        [self loadApplicationColors];
    }

    NSColor *color = [userColors valueForKey: key];
    if (color != nil) {
        return color;
    }

    color = [defaultColors valueForKey: key];
    if (color != nil) {
        return color;
    }

    return [NSColor blackColor];
}

/**
 * Stores the given color under the given key as customized user color (which overrides the default color).
 */
+ (void)setApplicationColor: (NSColor *)color forKey: (NSString *)key
{
    if (defaultColors == nil) {
        [self loadApplicationColors];
    }

    NSUserDefaults      *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *colors = [[defaults objectForKey: @"colors"]  mutableCopy];
    if (colors == nil) {
        colors = [NSMutableDictionary dictionaryWithCapacity: 10];
    }
    userColors[key] = color;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject: color];
    colors[key] = colorData;
    [defaults setObject: colors forKey: @"colors"];
}

/**
 * Removes the color with the given key from the user settings thereby making the default value active again.
 */
+ (void)resetApplicationColorForKey: (NSString *)key
{
    [userColors removeObjectForKey: key];

    NSUserDefaults      *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *colors = [[defaults objectForKey: @"colors"]  mutableCopy];
    if (colors != nil) {
        [colors removeObjectForKey: key];
        [defaults setObject: colors forKey: @"colors"];
    }
}

- (NSColor *)colorWithChangedBrightness: (CGFloat)factor
{
    NSColor *deviceColor = [self colorUsingColorSpace: [NSColorSpace genericRGBColorSpace]];
    factor *= deviceColor.brightnessComponent;
    return [NSColor colorWithCalibratedHue: deviceColor.hueComponent
                                saturation: deviceColor.saturationComponent
                                brightness: factor
                                     alpha: deviceColor.alphaComponent];
}

- (NSColor *)colorWithChangedSaturation: (CGFloat)factor
{
    NSColor *deviceColor = [self colorUsingColorSpace: [NSColorSpace genericRGBColorSpace]];
    factor *= deviceColor.saturationComponent;
    return [NSColor colorWithCalibratedHue: deviceColor.hueComponent
                                saturation: factor
                                brightness: deviceColor.brightnessComponent
                                     alpha: deviceColor.alphaComponent];
}

- (NSString *)colorAsHTML
{
    // Convert this color to RGB colorspace first.
    NSColor *deviceColor = [self colorUsingColorSpace: [NSColorSpace genericRGBColorSpace]];
    CGFloat components[deviceColor.numberOfComponents];
    [deviceColor getComponents: components];

    return [NSString stringWithFormat: @"#%2X%2X%2X", (int)(255 * components[0]), (int)(255 * components[1]), (int)(255 * components[2])];
}

@end
