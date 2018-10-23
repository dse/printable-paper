# Constructing a Grid

## Grid Properties

    -   unit

## Elements

`horizontal-line` --- A single horizontal line

    -   x || x, y1, y2 || x, y1, length || x, y2, length
    -   snap-to
    -   css-class

`vertical-line` --- A single vertical line

    -   y || y, x1, x2 || y, x1, length || y, x2, length
    -   snap-to
    -   css-class

`horizontal-line-array` --- An array of horizontal lines, from top to bottom

    -   x1, x2
    -   y1, y2
    -   y-spacing (1 unit)
    -   y-origin (50%)
    -   snap-to
    -   css-class
    -   nearest (center, margins, ends)
    -   exclude

`vertical-line-array` --- An array of vertical lines, from left to right

    -   x1, x2
    -   y1, y2
    -   x-spacing
    -   x-origin
    -   snap-to
    -   css-class
    -   nearest (center, margins, ends)
    -   exclude

`grid` --- A grid of horizontal and vertical lines, or dots

    -   is-dot-grid
    -   is-enclosed (if not a dot grid)
    -   x1, x2
    -   y1, y2
    -   x-spacing
    -   y-spacing
    -   x-origin
    -   y-origin
    -   snap-to || x-snap-to, y-snap-to
    -   css-class || x-css-class, y-css-class
    -   nearest (center, margins, ends)
    -   exclude || x-exclude, y-exclude

`snap-to`

    -   id of set of horizontal lines
    -   id of set of vertical lines
    -   id of grid
    -   center?
    -   margins (near)
    -   ends (near)
    -   bottom or top; left or right
