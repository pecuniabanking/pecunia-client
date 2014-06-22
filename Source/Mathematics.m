/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "Mathematics.h"

@implementation Mathematics

/**
 * Computes the factors α0 and α1 (stored in result[0] and result[1], respectively, that
 * determine a fitting linear regression function for the given data.
 * Usable as: y = α0 + α1 * x;
 */
+ (void)computeLinearFunctionParametersX: (double *)xValues
                                       y: (double *)yValues
                                   count: (NSUInteger)count
                                  result: (double *)result
{
    if (count < 2) {
        result[0] = 0;
        result[1] = 0;

        return;
    }

    CGFloat xMean;
    vDSP_meanvD(xValues, 1, &xMean, count);

    CGFloat yMean;
    vDSP_meanvD(yValues, 1, &yMean, count);

    CGFloat xResidualSum = 0;
    CGFloat yResidualSum = 0;
    for (NSUInteger i = 0; i < count; ++i) {
        CGFloat xResiduum = xValues[i] - xMean;
        CGFloat yResiduum = yValues[i] - yMean;

        xResidualSum += xResiduum * xResiduum;
        yResidualSum += xResiduum * yResiduum;
    }

    result[1] = yResidualSum / xResidualSum;
    result[0] = yMean - result[1] * xMean;
}

/**
 * Computes the factors α0, α1 and α2 (stored in result[0], result[1] and result[2], respectively, that
 * determine a fitting square regression function for the given data.
 * Usable as: y = α0 + x * α1 + x * x * α2;
 */
+ (void)computeSquareFunctionParametersX: (double *)xValues
                                       y: (double *)yValues
                                   count: (NSUInteger)count
                                  result: (double *)result
{
    if (count < 2) {
        result[0] = 0;
        result[1] = 0;
        result[2] = 0;

        return;
    }

    // Solve the equation system to find the minimum residual sum.
    // | n   ∑x  ∑x² |   | α0 |   | ∑y   |
    // | ∑x  ∑x² ∑x³ | * | α1 | = | ∑xy  |
    // | ∑x² ∑x³ ∑x⁴ |   | α2 |   | ∑x²y |

    // We can compute all the sums in one single loop so no need to detour to Accelerate.framework
    // (we don't get ∑x³, ∑x⁴ etc. from there anyway).
    __CLPK_real xSum = 0;
    __CLPK_real x2Sum = 0;
    __CLPK_real x3Sum = 0;
    __CLPK_real x4Sum = 0;
    __CLPK_real ySum = 0;
    __CLPK_real xySum = 0;
    __CLPK_real x2ySum = 0;
    for (NSUInteger i = 0; i < count; ++i) {
        __CLPK_real x = xValues[i];
        __CLPK_real x2 = x * x;
        __CLPK_real y = yValues[i];
        xSum += x;
        x2Sum += x2;
        x3Sum += x * x2;
        x4Sum += x2 * x2;
        ySum += y;
        xySum += x * y;
        x2ySum += x2 * y;
    }

    // Some additional paramater to solve the equation system. These are constant for this computation.
    __CLPK_integer n = 3, nrhs = 1, lda = 3, ldb = 3, info;
    __CLPK_integer ipiv[3];

    // Matrix is stored in column-primary order.
    __CLPK_real a[3 * 3] = {
        count, xSum, x2Sum,
        xSum, x2Sum, x3Sum,
        x2Sum, x3Sum, x4Sum,
    };

    __CLPK_real b[3] = {
        ySum, xySum, x2ySum,
    };

    // Solve a * x = b. Result is stored in b.
    sgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);

    if (info == 0) {
        result[0] = b[0];
        result[1] = b[1];
        result[2] = b[2];
    }
}

static double ticksToNanoseconds;

/**
 * Convenience function to measure time differences very precisely. Use in conjunction with timeDifferenceSince.
 */
+ (uint64_t) beginTimeMeasure {
    if (ticksToNanoseconds == 0) {
        mach_timebase_info_data_t timebase;
        mach_timebase_info(&timebase);
        ticksToNanoseconds = (double)timebase.numer / timebase.denom;
    }
    return mach_absolute_time();
}

/**
 * Returns a precise time differenc in nano seconds since startTime.
 */
+ (double)timeDifferenceSince: (uint64_t)startTime {
    return (mach_absolute_time() - startTime) * ticksToNanoseconds;
}

@end
