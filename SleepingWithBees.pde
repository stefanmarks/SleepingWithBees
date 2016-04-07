/**
 * Sketch for creating honeycomb frames based on sound.
 *
 * @author Gerbrand van Melle
 * @author Stefan Marks
 *
 * http://en.wikipedia.org/wiki/Honeycomb
 * http://www.dusd.net/jdelatorre/2014/03/10/honeybees-a-honeycomb-by-any-other-shape-is-not-a-honeycomb/
 * http://physicsworld.com/cws/article/news/2014/sep/10/fractal-like-honeycombs-take-the-strain
 */

// program name and version
final String PROGRAM_TITLE   = "Sleeping With Bees";
final String PROGRAM_VERSION = "2.0";

// imports
import java.util.*;
import java.text.*;
import javax.swing.*;
import javax.swing.filechooser.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import controlP5.*;

// Maths constants
final float SIN60 = sin(radians(60));
final float COS60 = cos(radians(60));

// GUI constants
final int GUI_VSPACE = 10; // default vertical GUI element spacing
final int GUI_VSIZE  = 15; // default vertical GUI element size

// global variables
ControlP5 gui;                       // GUI
boolean   hideGUI;                   // flag for hiding the gui
int       leftGUI_Y,rightGUI_Y;      // Y positions of GUI elements (trivial layout manegement)
Button    btnSaveSTL, btnSaveJSON;   // common buttons for saving files
Toggle    btnMirror;                 // mirror button
Button    btnMenu;                   // return to menu

Minim     minim;                     // Sound system
Frame     primaryFrame, mirrorFrame; // Frames of cells and the mirrored frame
PImage    cellColourMap;             // colour scheme
PVector   cameraPos, frameRotation;  // camera position and frame rotation



// Program modes
enum ProgramMode
{
  INTRO, DEMO, GENERATE, LOAD_IMAGE, LOAD_FRAME;
}

ProgramMode  currentMode, newMode;
IProgramMode programMode;

java.awt.Component mainComponent;


void settings()
{
  if ( DEMO_MODE ) 
  {
    fullScreen(P3D);
  }
  else 
  {
    size(1024, 800, P3D);
  }
}


void setup()
{
  smooth();
  strokeWeight(1);
  frameRate(FRAMES_PER_SECOND);

  minim = new Minim(this);
  gui   = new ControlP5(this);
  
  cameraPos     = new PVector();
  frameRotation = new PVector();
  hideGUI       = false;
  
  // start
  setColourScheme();
  programMode = null;
  switchProgramMode(ProgramMode.INTRO);
}


void switchProgramMode(ProgramMode mode)
{
  newMode = mode;
}


/**
 * Rendersa single frame.
 */
void draw()
{
  // has program mode changed?
  if ( newMode != currentMode )
  {
    // if yes, deactivate old mode
    if ( programMode != null )
    {
      programMode.deinitialise();
      programMode = null;
    }
    
    // remove all GUI elements
    List<ControllerInterface<?>> list = gui.getAll();
    for ( ControllerInterface ci : list )
    {
      gui.remove(ci.getName());
    }
    setGUI_Visibility(true);
  
    // delete frames
    primaryFrame = null;
    mirrorFrame  = null;
    
    // reset some settings
    cursor();
    cameraPos.z = 500;
    leftGUI_Y  = 10;
    rightGUI_Y = 10;
    
    // switch to new program mode
    switch ( newMode )
    {
      case DEMO       : programMode = new ProgramMode_Generate(true); break;
      case GENERATE   : programMode = new ProgramMode_Generate(false); break;
      case LOAD_IMAGE : programMode = new ProgramMode_LoadImage(); break;
      case LOAD_FRAME : programMode = new ProgramMode_LoadFrame(); break;
      default         : programMode = new ProgramMode_Intro(); break;
    }
    
    if ( programMode != null )
    {
      programMode.initialise();
      // println("Switched to program mode '" + programMode.getName() + "'");
    }
    
    currentMode = newMode;

    
    // add common GUI elements
    if ( currentMode != ProgramMode.INTRO )
    {
      rightGUI_Y += GUI_VSPACE;
  
      btnMirror = gui.addToggle("Mirror")
        .setSize(100, GUI_VSIZE)
      ;
      btnMirror.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
      addControlR(btnMirror);
  
      rightGUI_Y += GUI_VSPACE;
      btnSaveSTL = gui.addButton("Save STL")
        .setSize(100, GUI_VSIZE)
      ;
      btnSaveSTL.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
      addControlR(btnSaveSTL);
      
      btnSaveJSON = gui.addButton("Save JSON")
        .setSize(100, GUI_VSIZE)
      ;
      btnSaveJSON.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
      addControlR(btnSaveJSON);

      rightGUI_Y += GUI_VSPACE;
  
      btnMenu = gui.addButton("Back to Menu")
        .setSize(100, GUI_VSIZE)
      ;
      btnMenu.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
      addControlR(btnMenu);  
    }
    
    gui.addFrameRate().setInterval(10).setPosition(width - 30, height - 20);
  }
  
  
  hint(ENABLE_DEPTH_TEST);   

  pushMatrix();
  pushStyle();
  
  if ( programMode != null )
  {
    programMode.draw();
  }

  popStyle();
  popMatrix();

  // don't hide GUI with 3D content
  hint(DISABLE_DEPTH_TEST);   
}


void addControlL(ControllerInterface ci)
{
 ci.setPosition(10, leftGUI_Y);
 leftGUI_Y += ci.getHeight() + GUI_VSPACE; 
}


void addControlR(ControllerInterface ci)
{
 ci.setPosition(width - 10 - ci.getWidth(), rightGUI_Y);
 rightGUI_Y += ci.getHeight() + GUI_VSPACE; 
}


void controlEvent(CallbackEvent theEvent)
{
  if (theEvent.getAction() == ControlP5.ACTION_PRESS )
  {
    controlP5.Controller src = theEvent.getController();
    if      ( src == btnSaveSTL  ) { saveStlFile(); }
    else if ( src == btnSaveJSON ) { saveJSON_File(); }
    else if ( src == btnMirror   ) { enableMirrorFrame(btnMirror.getBooleanValue()); }
    else if ( src == btnMenu     ) { switchProgramMode(ProgramMode.INTRO); }
  }
}


void applyStandardFrameTransformation()
{
  // mouse position determines rotation
  translate(map(frameRotation.y, -90, 90, width  * 3 / 8, width  * 5 / 8), 
            map(frameRotation.x, -90, 90, height * 5 / 8, height * 3 / 8),
            cameraPos.z);
  rotateX(radians(frameRotation.x));
  rotateY(radians(frameRotation.y));
}


/**
 * Draws the frame and mirror frame.
 */
void drawFrames()
{
  if ( primaryFrame != null )
  {
    pushMatrix();
      translate(-primaryFrame.getWidth() / 2, -primaryFrame.getHeight() / 2);
      primaryFrame.render();
    popMatrix();
  }
  
  // draw mirror frame
  if ( mirrorFrame != null )
  {
    translate(-mirrorFrame.getWidth() / 2, -mirrorFrame.getHeight() / 2);
    mirrorFrame.render();
  } 
}


/**
 * Mirrors the existing frame.
 *
 * @param enable  <code>true</code> to enable the mirror
 */
void enableMirrorFrame(boolean enable)
{
  if ( enable && (mirrorFrame == null) )
  {
    mirrorFrame = new Frame(primaryFrame);
  }
  else if ( !enable )
  {
    // destroy mirror frame
    mirrorFrame = null;
  }  
  
  if ( btnMirror.getBooleanValue() != enable )
  {
    btnMirror.setValue(enable);
  }
}


void setGUI_Visibility(boolean visible)
{
  if ( visible ) gui.show();
  else           gui.hide();
  hideGUI = !visible;
}


/**
 * Determines the colour scheme of the cells.
 */ 
void setColourScheme()
{
  // colour map for cells
  cellColourMap = loadImage("CellColourMap1.png");
  //cellColourMap = loadImage("CellColourMap2.png");
  cellColourMap.resize(256, 2);
  
  // set colour scheme for buttons as well
  gui.setColorBackground(  getCellColour(0.75, false));
  gui.setColorForeground(  getCellColour(1.00, false));
  gui.setColorActive(      getCellColour(0.5, true));
  gui.setColorCaptionLabel(getCellColour(1, true));
  gui.setColorValueLabel(  getCellColour(1, true));
}  


color getCellColour(float activity, boolean primaryColour)
{
  activity = constrain(activity, 0, 1);
  int x = (int) map(activity, 0, 1, 0, 255); // map activity to pixel
  int y = primaryColour ? 1 : 0; // lower row is brighter = primary colour
  return cellColourMap.get(x, y);
}


/**
 * Saves the frame config as a JSON file.
 */
void saveJSON_File()
{  
  if ( primaryFrame == null ) return;

  String filename = "./data/frame" + getTimestamp() + ".frm";
  if ( saveJSONObject(primaryFrame.getJSON(), filename /*, "compact"*/) )
  {
    println("JSON file '" + filename + "' created");
  }
}


/**
 * Saves the geometry as an STL file.
 */
void saveStlFile()
{ 
  if ( primaryFrame == null ) return;
  
  String filename = "./data/geometry" + getTimestamp() + ".stl";
  PrintWriter w = createWriter(filename);
  if ( w != null )
  {
    primaryFrame.writeSTL(w);
    
    if ( mirrorFrame != null )
    {
      mirrorFrame.writeSTL(w);
    }
    
    w.close();
    println("STL file '" + filename + "' created");
  }  
}


/**
 * Creates a string with the current time, e.g., for filename sorting.
 *
 * @return timestamp string
 */
String getTimestamp()
{
  return new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
}


/**
 * Called when a key is pressed.
 */
void keyPressed()
{
  if ( (programMode == null) || !programMode.handleKeyPressed() )
  {
    switch ( key )
    {
      case 'g' : // Hide/Show GUI
      {
        if ( currentMode != ProgramMode.INTRO )
        {
          setGUI_Visibility(hideGUI);
        }
        break;
      }
      
      case 'j' : 
      {
        // save frame config as JSON file
        saveJSON_File(); 
        break;
      }
      
      case 's' : 
      {
        // save screenshot
        saveFrame("./data/screenshot" + getTimestamp() + ".png"); 
        break;
      }
      
      case 'p' : 
      {
        // save geometry as 3D-printable STL file
        saveStlFile(); 
        break;
      }
      
      case 'm' : 
      {
        // mirror the frame
        enableMirrorFrame(!btnMirror.getBooleanValue());
        break;
      }
  
      case ESC : 
      {
        // return to Intro mode, otherwise quit
        if ( currentMode != ProgramMode.INTRO )
        {
          switchProgramMode(ProgramMode.INTRO); 
          key = 0;
        }
        break;
      }
  
      case CODED :
      {
        // special keys
        switch ( keyCode )
        {
          // cursor keys move centre of origin
          case UP   : cameraPos.y -= 0.01; break;
          case DOWN : cameraPos.y += 0.01; break;
        }
        
        break;
      }
    }
  }
}


/**
 * Mouse drag for rotating the frame.
 */
void mouseDragged(MouseEvent event)
{
  if ( !gui.isMouseOver() ) 
  {
    // only move frame when mouse is not over GUI element
    frameRotation.x = constrain(frameRotation.x + (pmouseY - mouseY) * 180.0 / height, -90, 90);
    frameRotation.y = constrain(frameRotation.y - (pmouseX - mouseX) * 180.0 / width,  -90, 90);
  }
}


/**
 * Mouse wheel for zoom.
 */
void mouseWheel(MouseEvent event)
{
  if ( !gui.isMouseOver() ) 
  {
    // only move camera when mouse is not over GUI element
    cameraPos.z -= event.getCount() * 10;
  }
}