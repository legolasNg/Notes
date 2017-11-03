Flexbox更适合一些应用程序组件和小规模布局(一维布局)，Grid布局适用于较大规模的布局(二维布局)。

## 布局级别

布局级别分为：

- block：block-level element，块级元素。被显示为独立的一块，多个元素会换行。
- inline：inline-level element，内联元素。多个元素不会换行，在一行内显示直到改行排满。

### html标签的布局级别

- block元素标签：div, form, table, p, pre, h1...h6, dl, ol, ul等
- inline元素标签：span, a, strong, em, label, input, select, textarea, img, br等

可以通过设置`display: inline;`或者`display: block;`，改变元素的布局级别。

一般来说，block元素可以包含block元素和inline元素，但是inline元素只能包含inline元素。但是，每个特定的元素能包含的元素也是特定的，所以具体到个别元素上，该规律不适用(比如p标签，只能包含inline元素，不能包含block元素)。

### 细节比较

- `display:block`：
    1. block元素会独占一行，多个block元素会各自新起一行。默认情况下，block元素宽度自动填充满其父元素宽度。
    2. block元素可以设置width和height属性，即使设置了宽度，仍然独占一行。
    3. block元素可以设置margin和padding属性。

- `display:inline`：
    1. 多个相邻的inline元素会排列在同一行，直到一行被占满才会新换一行，宽度随元素内容而变化。
    2. inline元素设置width和height属性无效。
    3. inline元素，水平方向的padding-left、padding-right、margin-left、margin-right都产生边距效果，竖直方向padding-top、padding-bottom、margin-top、margin-bottom不会产生边距效果。

- `display:inline-block`：
    1. 将对象展现为inline对象，对象内容作为block对象呈现，之后的内联对象会被排列在一行内。

## Flexbox布局

Flexbox布局(也叫Flexible Box布局模块)，是W3C于2009年提出的草案，旨在控制未知容器元素的对齐方式，排列方向，排列顺序等。

flex布局背后的主要思想是，container能改变其items的宽度、高度和顺序，以便能更好地填充可用空间(主要是适应各种显示设备和屏幕大小)。弹性container会扩展item以填充可用空间，或者缩小item以防止溢出。

### 基础知识

Flex布局主要有父容器和它的直接子元素组成，其中父容器被称之为flex container，而其直接的子元素称作为flex item。

![container](https://css-tricks.com/wp-content/uploads/2014/05/flex-container.svg)
![item](https://css-tricks.com/wp-content/uploads/2014/05/flex-items.svg)

#### 父容器

```css
/* 所有 "column-*" 属性在flex父容器上都不生效，并且flex父容器不能使用"::first-line"和"::first-letter"伪元素 */
.container {
    /*  定义flex容器，至于block还是inline取决于所给值 */
    display: flex | inline-flex;
    /*  建立主轴(main axis)，定义子元素的排列方向：水平方向还是垂直方向(flex布局是单向布局概念)
        row(默认值)：在 "ltr" 中是从左到右，在 "rtl" 中是从右到左
        row-reverse：在 "ltr" 中是从右到左，在 "rtl"中是从左到右
        column：在 "ltr" 中是从上到下，在 "rtl" 中是从下到上
        column-reverse：在 "ltr" 中是从下到上，在 "rtl" 中是从上到下 */
    flex-direction：row | row-reverse | column | column-reverse;
    /*  建立交叉轴(cross axis)。默认情况下，子元素会排列在一行，flex-wrap属性用来修改子元素根据容器宽度换行
        nowrap(默认值)：所有子元素都排列在一行
        wrap：子元素排列在多行，从上到下的顺序
        wrap-reverse：子元素排列在多行，从下到上的顺序 */
    flex-wrap: nowrap | wrap | wrap-reverse;
    /*  "flex-direction"和"flex-wrap"属性的缩写，定义主轴和交叉轴，默认值是row nowrap */
    flex-flow: <'flex-direction'> || <'flex-wrap'>;
    /*  定义沿主轴方向的对齐方式
        flex-start(默认值)：主轴起点对齐
        flex-end：主轴终点对齐
        center：主轴中点对齐
        space-between：主轴两端对齐，子元素间隔相等
        space-around：子元素均匀分布在主轴上，每两个子元素间隔为2个单位，首尾元素到容器边缘间隔为1个单位 */
    justify-content: flex-start | flex-end | center | space-between | space-around;
    /*  定义沿交叉轴方向的对齐方式
        flex-start：交叉轴起始边缘对齐
        flex-end：交叉轴终点边缘对齐
        center：交叉轴中点对齐
        baseline：基线(Baseline--多数字母排列的基准线)对齐
        stretch(默认值)：交叉轴方向拉伸，以适应容器 */
    align-items: flex-start | flex-end | center | baseline | stretch ;
    /*  子元素多行显示，定义多行在父容器的交叉轴方向对齐方式给，类似于"justify-content"在主轴方向单个子元素对齐方式
        flex-start：交叉轴起点对齐
        flex-end：交叉轴中点对齐
        center：交叉轴中点对齐
        space-between：交叉轴两端对齐，子元素间隔相等
        space-around：子元素行上下间距相等，沿交叉轴排列。每行间隔为2个单位，首尾行到容器边缘间距为1个单位
        stretch(默认值)：子元素行拉伸，填充剩余空间 */
    align-content: flex-start | flex-end | center | space-between | space-around | stretch;
}
```

#### 子元素

```css
/* "float"、"clear"、"vertical-align"等属性在flex子元素上都不生效，无法将其out-of-flow */
.item {
    /*  默认情况下，flex子元素按照出现顺序排列，"order" 属性可以控制子元素在父容器内出现的顺序 。默认值为0 */
    order: <integer> ;
    /*  定义了子元素在父容器内的放大比例，接受无单位值作为比例(默认值为0，负数无效)，指示子元素在父容器内应该占据的可用空间。
        如果子元素该属性都置为1，父容器的空间将平均分配给每个子元素。
        如果有一个子元素该属性为2，该子元素占据的空间将是其他元素的2倍(至少会尝试) */
    flex-grow: <number>;
    /*  定义了子元素在父容器内的缩小比例，默认值为1，负数无效 */
    flex-shrink: <length> | auto;
    /*  定义了子元素在填充空间前的默认大小，值可以是长度或者auto关键字。
        如果置为0，将不考虑内容周围空间；如果置为1，内容周围空间将根据 "flex-grow" 值来分配 */
    flex-basis: <length> | auto;
    /*  "flex-grow"、"flex-shrink"和"flex-basis"的缩写，"flex-basis"和"flex-shrink"是可选的，默认值是0 1 auto
        值"auto"等价于"1 1 auto"，"none"等价于"0 0 auto"*/
    flex: none | [ <'flex-grow'> <'flex-shrink'>? || <'flex-basis'> ];
    /*  允许单个子元素设置改属性，来覆盖默认对齐方式(或者由"align-items"指定的对齐方式) */
    align-self: auto | flex-start | flex-end | center | baseline | stretch;
}
```

> 一个元素是浮动的(float:left/right)，绝对定位的(position:absolute/fixed)或者是根元素(html)，那么它被称之为流外的元素(out-of-flow)。
> 如果一个元素不是流外的元素，那么它被称之为流内的素(in-flow)。


## Grid布局

Grid布局(也叫CSS栅格布局)，是一个基于栅格的二维布局系统，旨在彻底改变基于网格用户界面的设计。

### 基础知识

参考：
    [A Complete Guide to Flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)
    [A Visual Guide to CSS3 Flexbox Properties](https://scotch.io/tutorials/a-visual-guide-to-css3-flexbox-properties)
    [A Complete Guide to Grid](https://css-tricks.com/snippets/css/complete-guide-grid/)
