# Presentation for Münster UseR Meeting Nov 20 2018

[Click here if ya just wanna get to the
stuff.](https://mpadge.github.io/ms-user-meetup-nov2018/slides/ms-meetup-nov18.html#1).
Alternatively, if you're interested in the *how*, here's that stuff:

1. Clone the repo
2. Get rid of the entire `docs` folder
3. `make`
4. `make open`

The first `make` should recreate all data used in the presentation, which may
take a while. After that, subsequent `make`s will be effectively instantaneous.

## A bit more detail

The presentation was built with [`xaringan`](https://github.com/yihui/xaringan).
In almost every way a fabulous piece of software, `xaringan` nevertheless does
not (yet) play nicely with every kind of `html` widget. This means that many of
the `leaflet` and `deck.gl` maps that may otherwise have just been generated as
widgets have instead been pre-generated and manually saved as screenshots.
That's just the way things are at this present moment. Should change any day now
...
