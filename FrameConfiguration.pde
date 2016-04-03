/**
 * Class for the configuration of a frame.
 */
class FrameConfiguration
{
  int     rows, columns;
  float   cellRadius, cellDepth, cellAngle, cellRoughness;
  boolean mirrored;
  
  
  /**
   * Constructor with basic data.
   * 
   * @param frameWidth    the width  of the frame in mm
   * @param frameHeight   the height of the frame in mm
   * @param cellDiameter  the diameter of each cell in mm
   * @param cellDepth     the depth of each cell in mm
   */
  FrameConfiguration(float frameWidth, float frameHeight, float cellDiameter, float cellDepth)
  {
    this.columns       = (int) (frameWidth  / (cellDiameter * SIN60)); 
    this.rows          = (int) (frameHeight / (cellDiameter * 0.75));
    this.cellRadius    = cellDiameter / 2;
    this.cellDepth     = cellDepth;
    this.cellAngle     = 0;
    this.cellRoughness = 0;
    this.mirrored      = false;
  }
  
  
  /**
   * Copy constructor.
   * 
   * @param source  the source configuration
   */
  FrameConfiguration(FrameConfiguration source)
  {
    rows          = source.rows;
    columns       = source.columns;
    cellRadius    = source.cellRadius;
    cellDepth     = source.cellDepth;
    cellAngle     = source.cellAngle;
    cellRoughness = source.cellRoughness;
    mirrored      = source.mirrored;
  }
  
  
  /**
   * Constructor reading data from a JSON object.
   * 
   * @param o the JSON object
   */
  FrameConfiguration(JSONObject o)
  {
    rows    = o.getInt("rows");
    columns = o.getInt("columns");
    
    cellRadius    = o.getFloat("radius",    CELL_DIAMETER / 2);
    cellDepth     = o.getFloat("depth",     FRAME_DEPTH);
    cellAngle     = o.getFloat("angle",     CELL_ANGLE);
    cellRoughness = o.getFloat("roughness", CELL_ROUGHNESS);
    
    mirrored = false;
  }


  /**
   * Stores the frame configuration in a JSON object.
   *
   * @return the JSON object with the configuration
   */
  JSONObject getJSON()
  {
    JSONObject o = new JSONObject();
    o.setInt("rows", rows);
    o.setInt("columns", columns);
    
    o.setFloat("radius",    cellRadius);
    o.setFloat("depth",     cellDepth);
    o.setFloat("angle",     cellAngle);
    o.setFloat("roughness", cellRoughness);
    
    return o;
  }  

}