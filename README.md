InstaClip Share
============

An iOS Share Extension written in Swift 2.0

By [John Weeks](http://moonrisesoftware.net/blog/)

Have you ever wanted to share an excerpt from a podcast with someone? InstaClip Share to the rescue! The extension makes an audio clip of a podcast and attaches it to a message that you can send.

In this version I focused solely on a bare bones clip creator in the share extension. The host app provides a hard coded audio file url and current play time to the share extension (I’ll fix the hard coded file limitation in the next version). The share extension gets the parameters, makes the clip, attaches it to a MFMessageComposeViewController and then presents it for the user to send.

Read more about it [here](http://moonrisesoftware.net/blog/).