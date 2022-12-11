# SVG

## Elements and Their Attributes

    circle cx cy r
    ellipse cx cy rx ry
    image x y width height href preserveAspectRatio
    line x1 y1 x2 y2
    path d
    polygon points="x,y ..."
    polyline points="x,y ..."
    rect x y width height rx ry
    use href x y width height

## d

https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d

-   0,0 is the upper left-hand corner.
-   Right is positive; left is negative.
-   Down is positive; up is negative.

```
Move from current point to...           M x,y               m dx,dy
Draw a line from current point to...    L x,y               l dx,dy
Draw a horiz. or vert. line             H x     V y         h dx    v dy
Draw a cubic Bezier curve       C x1,y1 x2,y2 x,y   c dx1,dy1 dx2,dy2 dx,dy
       (smooth)                 S x2,y2 x,y         s dx2,dy2 dx,dya
Draw a quadratic Bezier curve   Q x1,y1 x,y         q dx1,dy1 dx,dy
       (smooth)                 T x,y               t dx,dy
Draw an elliptical arc curve    A rx,ry angle large-arc-flag sweep-flag x y
                                a rx,ry angle large-arc-flag sweep-flag dx dy
Close current path: join instead of just line-to    Z or z
```

## Common Attributes

    id
    class
    style

    fill                        .
    fill-opacity                .
    opacity                     .
    stroke                      .
    stroke-dasharray            .
    stroke-dashoffset           .
    stroke-linecap              butt|round|square
    stroke-linejoin             arcs|bevel|miter|miter-clip|round
    stroke-opacity              .
    stroke-width                .
    transform                   .

## Common Text Attributes

    font-family                 .
    font-size                   .
    font-style                  .
    font-variant                .
    text-anchor                 start|middle|end

## Baseline Related Attributes

    alignment-baseline          auto|baseline|before-edge|text-before-edge|
                                  middle|central|after-edge|text-after-edge|
                                  ideographic|alphabetic|hanging|mathematical|
                                  inherit
    baseline-shift              auto|baseline|super|sub|<percentage>|<length>|
                                  inherit
    dominant-baseline           auto|text-bottom|alphabetic|ideographic|middle|
                                  central|mathematical|hanging|text-top

## Other Attributes

    clip
    clip-path
    clip-rule
    color                       currentcolor for fill/stroke/*-color
    color-interpolation
    color-interpolation-filters
    color-profile
    cursor
    direction
    display
    enable-background
    fill-rule
    filter
    flood-color
    flood-opacity
    font-size-adjust
    font-stretch
    font-weight
    glyph-orientation-horizontal
    glyph-orientation-vertical
    image-rendering
    kerning
    letter-spacing
    lighting-color
    marker-end
    marker-mid
    marker-start
    mask
    overflow
    pointer-events
    shape-rendering
    stop-color
    stop-opacity
    stroke-miterlimit
    text-decoration
    text-rendering
    unicode-bidi
    vector-effect
    visibility
    word-spacing
    writing-mode
