interface IProgramMode
{
  String getName();
  
  void initialise();
  void deinitialise();
  
  void    draw();
  boolean handleKeyPressed();
}


class ProgramMode_Intro implements IProgramMode, CallbackListener
{
  String getName()
  {
    return "Intro";
  }
  
  
  void initialise()
  {
    PFont buttonFont = createFont("Default", width / 30);
    
    int w = width / 2 - 200;
    btnGenerate = gui.addButton("Generate");
    btnGenerate.setPosition(100, 500).setSize(w, 80)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
      .getCaptionLabel().setFont(buttonFont)
    ;
    btnDemo = gui.addButton("Demo");
    btnDemo.setPosition(100, 650).setSize(w, 80)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
      .getCaptionLabel().setFont(buttonFont)
    ;

    btnLoadImage = gui.addButton("Load Image");
    btnLoadImage.setPosition(width / 2 + 100, 500).setSize(w, 80)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
      .getCaptionLabel().setFont(buttonFont)
    ;
    btnLoadFrame = gui.addButton("Load Frame");
    btnLoadFrame.setPosition(width / 2 + 100, 650).setSize(w, 80)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
      .getCaptionLabel().setFont(buttonFont)
    ;
  }
  
  
  void deinitialise()
  {
  }
  
  
  void draw()
  {
    background(0);
    
    textAlign(CENTER, CENTER);
    int h = height / 6;
    int y = h;
    int x = width / 2;
    
    textSize(width / 15);
    fill(getCellColour(1, true));
    text(PROGRAM_TITLE + " - v" + PROGRAM_VERSION, x, y); y+= h;
    
    fill(getCellColour(1, false));
    textSize(width / 30);
    text("© 2015/2016 Stefan Marks & Gerbrand van Melle", x, y); y+= h; 
  }
  
  
  boolean handleKeyPressed()
  {
    return false;
  }
  
  
  void controlEvent(CallbackEvent theEvent) 
  {
    Button btnSource = (Button) theEvent.getController();
    if      ( btnSource == btnDemo      ) { switchProgramMode(ProgramMode.DEMO); }
    else if ( btnSource == btnGenerate  ) { switchProgramMode(ProgramMode.GENERATE); }
    else if ( btnSource == btnLoadImage ) { switchProgramMode(ProgramMode.LOAD_IMAGE); }
    else if ( btnSource == btnLoadFrame ) { switchProgramMode(ProgramMode.LOAD_FRAME); }
  }
  

  Button btnDemo, btnGenerate, btnLoadFrame, btnLoadImage;
}




class ProgramMode_Generate implements IProgramMode, CallbackListener
{
  ProgramMode_Generate(boolean demo)
  {
    this.demoMode = demo;
  }
  
  
  String getName()
  {
    return demoMode ? "DemoMode" : "Generate";
  }
  
  
  void initialise()
  {
    // load sound
    sound = minim.loadFile("Hive1.mp3");
    sound.loop(); // for continuous play
  
    // attach FFT analyser
    fft = new FFT(sound.bufferSize(), sound.sampleRate());
  
    wingNoiseMax = 0.01;
    hiveNoiseMax = 0.01;
    
    if ( demoMode )
    {
      noCursor();
      setGUI_Visibility(false);
      cameraPos.y = -0.05;
      cameraPos.z = 570;
    }    

    // GUI elements
    sldWingNoise = gui.addSlider("Wing Noise")
      .setSize(width - 200, GUI_VSIZE)
      .setRange(0, 1)
      .setVisible(false);
    ;
    sldHiveNoise = gui.addSlider("Hive Noise")
      .setSize(width - 200, GUI_VSIZE)
      .setRange(0, 1)
      .setVisible(false);
    ;
    lblFrequency = gui.addTextlabel("Frequency")
      .setValue("")
      .setVisible(false);
    ;
    addControlL(sldWingNoise); addControlL(sldHiveNoise); addControlL(lblFrequency);

    btnShowSpectrum = gui.addToggle("Show Spectrum")
      .setSize(100, GUI_VSIZE)
      .setValue(false)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
    ;
    btnShowSpectrum.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
    addControlR(btnShowSpectrum);

    btnGenerate = gui.addToggle("Generate")
      .setSize(100, GUI_VSIZE)
      .setValue(demoMode)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
    ;
    btnGenerate.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
    addControlR(btnGenerate);
    
    btnRestart = gui.addButton("Restart")
      .setSize(100, GUI_VSIZE)
      .addListenerFor(ControlP5.ACTION_CLICK, this)
    ;
    btnRestart.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
    addControlR(btnRestart);
    
    restart();
  }
  
  
  void deinitialise()
  {
    sound.pause();
    sound = null;
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
    if ( btnGenerate.getBooleanValue() && (frameCount % FRAMES_PER_AGENT_MOVEMENT == 0) )
    {
      canMove  = true;
      storePos = false;
      
      for ( Agent a : agents ) 
      {
        if ( a instanceof SyncDancer )
        {
          ((SyncDancer) a).setWingNoise(wingNoise);
        }
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

    background(0);

    if ( btnShowSpectrum.getBooleanValue() )
    {
      // draw spectrum
      noStroke();
      lblFrequency.setValue("");
      final int barWidth = width / fft.specSize(); 
      for ( int i = 0; i < fft.specSize() ; i++ )
      {
        float intensity = fft.getBand(i) / 10;
        int   barHeight = (int) (intensity * height);
        if ( i == mouseX / barWidth )
        { 
          // mouseX indicates which frequency is at that spectrum position
          fill(getCellColour(intensity, true)); 
          lblFrequency.setValue("Frequency: " + ((int) fft.indexToFreq(i)) + "Hz"); 
        }
        else                          
        { 
          fill(getCellColour(intensity, false)); 
        }
        rect(i * barWidth, height - barHeight, barWidth, barHeight);
      }
      
      sldWingNoise.setValue(wingNoise);
      sldHiveNoise.setValue(hiveNoise); 
    }
    
    if ( demoMode )
    {
      // reset hive after certain time
      if ( frameCount % (FRAMES_PER_SECOND * DEMO_RESET_TIME) == 0 )
      {
        restart();
      }

      //automatic camera rotation
      translate(width / 2, (1 + cameraPos.y) * (height / 2), cameraPos.z);
      rotateX(radians(45));
      rotateZ(radians((frameCount % 1000) * 360.0 / 1000.0));
    }
    else
    {
      applyStandardFrameTransformation();
    }

    drawFrames();
  }
  
  
  void restart()
  {
    FrameConfiguration conf = new FrameConfiguration(FRAME_WIDTH, FRAME_HEIGHT, CELL_DIAMETER, FRAME_DEPTH / 2);
    conf.mirrored = true;
    conf.cellRoughness = CELL_ROUGHNESS;
    if ( !demoMode ) 
    {
      conf.cellAngle = CELL_ANGLE; // no tilt for demo mode
    }
    primaryFrame = new Frame(conf);
    
    // create dancing bees
    agents = new LinkedList<Agent>();
    int centreX = primaryFrame.config.columns / 2;
    int centreY = primaryFrame.config.rows    / 2;
    agents.add(new SyncDancer(new FramePos(primaryFrame, centreX, centreY),    0, true));
    agents.add(new SyncDancer(new FramePos(primaryFrame, centreX, centreY),  120, false));
    agents.add(new SyncDancer(new FramePos(primaryFrame, centreX, centreY), -120, false));
  }


  void runAgents(boolean run)
  {
    if ( btnGenerate.getBooleanValue() != run )
    {
      btnGenerate.setValue(run);
    }
  }  
  
  
  void showSpectrum(boolean show)
  {
    if ( btnShowSpectrum.getBooleanValue() != show )
    {
      btnShowSpectrum.setValue(show);
    }
    sldWingNoise.setVisible(show);
    sldHiveNoise.setVisible(show);
    lblFrequency.setVisible(show);
  }
  
  
  boolean handleKeyPressed()
  {
    boolean keypressHandled = false;
    
    switch ( key )
    {
      case ' ' : 
      {
        // pause and unpause agent activity
        runAgents(!btnGenerate.getBooleanValue()); 
        keypressHandled = true;
        break;    
      }      

      case 'f' : 
      {
        // show/hide spectrum
        showSpectrum(!btnShowSpectrum.getBooleanValue());
        keypressHandled = true;
        break;
      }
      
      case 'r' : 
      {
        // clear the frame and restart all agents
        restart(); 
        keypressHandled = false;
        break;
      }      

    }

    return keypressHandled;
  }
  
  
  void controlEvent(CallbackEvent theEvent) 
  {
    if ( theEvent.getController() == btnShowSpectrum )
    {
      showSpectrum(btnShowSpectrum.getBooleanValue());
    }
    if ( theEvent.getController() == btnRestart )
    {
      restart();
    }
  }
  

  AudioPlayer sound;
  FFT         fft;
  float       wingNoise, wingNoiseMax;
  float       hiveNoise, hiveNoiseMax;
  List<Agent> agents;
  boolean     demoMode;

  Slider      sldWingNoise, sldHiveNoise;
  Textlabel   lblFrequency;
  Toggle      btnShowSpectrum, btnGenerate;
  Button      btnRestart;
}



public class ProgramMode_LoadImage implements IProgramMode, CallbackListener
{
  ProgramMode_LoadImage()
  {
    // nothing else to do
    activeRow = 0;
  }
  
  
  String getName()
  {
    return "Load Image";
  }
  
  
  void initialise()
  {
    selectInput("Please select the Image file to load:", "fileSelected", sketchFile("data/."), this);
    
    sldThreshold = gui.addSlider("Threshold")
      .setSize(200, 20)
      .setRange(0, 1)
      .setValue(0.5)
    ;
    addControlL(sldThreshold);
  }


  public void fileSelected(File selection) 
  {
    if ( selection != null )
    {
      // load image pattern
      cellPattern = loadImage(selection.toString()); 
    }

    if ( cellPattern != null )
    {
      println("Loaded image file '" + selection + "'");
      
      FrameConfiguration conf = new FrameConfiguration(FRAME_WIDTH, FRAME_HEIGHT, CELL_DIAMETER, FRAME_DEPTH / 2);
      conf.mirrored = true;
      conf.cellRoughness = CELL_ROUGHNESS;
      primaryFrame = new Frame(conf); 
      cellPattern.resize(primaryFrame.config.columns, primaryFrame.config.rows);
    }
    else
    {
      switchProgramMode(ProgramMode.INTRO);
    }
  }
  
  
  void deinitialise()
  {
    // nothing to do here
  }
  
  
  void draw()
  {
    if ( primaryFrame == null ) return;
    
    // update row by row
    generateCells(activeRow);
    activeRow = (activeRow + 1) % primaryFrame.config.rows;
    
    // draw the frame
    background(0);
    applyStandardFrameTransformation();
    drawFrames();
  }
  
  
  /**
   * Generates random cells with intensity based on the background image.
   *
   * @param row  the row to generate Cells for
   */
  void generateCells(int row)
  {
    for ( int x = 0 ; x < primaryFrame.config.columns ; x++ )
    {
      float b = brightness(cellPattern.get(x, row)) / 255.0;

      // Generate cells with different brightness
      if ( b < sldThreshold.getValue() ) 
      {
        // remove cell
        if ( primaryFrame.getCell(x, row) != null )
        {
          primaryFrame.removeCell(x, row);
        }
      }
      else 
      {
        Cell c = primaryFrame.createCell(x, row);
        c.setActivity(b);
      }
    }  
  }
  
  
  boolean handleKeyPressed()
  {
    // no keys handled
    return false;
  }
  
  
  void controlEvent(CallbackEvent theEvent) 
  {
    // no events handled
  }
  

  PImage cellPattern;
  int    activeRow;
  Slider sldThreshold;
}



public class ProgramMode_LoadFrame implements IProgramMode, CallbackListener
{
  ProgramMode_LoadFrame()
  {
    // nothing else to do
  }
  
  
  String getName()
  {
    return "Load Frame";
  }
  
  
  void initialise()
  {
    selectInput("Please select the Frame File to load:", "fileSelected", sketchFile("data/."), this);
  }
  
  
  void deinitialise()
  {
    // nothing to do here
  }
  
  
  public void fileSelected(File selection) 
  {
    if ( selection != null )
    {
      JSONObject obj = loadJSONObject(selection);
      primaryFrame = new Frame(obj);
    }
    
    if ( primaryFrame != null )
    {
      println("Loaded frame file '" + selection + "'");
    }
    else
    {
      switchProgramMode(ProgramMode.INTRO);
    }
  }
  
  
  void draw()
  {
    background(0);
    applyStandardFrameTransformation();
    drawFrames();
  }
  
  
  boolean handleKeyPressed()
  {
    // no keypresses to handle
    return false;
  }
  
  
  void controlEvent(CallbackEvent theEvent) 
  {
    // nothing to do here
  }
}