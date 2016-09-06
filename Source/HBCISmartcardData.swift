//
//  HBCISmartcardData.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 20.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCICardBankData {
    public var name:String;
    public var bankCode:String;
    public var country:String;
    public var host:String;
    public var hostAdd:String;
    public var userId:String;
    public var commtype:UInt8;
}

struct HBCICardKeyData {
    var keyNumber, keyVersion, keyLength, algorithm:UInt8;
}
