# InstaClip Share

An iOS Share Extension and Podcast Player host app written in Swift 2.0 and Xcode 7

By [John Weeks](http://moonrisesoftware.net/blog/)

Have you ever wanted to share an excerpt from a podcast with someone? The extension makes an audio clip of a podcast and attaches it to a message that you can send.
Share extension features:

- Adaptive UI Podcast Player Host app
    - plays podcasts that have been synced on your iOS device from iTunes or Apple’s Podcast app.
- State Restoration
- Remote Control (lock screen, headphone button)

###### What’s new in V0.3
The Share Extension now has a clip editor. The audio waveform is scrollable throughout the entire podcast.  Drag the clip start or end to change the clip's beginning or end time. The arrow buttons shift the clip forward or backward in the timeline. I rewrote the Share Extension using the VIPER application architecture. I'll be posting a blot entry about my experience shortly.

###### V0.2
I updated the code that accesses the iOS media library (podcasts are sync'd here) from plain old functions to Swift extensions and added unit tests to test them. Check out my blog post for more details.   

###### V0.1
In this version I have focused on an adaptive UI to select podcasts that have been synced on your iOS device from iTunes or Apple’s Podcast app. I wanted to create a simple and functional UI for all iOS devices that allows you to play existing podcast episodes. The main point of this project is to demonstrate a share extension in Swift so I’m not going to reinvent the wheel by coding a podcast syncing mechanism.

###### V0.0
In this version I focused solely on a bare bones clip creator in the share extension. The host app provides a hard coded audio file url and current play time to the share extension (I’ll fix the hard coded file limitation in the next version). The share extension gets the parameters, makes the clip, attaches it to a MFMessageComposeViewController and then presents it for the user to send.

###### Notes for Xcode debugging:
You have to run InstaClip Player first to load the app. Then switch schemes to InstaClip Share, run and choose InstaClip Player. On your first share you will have to select More... and enable InstaClip Share. The first run with the debugger is slow, otherwise its quick.

Read more about it [here](http://moonrisesoftware.net/blog/).