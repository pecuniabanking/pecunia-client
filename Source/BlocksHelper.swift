/**
 * Copyright (c) 2015, Pecunia Project. All rights reserved.
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

import AppKit;

// Helper code for working with blocks (especially when using GCD).
// Original cancelable block code from Sebastien Thiebaud.

typealias dispatch_cancelable_block_t = (cancel: Bool) -> Void;

func dispatch_after_delay(queue: dispatch_queue_t, delay: CGFloat, block: dispatch_block_t) -> dispatch_cancelable_block_t {
    var cancelableBlock: dispatch_cancelable_block_t? = nil;
    var originalBlock: dispatch_block_t? = block;

    // This block will be executed in NOW() + delay
    let delayBlock: dispatch_cancelable_block_t = { cancel in
        if !cancel {
            dispatch_async(dispatch_get_main_queue(), originalBlock!);
        }

        // We don't want to hold any objects in memory.
        originalBlock = nil;
        cancelableBlock = nil;
    };

    cancelableBlock = delayBlock;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * CGFloat(NSEC_PER_SEC))), queue) {
        // We are now in the future (NOW() + delay).
        // It means the block hasn't been canceled so we can execute it.
        if cancelableBlock != nil {
          cancelableBlock!(cancel: false);
        }
    };

    return cancelableBlock!;
}

func cancel_block(block: dispatch_cancelable_block_t) -> Void {
    block(cancel: true);
}
