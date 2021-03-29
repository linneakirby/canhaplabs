---
layout: post
title:  "project iteration 2"
category: "project"
---

# Project Iteration 2

## This Iteration Goals

Since we are working remotely, we decided to once again create three distinct task lists for the second iteration (assignments are noted in parentheses):

1. Improve upon the interface to create a UI almost completely controlled through the Haply and bugfixes. (Linnea)

2. Add texture to the walls and UI elements and collect opinions on texture. (Marco)

3. Integrate the different explorations from Iteration 1, quality assurance testing, and work with Marco to set up a texture testing codebase. (Preeti)


## Technical Approach and Findings

### Preeti - integration, QA testing, and setting up texture testing code

Preeti took our three separate codebases from Iteration 1 and integrated them into one functional codebase. She then tested the integrated code for quality and came up with a list of bugs that she then passed onto me for fixing:

{% include figure image_path="/assets/project-iteration-2/cursorOffset.gif" alt="Cursor offsets." caption="_The brush when coloring and the cursor when not coloring were offset._" %}

{% include figure image_path="/assets/project-iteration-2/whiteBorder.png" alt="White borders." caption="_The brush would not reach the walls and left a white border. Also, switching from coloring mode to not coloring mode when on a wall would leave a streak of color._" %}

{% include figure image_path="/assets/project-iteration-2/beginningSplotch.png" alt="Splotch of color when beginning." caption="_When first starting the program, the brush would leave a splotch of color._" %}

{% include figure image_path="/assets/project-iteration-2/notooltip.gif" alt="No indication of the brush when coloring." caption="_There was no indication of brush position when coloring, so the user could lose the brush when filling in an area with one color._" %}

She and Marco then compiled a simple interface of their texture explorations so that we could gather some preliminary feedback on texture.

{% include figure image_path="/assets/project-iteration-2/textures.png" alt="Texture interface." caption="_Preeti and Marco visually differentiated the textures only by color so as not to influence any testers._" %}

### Marco - add texture to elements and create a texture testing survey

Marco added a damping effect to the walls of the coloring screen by adding a sensor surrounding the brush like a halo. When the sensor touches a wall, it increases the damping and makes the coloring experience smoother around walls. He also added a honey-like effect to the color picker "buttons" that I added to make it feel like the user is dipping a brush into paint.

{% include figure image_path="/assets/project-iteration-2/dampingHalo.png" alt="The damping halo." caption="_The damping halo and a slider to test different damping strengths._" %}

He then created a survey to go along with the texture exploration interface so that we could collect some opinions from other students in the class about which textures feel good to color on.

{% include figure image_path="/assets/project-iteration-2/survey.png" alt="Marco's survey." caption="_The first page of Marco's survey._" %}

### Linnea - continuing UI and UX development

#### Modifying the color picker

After speaking with our mentors, I decided to switch the color picker from a "mix it yourself" to a "pick from these six options" color picker. Because users would probably want to color with more than just six colors, I decided to make `ColorPalette` and `ColorSwatch` classes so that I could save multiple color palettes and users could swap between them:

```java
public class ColorPalette{
  public ColorSwatch[] palette = new ColorSwatch[6];
  
  public ColorPalette(ColorSwatch[] p){
    for(int i=0; i<p.length; i++){
      this.palette[i] = p[i];
    }
  }
  
  public ColorPalette(ColorSwatch s0, ColorSwatch s1, ColorSwatch s2, ColorSwatch s3, ColorSwatch s4, ColorSwatch s5){
    this(new ColorSwatch[] {s0, s1, s2, s3, s4, s5});
  }
  
  //create empty (black) color palette
  public ColorPalette(){
    this(new ColorSwatch[] {});
  }
  
  public int getLength(){
    return palette.length;
  }
  
  //returns black if swatch doesn't exist
  public ColorSwatch getSwatch(int index){
    if(this.palette[index] != null){
      return this.palette[index];
    }
    return new ColorSwatch(0, 0, 0);
  }
  
  //returns previous color or black if no previous color  
  public ColorSwatch setSwatch(int index, ColorSwatch swatch){
    ColorSwatch ret = this.getSwatch(index);
    this.palette[index] = swatch;
    return ret;
  }
  
  //returns previous color or black if no previous color
  public ColorSwatch addSwatch(ColorSwatch swatch){
    ColorSwatch ret = this.getSwatch(this.palette.length);
    this.palette[this.palette.length] = swatch;
    return ret;
  }
  
  //removes swatch at index and replaces with black, returns original color or black if no original color
  public ColorSwatch removeSwatch(int index){
    ColorSwatch ret = this.getSwatch(index);
    this.palette[index] = new ColorSwatch(0, 0, 0);
    return ret;
  }
  
}
```
_The `ColorPalette` class consists of and array of six `ColorSwatch` objects and is able to add, set, and remove swatches, keeping a default color of black for any undefined swatches._


```java
public class ColorSwatch{
  private int r;
  private int g;
  private int b;
  private int paletteIndex;
  
  public ColorSwatch(int r, int g, int b, int index){
    this.r = r;
    this.g = g;
    this.b = b;
    this.paletteIndex = index;
  }
  
  public ColorSwatch(int r, int g, int b){
    this(r, g, b, 0);
  }
  
  public ColorSwatch(int[] c){
    this(c[0], c[1], c[2], 0);
  }
  
  //default to black
  public ColorSwatch(){
   this(0, 0, 0, 0); 
  }
  
  public void setPaletteIndex(int index){
    paletteIndex = index;
  }
  
  public int getPaletteIndex(){
    return paletteIndex;
  }
  
  public int getRed(){
    return this.r;
  }
  
  public int getGreen(){
    return this.g;
  }
  
  public int getBlue(){
    return this.b;
  }
  
  public int[] getColor(){
    int[] ret = {this.r, this.g, this.b};
    return ret;
  }
  
  public void setColor(int[] c){
    this.r = c[0];
    this.g = c[1];
    this.b = c[2];
  }
  
  public void setColor(int r, int g, int b){
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
}
```

_The `ColorSwatch` class consists of a representation of an RGB color and an index in a `ColorPalette` object. It is able to get and set itself in a couple different ways just out of convenience._

#### Toggling keyboard interactions

I decided to start simple and use keyboard interactions to trigger different events. I used Processing's built-in `KeyPressed()` function to set up my keyboard shortcuts:

```java
void keyPressed() {
  if (key == ' ') { // pressing spacebar makes walls flexible
    if (isDrawingModeEngaged()) {
      disengageDrawingMode();
    } else {
      engageDrawingMode();
    }
  }
  if (key == 'c' || key == 'C') { // pressing c changes to a random colour
    setDrawingColor((int)random(255), (int)random(255), (int)random(255));
  }
  if (key == 'v' || key == 'V') { // pressing v changes to a random shape
    shape = (shape + 1) % (NUM_SHAPES);
  }
}
```

I set the spacebar to toggle a coloring mode on and off, 'c' to randomly change the color, and 'v' to swap between a circle and a square brush tip.

#### Indicating mode

To visually indicate which mode the user is in, I wanted to change the wall color to a bright green when coloring mode is disengaged. I used a HashMap to link the internal Wall representation of each wall with the visual FBox representation. When the spacebar is pressed, I loop through the ArrayList of Wall objects, get the FBox representation from the HashMap, and set the color to the desired color (bright green or black depending on what mode is engaged):


```java
void setWallFlexibility(boolean flexibility, int wallColor) {
  FBox wallInWorld;
  for (Wall item : wallList) {
    wallInWorld = wallToWorldList.get(item);
    wallInWorld.setSensor(flexibility);
    wallInWorld.setFillColor(wallColor);
    wallInWorld.setStrokeColor(wallColor);
  }
}
```

#### Exploring brush shape and color

I decided to disable Preeti's texture explorations for the moment. I liked the idea of visual texture as part of the brush options, but I thought it would be easier to work with basic shapes as I explored changing the brush color. Instead of attaching images to the HVirtualCoupling itself, I used the `playerToken` position to draw an object of the desired shape at the same position. I created two basic brush options for coloring mode – a circle and a square drawing tool – and a cursor for when coloring mode is disengaged:


```java
void drawCursor(PGraphics layer) {
  layer.ellipse(playerToken.getAvatarPositionX()*40, playerToken.getAvatarPositionY()*40, 2, 2);
  world.draw();
}

void drawCircle(PGraphics layer) {
  layer.ellipse(playerToken.getAvatarPositionX()*40, playerToken.getAvatarPositionY()*40, 20, 20);
  world.draw();
}

void drawSquare(PGraphics layer) {
  layer.rect(playerToken.getAvatarPositionX()*40-10, playerToken.getAvatarPositionY()*40-10, 20, 20);
  world.draw();
}
```

I also created six color swatches and a color mixer swatch at the bottom right of the screen. I do not want to rely on keyboard shortcuts long term, so I thought it would make more sense for the user to "dip their brush" into "buckets" to add or subtract red, green, and blue. The color mixer swatch updates the mixed color in real time. 

{% include figure image_path="/assets/project-iteration-1/color-swatches.png" alt="My color swatch setup." caption="_Dipping into the desaturated shade will subtract the corresponding color, while dipping into the saturated shade will add the corresponding color. The bar at the bottom shows the currently mixed color._" %}

#### Creating layers

One big issue I ran into was figuring out how to save the coloring trails while not saving the cursor trails. 

{% include figure image_path="/assets/project-iteration-1/cursor-trails.gif" alt="The cursor leaving a trail." caption="_The bane of my existence for two days straight._" %}

While it was relatively simple to figure out how to change colors and place shapes at the `playerToken`'s position, I struggled with helping the program discriminate what to save. I eventually figured out that I needed to create drawing layers! 

##### Processing frustrations: a short aside

One of my biggest frustrations with Processing is that by attempting to simplify programming, the developers have ended up obfuscating some potentially important information. In my case, the obfuscated information was that the default canvas that pixels get recorded to is called `g`! Any time a Processing-specific method such as `background(<color>)` is called, it affects `g`. The secret I learned is that these methods can also affect other layers, so if you have another layer called `topLayer`, then `topLayer.background(<color>)` changes the background of `topLayer` instead of `g`!

##### Layers upon layers

I decided I needed three layers (ordered top to bottom):

1. a layer to display the cursor every time coloring mode is toggled off
2. a layer to incrementally color on every time coloring mode is toggled on
3. a layer to white-out and load the accumulated color onto each draw cycle

{% include figure image_path="/assets/project-iteration-1/layer-explanation.png" alt="Drawing the layers." caption="_My attempt at drawing how I set up the layers._" %}

I created an array of layers, with `g` as the 0th layer. Each draw cycle, I set `g`'s background to white so as to remove any cursor trails, and load the image from `layers[1]`, the coloring layer. If coloring mode is toggled on, then the current brush is displayed and the color trail is saved to `layers[1]`. If coloring mode is toggled off, then the cursor is displayed on `layers[2]`:

```java

void createLayers() {
  layers[0] = g;
  layers[1] = createGraphics((int)worldWidth*40, (int)worldHeight*40 + 2);
  layers[2] = createGraphics((int)worldWidth*40, (int)worldHeight*40 + 2);
}

void draw() {
  g.background(255);
  image(layers[1], 0, 0);
  if (isDrawingModeEngaged()) {
    layers[1].beginDraw();
    layers[1].noStroke();
    int[] c = getDrawingColor();
    layers[1].fill(color(c[0], c[1], c[2]));
    drawShape(layers[1]);
    layers[1].endDraw();
    image(layers[1], 0, 0);
  } else {
    layers[2].beginDraw();
    layers[2].clear();
    layers[2].background(0, 0);
    layers[2].stroke(255, 0, 0);
    drawCursor(layers[2]);
    layers[2].endDraw();
    image(layers[2], 0, 0, width, height);
  }
  world.draw();
}
```

#### Putting it all together

{% include figure image_path="/assets/project-iteration-1/linnea.gif" alt="My interface exploration." caption="_The result of my various explorations._" %}

My code can be found [here](https://github.com/preetivyas/HaptiColour/tree/lkirby).

## Lessons Learned

I think we achieved a significant amount this iteration. I believe Preeti and Marco's explorations have put us in a good spot to begin putting all the pieces of our design together. Furthermore, I think my accomplishments this iteration have laid the groundwork for augmenting our design.

One of the major lessons I learned this iteration was that sometimes tools that are created in attempts to streamline processes can unintentionally be a hinderance.

I think the biggest obstacles we have moving forward are keeping our design simple and converging towards pleasing textures to interact with. We will need to explore whether it is more pleasing to have a brush texture interacting with a background texture or to have only one of the two. I do not want to end up with an overload of coloring options and texture sensations. At the same time, I would like to keep as many interactions as possible relegated to the Haply so as to not inundate the user with having to remember too many control options. Our stated goal was to create a tool for mindfulness, anxiety reduction, and fine motor skill training and it is important we do not stray too far from this goal by adding in extraneous options.

## Next Iteration Goals

My next iteration goals are to:

1. Implement the interaction of touching the color swatch and changing the mixed color. At the moment, only the random color functionality is implemented.
2. Re-add in Preeti's idea of texture swatches. My current idea is to have a variety of transparent grayscale texture swatches that can be layered over my basic colorful shape brushes.
3. Implement "clear" and "erase" functionality. Also perhaps changing brush size.
4. Explore a "save" functionality. Now that I know how `PGraphics` objects work, I think it should be relatively straightforward to save the image on `layers[1]` to a file.
5. Begin integrating my interface with what Marco and Preeti have been working on.