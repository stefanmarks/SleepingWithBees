/**
 * Class for managing a frame position.
 */
public class FramePos
{
  public final Frame frame;
  public final int   x, y;

  
  public FramePos(Frame frame, int x, int y)
  {
    
    this.frame = frame;
    this.x = x;
    this.y = y; 
  }
  
  
  public boolean isValid()
  {
    return (x >= 0) && (x < frame.config.columns) && 
           (y >= 0) && (y < frame.config.rows); 
  }
  
  
  public FramePos getNeighbour(int angle)
  {
    // start here
    int nx = x;
    int ny = y;
    // convert angle to integer [0...5]
    // 30 degree is index 0
    angle -= 15;
    while ( angle >= 360 ) { angle -= 360; }
    while ( angle <  0   ) { angle += 360; } 
    angle /= 60;
    if ( this.y % 2 == 0 )
    {
      // even rows:
      switch ( angle )
      {
        case 0 : ny--; break;
        case 1 : nx++; break;
        case 2 : ny++; break;
        case 3 : nx--; ny++; break;
        case 4 : nx--; break;
        case 5 : nx--; ny--; break;
      }
    }
    else
    {
      // odd rows
      switch ( angle )
      {
        case 0 : nx++; ny--; break;
        case 1 : nx++; break;
        case 2 : nx++; ny++; break;
        case 3 : ny++; break;
        case 4 : nx--; break;
        case 5 : ny--; break;
      }
      
    }
    return new FramePos(frame, nx, ny); 
  }
  
  
  public boolean hasCell()
  {
    return frame.getCell(x, y) != null; 
  }
  
  
  public Cell getCell()
  {
    return frame.getCell(x, y); 
  }
  
  
  public Cell createCell()
  {
    return frame.createCell(x, y); 
  }
  
  
  public PVector getWorldPos()
  {
    PVector worldPos = new PVector();
    worldPos.x = x * 2;
    if ( y % 2 == 1 ) 
    {
      worldPos.x += 1; // odd row offset 
    }
    worldPos.x *= SIN60 * frame.config.cellRadius;
    worldPos.y  = (y + (frame.config.mirrored ? 0.666666666666 : 0)) * 0.75 * 2 * frame.config.cellRadius;
    return worldPos;
  }
  
}


/**
 * Class for managing a frame position AND a direction.
 */
public class FramePosDir extends FramePos
{
  final public int angle; 


  public FramePosDir(FramePos pos, int angle)
  {
    super(pos.frame, pos.x, pos.y);
    this.angle = angle;
  }
  

  public FramePosDir(Frame frame, int x, int y, int angle)
  {
    super(frame, x, y);
    this.angle = angle;
  }

  
  public FramePos getNeighbour()
  {
    return super.getNeighbour(angle);
  }
}