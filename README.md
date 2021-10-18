# remarkable-keywriter [![opkg](https://img.shields.io/badge/OPKG-keywriter-blue)](https://toltec-dev.org/)

master build status: [![CircleCI](https://circleci.com/gh/dps/remarkable-keywriter.svg?style=svg)](https://circleci.com/gh/dps/remarkable-keywriter)

---

More than a decade ago I had a [Psion 5mx](https://en.wikipedia.org/wiki/Psion_Series_5). A great little palmtop computer with a mechanical keyboard. I used it to take notes in meetings, to write stuff on trains and on beaches. This was before the mobile web was a thing, so my 5mx also had the awesome trait of helping me stay way more focused that writing on my PC. Last year, I found out about the [Freewrite](https://getfreewrite.com/) - a quirky eInk + mechanical keyboard single purpose writing machine. It *looks* pretty cool and the idea of a completely distraction-free device for _writing_, with a real mechanical keyboard, which would work well in direct sunlight - I was intrigued, maybe the 5mx was back?

I didn't buy one - it was expensive, and some of the reviews suggested the freewrite was more novelty than useful appliance, so I bought a reMarkable tablet instead. The reMarkable is a great pen based, distraction-free note taker. But freehand notes, even with the handwriting recognition in the latest update aren't great for a certain kind of writing... composing a blog post for instance.

So, over the long weekend I decided to try turning my reMarkable, with a real keyboard connected via USB on-the-go into something as close to a Freewriter as I could make.

Here it is: reMarkable keyWriter.
![Image of reMarkable keyWriter](https://blog.singleton.io/static/imgs-remarkable-keywriter/keywriter.jpg)

And here's a video of it in action on YouTube:
https://www.youtube.com/watch?v=viNgCsWecF0

A full screen content-only UI inspired by [Notable's](https://github.com/notable/notable) full-screen focus mode. Content is written in markdown format and you can flip from edit mode to rendered reading mode by hitting escape. The `sundown` markdown renderer is built in - full markdown syntax is supported. I love the keyboard driven productivity of Slack's omnibox, so Ctrl-K brings up a quick note switcher... Type the name of a fresh note and hit enter to start composing something new! There's just enough functionality without a keyboard connected to make it possible to read previously composed notes.

Building this was fun, it works particularly well outdoors in direct sunlight and is quite an enchanting experience for note taking and focused writing... I even used it to write this README!

# How to install on your own reMarkable

If you have toltec installed, just install with `opkg install keywriter`. Otherwise use the following steps:

* Follow the instructions at https://remarkablewiki.com/tech/ssh to set up passwordless ssh to your reMarkable
* either build from source (a build script which you can use for insipration is in this repo at `.circleci/config.yml`) or use the prebuilt binary at `prebuilt/edit`
* copy the binary onto your tablet `scp edit 10.11.99.1:/home/root/edit` (use the IP address and destination of your own set up). If you use the [draft](https://github.com/dixonary/draft-reMarkable) custom launcher, you'll find example config and an icon in `draft_files`.
* Attach a USB keyboard with a USB OTG connector (e.g. [this one](https://www.amazon.com/dp/B015GZOHKW/ref=cm_sw_r_cp_tai_vzK-CbQ1FWJ3Z)). Note that Apple USB keyboards with built in USB hubs don't work - it needs to be a simple USB device, not a hub.
* `ssh` to your remarkable and create the directory notes will be stored in
  * `mkdir -p /home/root/edit`
  * Add some content to the default scratch note:
  * `echo scratch > /home/root/edit/scratch.md`
* (if not using a custom launcher)
    * ssh to your reMarkable
    * kill the main UI `killall xochitl`
    * start `edit`
