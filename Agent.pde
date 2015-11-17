/**
 * Interface for an agent that can sense, decide, and then act.
 */
public interface Agent
{
  /**
   * Sense the world around the agent.
   */
  public abstract void sense();
  
  /**
   * Decide on what action to take.
   */
  public abstract void decide();
  
  /**
   * Act on the decision made.
   */
  public abstract void act();
}


/**
 * Sync Dancer agent class.
 *
 * Creates agents that agree on a common movement angle, but with point symmetry applied.
 */
 
int     commonAngle = 0;
boolean canMove     = false;
boolean storePos    = false;

public class SyncDancer implements Agent
{
  public SyncDancer(FramePos start, int angleOffset, boolean master)
  {
    this.position    = start;
    this.angleOffset = angleOffset;
    this.master      = master;
    
    memory = new LinkedList<FramePosDir>();

    prevNoise = 0;

    start.createCell();
  }
  
  
  /**
   * Sense: Can you move?
   */
  public void sense()
  {
    nextPosition = position.getNeighbour(commonAngle + angleOffset);
    if ( !nextPosition.isValid() )
    {
      // Reached border of frame. That's it... 
      nextPosition = null;
      canMove      = false;
    }
    else if ( nextPosition.hasCell() && (random(100) < 50) )
    {
      // reached an already filled cell > 50% chance of "walking" over it.
      nextPosition = null;
      canMove      = false;
    }
  }
  
  
  /**
   * Decide what to do next.
   */
  public void decide()
  {
    if ( master )
    {
      if ( canMove )
      {
        // change directiopn based on wing noise change
        commonAngle += 400 * (wingNoise - prevNoise);
        prevNoise = wingNoise;
        
        //commonAngle += (int) random(-20, 20);
      }
      
      if ( random(100) < 10 )
      {
        // 10% chance of remembering this position 
        storePos = true;
      }
    }
      
    if ( storePos )
    {
      memory.addFirst(new FramePosDir(position, commonAngle));
    }    
  }
  
  
  public void act()
  {
    if ( canMove )
    {
      // if agent can move, move
      position     = nextPosition;
      nextPosition = null;
    }
    else
    {
      // agent needs to "remember"
      if ( !memory.isEmpty() )
      {
        // ...there was something...
        FramePosDir past = memory.removeFirst();
        position = past;
        nextPosition = null;

        if ( master )
        {
          // recalled a previous position, now change angle drastically
          commonAngle = past.angle + (int) random(-90, 90);
        }
      }
    }

    Cell cell = position.createCell();
    cell.addActivity(storePos ? 0.5 : 0);
  }
  
  boolean  master;
  FramePos position, nextPosition;
  int      angleOffset;
  
  float    prevNoise;
  
  Deque<FramePosDir> memory;
}