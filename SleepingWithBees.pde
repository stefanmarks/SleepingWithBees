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

import java.util.*;
import java.text.*;
import ddf.minim.analysis.*;
import ddf.minim.*;


final float SIN60 = sin(radians(60));
final float COS60 = cos(radians(60));

final float CELL_ROUGHNESS = 4; 

PImage pattern;
Frame  frame;

float posZ = 0;

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


void setup()
{
  size(1024, 800, P3D);
  //fullScreen(P3D);
  
  smooth();
  strokeWeight(1);

  // load sound
  minim = new Minim(this);
  sound = minim.loadFile("Hive1.mp3");
  sound.play();    // play once
  // sound.loop(); // for continuous play
  
  // attach FFT analyser
  fft = new FFT(sound.bufferSize(), sound.sampleRate());
  
  // start
  restart(); 
  
  wingNoiseMax = 0.01;
  hiveNoiseMax = 0.01;
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
  if ( runAgents && (frameCount % 5 == 0) )
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
    
  // draw frame
  translate(map(mouseX, 0,  width, width  * 1 / 4, width  * 3 / 4), 
            map(mouseY, 0, height, height * 1 / 4, height * 3 / 4),
            posZ);
  rotateX(map(mouseY, 0, height, 2, -2));
  rotateY(map(mouseX, 0, width, -2, 2));
  translate(-frame.width/2, -frame.height/2);
  frame.render();
  
}


void restart()
{
  // load image pattern
  
  // Typical beehive frame is 480mm x 240mm, 29mm deep
  // numbers based on https://en.wikipedia.org/wiki/Langstroth_hive\
  // should average ~7000 cells
  // http://www.beesource.com/forums/archive/index.php/t-230451.html

  final float FRAME_WIDTH   = 480;
  final float FRAME_HEIGHT  = 240;
  final float FRAME_DEPTH   = 28;  
  final float CELL_DIAMETER = 6.235; // 5.4mm from flat side to flat side, -> diameter is 5.4mm / sin(60) = 6.235mm
  final float CELL_SIZE     = CELL_DIAMETER * SIN60;
  
  frame = new Frame((int) (FRAME_WIDTH / CELL_SIZE), 
                    (int) (FRAME_HEIGHT / (CELL_DIAMETER * 0.75)),
                    CELL_DIAMETER / 2, 
                    FRAME_DEPTH / 2); // Cells horiz, Cells vert, Cell radius in units, Cell depth in units 
  
  pattern = loadImage("CellPattern1.png"); // hexagon picture
  //pattern = loadImage("CellPattern2.jpg"); // bee
  
  pattern.resize(frame.sizeX, frame.sizeY);

  //generateCells(400);
    
  agents = new LinkedList<Agent>();
  agents.add(new SyncDancer(new FramePos(frame, frame.sizeX/2, frame.sizeY/2),    0, true));
  agents.add(new SyncDancer(new FramePos(frame, frame.sizeX/2, frame.sizeY/2),  120, false));
  agents.add(new SyncDancer(new FramePos(frame, frame.sizeX/2, frame.sizeY/2), -120, false));
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
    int x = (int) random(0, frame.sizeX);
    int y = (int) random(0, frame.sizeY);
    
    float b = brightness(pattern.get(x, y)) / 255.0;
    
    final boolean probabilityBased = true;
    if ( probabilityBased )
    {
      // Generate cells more likely for bright pixels
      if ( b > random(1) )
      {
        Cell c = frame.createCell(x, y);
        c.activity = 0.75;
      }
    }
    else
    {
       // Generate cells with different brightness
      Cell c = frame.createCell(x, y);
      c.activity = b;
    } 
  }  
}


/**
 * Saves th gemoetry as an STL file.
 *
 * @param filename  the filename to save
 */
void saveStlFile(String filename)
{  
  PrintWriter w = createWriter(filename);
  if ( w != null )
  {
    frame.writeSTL(w);
    w.close();
    println("STL file created");
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
  }
}


/**
 * Mouse wheel for zoom.
 */
void mouseWheel(MouseEvent event)
{
  posZ -= event.getCount() * 10;
}