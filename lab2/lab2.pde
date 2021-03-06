/**
 **********************************************************************************************************************
 * @file       lab2.pde
 * @author     Linnea Kirby
 * @date       05-February-2021
 * @brief      haptic maze loader based off of 
                 - "sketch_4_Wall_Physics.pde" by Steve Ding and Colin Gallacher
                 - "sketch_6_Maze_Physics.pde" by Elie Hymowitz, Steve Ding, and Colin Gallacher
 **********************************************************************************************************************
 * @attention
 *
 *
 **********************************************************************************************************************
 */



/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;

/* end library imports *************************************************************************************************/  



/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 

/* DEFINE USER-SET PARAMETERS HERE! */
public final String FILENAME = "maze.txt";
public final boolean PRINTMAZE = true;

/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                      = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40.0;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                = new PVector(0, 0); 

/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 30.0;  
float             worldHeight                         = 15.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;


/* Definition of wallList */
ArrayList<Wall> wallList;

/* Definition of maze end */
FCircle end;

/* Initialization of player token */
HVirtualCoupling  playerToken;

/* text font */
PFont font;

/* end elements definition *********************************************************************************************/ 



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1200, 600);
  
   /* set font type and size */
  font = loadFont("ComicSansMS-72.vlw");
  textFont(font);
  
  /* device setup */
  
  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */ 
  haplyBoard = new Board(this, "COM3", 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);
  
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1);
 
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
  
  widgetOne.device_set_parameters();
  
  
  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerCentimeter); 
  world               = new FWorld();
  
  /* create the maze!!! */
  try{
    createMaze(parseTextFile());
  }
  catch(incorrectMazeDimensionsException e){
    System.out.println(e);
  }

  /* world conditions setup */
  world.setGravity((0.0), (1000.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0.5);
  
  
  world.draw();
  
  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  

  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(renderingForce == false){
    background(255);
    world.draw();
  }
}
/* end draw section ****************************************************************************************************/

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    renderingForce = true;
    
    if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(posEE.copy().mult(200));  
    }
    
    playerToken.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
    
    
    playerToken.updateCouplingForce();
    fEE.set(-playerToken.getVirtualCouplingForceX(), playerToken.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons
    
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
  
    if (playerToken.h_avatar.isTouchingBody(end)){
      fill(random(255),random(255),random(255));
      text("!!!!!!!!!!", 
            edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
    }
  
    world.step(1.0f/1000.0f);
  
    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

ArrayList<Wall> parseTextFile() throws incorrectMazeDimensionsException{
  wallList = new ArrayList<Wall>();
  Wall w;
  
     String[] lines = loadStrings(FILENAME);
     
     if( lines == null){
       throw new NullPointerException("There is an error with your file!");
     }
     
     String line = lines[0]; // height and width of maze
     String[] mazeWH = line.split(" ");
     int mazeW = Integer.parseInt(mazeWH[0]);
     int mazeH = Integer.parseInt(mazeWH[1]);
     
     if(mazeW != worldWidth || mazeH != worldHeight){
       throw new incorrectMazeDimensionsException(worldWidth, worldHeight, mazeW, mazeH);
     }
     
     Character c;
     
     for(int i = 1; i < mazeH+1; i++){ // walls of maze
       line = lines[i];
       for(int j = 0; j < mazeW-1; j++){
         c = line.charAt(j);
         if (c == '-'){
           wallList.add(new Wall(1.25, 0.75, edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5, 0x000000));
         }
         
         else if (c == '|'){
           wallList.add(new Wall(0.75, 1.25, edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5, 0x000000));
         }
         else if (c == 'x'){
           createMazeEnd(edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5);
         }
         else if (c == '+'){
           createPlayerToken(edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5);
         }
       }
       if (PRINTMAZE) {
         System.out.println(line);
       }
     }
  
  return wallList;
}

void createMazeEnd(float x, float y){
    /* Finish Button */
  end = new FCircle(1.0);
  end.setPosition(x, y);
  end.setFill(200,0,0);
  end.setStaticBody(true);
  end.setSensor(true);
  world.add(end);
}

void createMaze(ArrayList<Wall> wallList) throws incorrectMazeDimensionsException{
  
  FBox wall;
  for(Wall item : wallList){
    /* creation of wall */
    wall = new FBox(item.getW(), item.getH());
    wall.setPosition(item.getX(), item.getY());
    wall.setStatic(true);
    int c = item.getColor();
    wall.setFill(c);
    world.add(wall);
  }
}

void createPlayerToken(float x, float y){
  /* Player circle */
  /* Setup the Virtual Coupling Contact Rendering Technique */
  playerToken = new HVirtualCoupling((0.75)); 
  playerToken.h_avatar.setDensity(4); 
  playerToken.h_avatar.setFill(random(255),random(255),random(255)); 
  playerToken.init(world, x, y); 
}

/* end helper functions section ****************************************************************************************/
