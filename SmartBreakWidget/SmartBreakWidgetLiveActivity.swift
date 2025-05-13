//
//  SmartBreakWidgetLiveActivity.swift
//  SmartBreakWidget
//
//  Created by Hugo Peyron on 13/05/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SmartBreakWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SmartBreakWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SmartBreakWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SmartBreakWidgetAttributes {
    fileprivate static var preview: SmartBreakWidgetAttributes {
        SmartBreakWidgetAttributes(name: "World")
    }
}

extension SmartBreakWidgetAttributes.ContentState {
    fileprivate static var smiley: SmartBreakWidgetAttributes.ContentState {
        SmartBreakWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SmartBreakWidgetAttributes.ContentState {
         SmartBreakWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SmartBreakWidgetAttributes.preview) {
   SmartBreakWidgetLiveActivity()
} contentStates: {
    SmartBreakWidgetAttributes.ContentState.smiley
    SmartBreakWidgetAttributes.ContentState.starEyes
}
