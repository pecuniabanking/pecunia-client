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

/*
typealias dispatch_cancelable_block_t = (_ cancel: Bool) -> Void;

func dispatch_after_delay(_ queue: DispatchQueue, delay: CGFloat, block: @escaping ()->()) -> dispatch_cancelable_block_t {
    var cancelableBlock: dispatch_cancelable_block_t? = nil;
    let originalBlock: ()->()? = block;

    // This block will be executed in NOW() + delay
    let delayBlock: dispatch_cancelable_block_t = { cancel in
        if !cancel {
            DispatchQueue.main.async(execute: originalBlock as! @convention(block) () -> Void);
        }

        // We don't want to hold any objects in memory.
        //originalBlock = nil; does not work in Swift3
        cancelableBlock = nil;
    };

    cancelableBlock = delayBlock;

    queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * CGFloat(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
        // We are now in the future (NOW() + delay).
        // It means the block hasn't been canceled so we can execute it.
        if cancelableBlock != nil {
          cancelableBlock!(false);
        }
    };

    return cancelableBlock!;
}

func cancel_block(_ block: dispatch_cancelable_block_t) -> Void {
    block(true);
}
 
*/
