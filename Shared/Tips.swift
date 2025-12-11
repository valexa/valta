//
//  Tips.swift
//  valta
//
//  Created by vlad on 11/12/2025.
//

import TipKit

struct AvatarTip: Tip {
    var title: Text {
        Text("Team Member")
    }
    var message: Text? {
        Text("Make sure you selected the correct user, it can not be changed")
    }
    var asset: Image? {
        Image(systemName: AppSymbols.person2Fill)
    }
}
