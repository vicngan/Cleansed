//
//  TodoWidgetBundle.swift
//  TodoWidget
//
//  Created by Nguyen Trong Dat on 2/17/26.
//

import WidgetKit
import SwiftUI

@main
struct TodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
        TodoWidgetControl()
        TodoWidgetLiveActivity()
    }
}
