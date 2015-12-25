/**
 * Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
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

@interface CurrencyValueTransformer : NSValueTransformer
@end

@interface MoreThanOneToBoolValueTransformer : NSValueTransformer
@end

@interface OneOrLessToBoolValueTransformer : NSValueTransformer
@end

@interface ExactlyOneToBoolValueTransformer : NSValueTransformer
@end

@interface ZeroCountToBoolValueTransformer : NSValueTransformer
@end

@interface NonZeroCountToBoolValueTransformer : NSValueTransformer
@end

@interface RemoveWhitespaceTransformer : NSValueTransformer
@end

@interface StringCasingTransformer : NSValueTransformer
@end

@interface PercentTransformer : NSValueTransformer
@end

@interface ObjectToStringTransformer : NSValueTransformer
@end

@interface ZeroValueToBoolTransformer : NSValueTransformer
@end

@interface ValueToColorTransformer : NSValueTransformer
@end
