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

// imports
import java.util.*;
import java.text.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

// Maths constants
final float SIN60 = sin(radians(60));
final float COS60 = cos(radians(60));

// global variables
PImage pattern;
PImage cellColourMap;
Frame  frame, mirrorFrame;

float posZ = 0;
float posY = 0;

// list of bees
List<Agent> agents;
boolean     runAgents;

// sound related variables
Minim       minim;
AudioPlayer sound;
FFT         fft;
boolean     drawSpectrum = false;
float       wingNoise, wingNoiseMax;
float       hiveNoise, hiveNoiseMax;


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

  // load sound
  minim = new Minim(this);
  sound = minim.loadFile("Hive1.mp3");
  //sound.play();    // play once
  sound.loop(); // for continuous play
  
  // attach FFT analyser
  fft = new FFT(sound.bufferSize(), sound.sampleRate());
  
  // start
  restart(); 
  
  wingNoiseMax = 0.01;
  hiveNoiseMax = 0.01;

  runAgents = DEMO_MODE;
  if ( DEMO_MODE )
  {
    noCursor();
    posZ = 570;
    posY = -0.05;
  }
}



void draw()
{
  // analyse the sound
  fft.forward(sound.mix);
  
  // wing noise = average of 150-700 Hz bands
  float newWingNoise = fft.calcAvg(150, 700);           // (center bee-wing frequency ~200Hz) 
  wingNoiseMax       = max(wingNoiseMax, newWingNoise); // running maximum
  newWingNoise      /= wingNoiseMax;                    // normalise [0...1]
  wingNoise = lerp(wingNoise, newWingNoise, 0.1);       // avoid sharp value changes
  
  // hive noise = average of 5kHz-12kHz bands
  float newHiveNoise = fft.calcAvg(5000, 12000);
  hiveNoiseMax       = max(hiveNoiseMax, newHiveNoise); // running maximum
  newHiveNoise      /= hiveNoiseMax;                    // normalise [0...1]
  hiveNoise = lerp(hiveNoise, newHiveNoise, 0.1);       // avoid sharp value changes 
    

  // are the agents "moving"?
  if ( runAgents && (frameCount % FRAMES_PER_AGENT_MOVEMENT == 0) )
  {
    canMove  = true;
    storePos = false;
    
    for ( Agent a : agents ) 
    {
      a.sense();
    }
    for ( Agent a : agents ) 
    {
      a.decide();
    }
    for ( Agent a : agents ) 
    {
      a.act();
    }
  }
  
  if ( DEMO_MODE )
  {
    // reset hive after certain time
    if ( frameCount % (FRAMES_PER_SECOND * DEMO_RESET_TIME) == 0 )
    {
      restart();
    }
  }

  // clear screen
  background(0);

  if ( drawSpectrum )
  {
    // draw spectrum
    noStroke();
    final int barWidth = width / fft.specSize(); 
    for(int i = 0; i < fft.specSize() ; i++)
    {
      if ( i == mouseX / barWidth ) { fill(255, 0, 0); println(fft.indexToFreq(i) + "Hz"); }
      else                          { fill(255); }
      float intensity = fft.getBand(i) * height / 5;
      rect(i * barWidth, height - intensity, barWidth, intensity);
    }
    
    fill(0, 255,   0); rect(0,  0, width * wingNoise, 10);
    fill(0,   0, 255); rect(0, 10, width * hiveNoise, 10); 
  }
    
  if ( DEMO_MODE )
  {
    //automatic camera rotation
    translate(width / 2, (1 + posY) * (height / 2), posZ);
    rotateX(radians(45));
    rotateZ(radians((frameCount % 1000) * 360.0 / 1000.0));
  }
  else
  {
    // mouse position determines rotation
    translate(map(mouseX, 0,  width, width  * 2 / 4, width  * 2 / 4), 
              map(mouseY, 0, height, height * 1 / 4, height * 3 / 4),
              posZ);
    rotateX(map(mouseY, 0, height, 2, -2));
    rotateY(map(mouseX, 0, width, -2, 2));
  }
  
  // draw frame
  pushMatrix();
    translate(-frame.getWidth() / 2, -frame.getHeight() / 2);
    frame.render();
  popMatrix();
  
  // draw mirror frame
  if ( mirrorFrame != null )
  {
    translate(-mirrorFrame.getWidth() / 2, -mirrorFrame.getHeight() / 2);
    mirrorFrame.render();
  } 
}


void restart()
{
  FrameConfiguration conf = new FrameConfiguration(FRAME_WIDTH, FRAME_HEIGHT, CELL_DIAMETER, FRAME_DEPTH / 2);
  conf.mirrored = true;
  conf.cellRoughness = CELL_ROUGHNESS;
  if ( !DEMO_MODE ) 
  {
    conf.cellAngle = CELL_ANGLE; // no tilt for demo mode
  }

  frame = new Frame(conf); 
  mirrorFrame = null;
  
  // load image pattern
  pattern = loadImage("CellPattern1.png"); // hexagon picture
  pattern = loadImage("Triangle.png");
  //pattern = loadImage("CellPattern2.jpg"); // bee
  
  pattern.resize(frame.config.columns, frame.config.rows);

  // colour map for cells
  cellColourMap = loadImage("CellColourMap1.png");
  //cellColourMap = loadImage("CellColourMap2.png");
  cellColourMap.resize(256, 2);

  //generateCells(400);
    
  agents = new LinkedList<Agent>();
  int centreX = frame.config.columns / 2;
  int centreY = frame.config.rows    / 2;
  agents.add(new SyncDancer(new FramePos(frame, centreX, centreY),    0, true));
  agents.add(new SyncDancer(new FramePos(frame, centreX, centreY),  120, false));
  agents.add(new SyncDancer(new FramePos(frame, centreX, centreY), -120, false));
}


/**
 * Mirrors the existing frame.
 */
void toggleMirrorFrame()
{
  if ( mirrorFrame == null )
  {
    mirrorFrame = new Frame(frame);
  }
  else
  {
    // mirror already exists > destroy
    mirrorFrame = null;
  }  
}


/**
 * Generates random cells with intensity based on the background image.
 *
 * @param count  the number of cells to generate
 */
void generateCells(int count)
{
  for ( int i = 0 ; i < count ; i++ )
  {
    int x = (int) random(0, frame.config.columns);
    int y = (int) random(0, frame.config.rows);
    
    float b = brightness(pattern.get(x, y)) / 255.0;
    
    final boolean probabilityBased = true;
    if ( probabilityBased )
    {
      // Generate cells more likely for bright pixels
      if ( b > random(1) )
      {
        frame.createCell(x, y, 0.75);
      }
    }
    else
    {
       // Generate cells with different brightness
      frame.createCell(x, y, b);
    } 
  }  
}


/**
 * Saves the frame config as a JSON file.
 *
 * @param filename  the filename to save
 */
void saveJSON_File(String filename)
{  
  if ( saveJSONObject(frame.getJSON(), filename, "compact") )
  {
    println("JSON file '" + filename + "' created");
  }
}


/**
 * Saves the geometry as an STL file.
 *
 * @param filename  the filename to save
 */
void saveStlFile(String filename)
{  
  PrintWriter w = createWriter(filename);
  if ( w != null )
  {
    frame.writeSTL(w);
    
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
  switch ( key )
  {
    case ' ' : 
    {
      // pause and unpause agent activity
      runAgents = !runAgents; 
      break;    
    }
    
    case 'f' : 
    {
      // show/hide spectrum
      drawSpectrum = !drawSpectrum;            
      break;    
    }

    case 'j' : 
    {
      // save frame config as JSON file
      saveJSON_File("frame" + getTimestamp() + ".frm"); 
      break;
    }
    
    case 's' : 
    {
      // save screenshot
      saveFrame("screenshot" + getTimestamp() + ".png"); 
      break;
    }
    
    case 'p' : 
    {
      // save geometry as 3D-printable STL file
      saveStlFile("geometry" + getTimestamp() + ".stl"); 
      break;
    }
    
    case 'g' : 
    {
      // generate some random cells based on the background image 
      generateCells(100); 
      break;
    }
    
    case 'r' : 
    {
      // clear the frame and restart all agents
      restart(); 
      break;
    }
    
    case 'm' : 
    {
      // mirror the frame
      toggleMirrorFrame(); 
      break;
    }

    case CODED :
    {
      // special keys
      switch ( keyCode )
      {
        // cursor keys move centre of origin
        case UP   : posY -= 0.01; break;
        case DOWN : posY += 0.01; break;
      }
      
      break;
    }
  }
}


/**
 * Mouse wheel for zoom.
 */
void mouseWheel(MouseEvent event)
{
  posZ -= event.getCount() * 10;
}