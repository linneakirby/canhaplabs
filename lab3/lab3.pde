/**
 **********************************************************************************************************************
 * @file       lab3.pde
 * @author     Linnea Kirby, Sri Gannavarapu
 * @version    V4.1.0
 * @date       12-March-2021
 * @brief      based off of "sketch_4_Wall_Physics" by Steve Ding, Colin Gallacher
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
import controlP5.*;
/* end library imports *************************************************************************************************/

/* user-set parameters ***********/
public final boolean DEBUG = true;
/* end user-set parameters **********/

/* scheduler definition ************************************************************************************************/
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/



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
float             worldWidth                          = 25.0;  
float             worldHeight                         = 10.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;


/* Initialization of wall */
FBox              wall;


/* Initialization of virtual tool */
HVirtualCoupling  s;
PImage            haplyAvatar;

ControlP5 cp5;
Boolean mislead = false;
/* end elements definition *********************************************************************************************/



/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */

  /* screen size definition */
  size(1000, 400);

  /* device setup */

  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem14201", 0);
   */
  haplyBoard = new Board(this, "/dev/cu.usbmodem14201", 0);
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


  /* Haptic Tool Initialization */
  s                   = new HVirtualCoupling((1)); 
  s.h_avatar.setDensity(4);  
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 


  /* If you are developing on a Mac users must update the path below 
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png" 
   */
  haplyAvatar = loadImage("./img/Haply_avatar.png"); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
  s.h_avatar.attachImage(haplyAvatar); 


  /* world conditions setup */
  world.setGravity((0.0), (1000.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0.5);

  cp5 = new ControlP5(this);
  cp5.addButton("mislead").setLabel("First Word").setPosition(40, 40);
  cp5.addButton("secondWord").setLabel("Second Word").setPosition(40, 60);
  cp5.addButton("thirdWord").setLabel("Third Word").setPosition(40, 80);


  world.draw();


  /* setup framerate speed */
  frameRate(baseFrameRate);


  /* setup simulation thread to run at 1kHz */
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/

float[] positionArr = new float[2];

/* draw section ********************************************************************************************************/
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if (renderingForce == false) {
    background(255);
    
    if(mislead){
     positionArr = checkPosition(positionArr);
     
    }
    
    
    
    world.draw();
  }
}
/* end draw section ****************************************************************************************************/



/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable {

  public void run() {
    hapticSimulationStep();
  }
}
/* end simulation section **********************************************************************************************/

/* helper functions section, place helper functions here ***************************************************************/

void controlEvent(CallbackEvent event) {
  if (event.getAction() == ControlP5.ACTION_CLICK) {
    switch(event.getController().getAddress()) {
    case "/mislead":
      if (DEBUG) {
        println("Button First Word Pressed");
      }
      mislead = true;
      beginMislead();
      break;
    case "/secondWord":
      if (DEBUG) {
        println("Button Second Word Pressed");
      }
      clearMislead();
      break;
    case "/thirdWord":
      if (DEBUG) {
        println("Button Third Word Pressed");
      }
      clearMislead();
      break;
    }
  }
}

void checkDirection(

void beginMislead() {
  createWall();
}

void clearMislead() {
  world.remove(wall);
}

void createWall() {
  /* creation of wall */
  wall                   = new FBox(width, 0.5);
  wall.setPosition(edgeTopLeftX, edgeTopLeftY+2*worldHeight/3.0);
  wall.setStatic(true);
  wall.setFill(0, 0, 0);
  world.add(wall);
}

void hapticSimulationStep() {
  /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */

  renderingForce = true;

  if (haplyBoard.data_available()) {
    getEndEffectorState();
  }

  s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 


  s.updateCouplingForce();
  fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
  fEE.div(100000); //dynes to newtons

  torques.set(widgetOne.set_device_torques(fEE.array()));
  widgetOne.device_write_torques();

  world.step(1.0f/1000.0f);

  renderingForce = false;
}

void getEndEffectorState() {
  /* GET END-EFFECTOR STATE (TASK SPACE) */
  widgetOne.device_read_data();

  angles.set(widgetOne.get_device_angles()); 
  posEE.set(widgetOne.get_device_position(angles.array()));
  posEE.set(posEE.copy().mult(200));
}




/* end helper functions section ****************************************************************************************/
