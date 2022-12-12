# names

-   ellipse cx cy rx ry
-   line x1 y1 x2 y2
-   path d
-   polygon points="x,y x,y x,y x,y"
-   polyline points="x,y x,y x,y x,y"
-   rect x y width height rx ry

# attributes

-   id
-   class
-   style
-   fill
-   fill-opacity
-   opacity
-   stroke
-   stroke-dasharray
-   stroke-dashoffset
-   stroke-linecap
-   stroke-linejoin
-   stroke-miterlimit
-   stroke-opacity
-   stroke-width
-   transform

# path

move to first coordinate pair; implicit line to additional pairs
-   M x,y [x,y ...]
-   m dx,dy [dx,dy ...]

line from current point to first coorindate pair then implicit lines to additional pairs
-   L x,y [x,y ...]
-   l dx,dy [dx,dy ...]

draw line from current point to X coordinate or dx
-   H x [x ...]
-   h dx [dx ...]

draw line from current point to Y coordinate or dy
-   V y [y ...]
-   v dy [dy ...]

cubic bezier curve from current point 
-   C x1,y1 x2,y2 x,y [x1,y1 x2,y2 x,y ...]
smooth cubic bezier curve from current point
-   S x2,y2 x,y [x2,y2 x,y ...]

https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d

