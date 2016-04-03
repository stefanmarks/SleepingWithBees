/**
 * Class for managing a rectangluar frame full of cells.
 */
class Frame
{
  final FrameConfiguration config;
  
  
  /**
   * Constructor for a frame with a given configuration.
   *
   * @param config  the frame configuration
   */
  Frame(FrameConfiguration config)
  {
    this.config = config; 
    cells = new Cell[config.rows][config.columns];
  }
  
  
  /**
   * Constructor for a frame to be read from a JSON file.
   *
   * @param o  the JSON object to read from
   */
  Frame(JSONObject o)
  {
    // read configuration
    this(new FrameConfiguration(o.getJSONObject("config")));
    // read cell data
    JSONArray arrCells = o.getJSONArray("cells");
    for ( int rowIdx = 0 ; rowIdx < config.rows ; rowIdx++ )
    {
      JSONArray arrRow = arrCells.getJSONArray(rowIdx);
      for ( int columnIdx = 0 ; columnIdx < config.columns ; columnIdx++ )
      {
        int activity = arrRow.getInt(columnIdx, 0);
        if ( activity > 0 )
        {
          // number > 0: cell exists with activity mapped to [1..9]
          createCell(columnIdx, rowIdx, map(activity, 1, 9, 0, 1));
        }
      }
      arrCells.setJSONArray(rowIdx, arrRow);
    }
  }
  
  
  /**
   * Constructor for a mirrored frame.
   *
   * @param source  the source frame
   */
  Frame(Frame source)
  {
    this(new FrameConfiguration(source.config));
    config.mirrored = !config.mirrored;
    
    for ( int y = 0 ; y < config.rows ; y++ )
    {
      for ( int x = 0 ; x < config.columns ; x++ )
      {
        if ( source.hasCell(x, y) )
        {
          Cell cell = createCell(x, y);
          cell.setActivity(source.getCell(x, y).getActivity());
        }
      }
    }
  }

  
  /**
   * Checks if a cell exists at a given position.
   *
   * @param x  the X position
   * @param y  the Y position
   *
   * @return <code>true</code> if there exists a cell at the given position
   */
  boolean hasCell(int x, int y)
  {
    return getCell(x, y) != null; 
  }
  

  /**
   * Retrieves the cell at a given position.
   *
   * @param x  the X position
   * @param y  the Y position
   *
   * @return the Cell instance at that position or <code>null</code> if there is no cell
   */
  Cell getCell(int x, int y)
  {
    if ( (x < 0) || (x >= config.columns) ||
         (y < 0) || (y >= config.rows) ) return null;
         
    return cells[y][x];  
  }


  /**
   * Creates a cell at a given position.
   *
   * @param x  the X position
   * @param y  the Y position
   *
   * @return the Cell instance at that position
   */
  Cell createCell(int x, int y)
  {
    Cell cell = getCell(x, y);
    if ( (cell == null) && 
         (x >= 0) && (x < config.columns) &&
         (y >= 0) && (y < config.rows) )
    {
      float heightVariation = config.cellRoughness * noise(x / 10.0, y / 10.0);
      cell = new Cell(new FramePos(this, x, y), heightVariation, config.cellRadius, config.cellDepth + heightVariation);
      cells[y][x] = cell;
    }
    return cell;
  }
  
  
  /**
   * Creates a cell at a given position with a specific activity.
   * The default activity is only set when the cell is actually created.
   * Any existing cell's activity is not changed.
   *
   * @param x         the X position
   * @param y         the Y position
   * @param activity  the default activity
   *
   * @return the Cell instance at that position
   */
  Cell createCell(int x, int y, float activity)
  {
    Cell cell = getCell(x, y);
    if ( cell == null )
    {
      cell = createCell(x, y);
      if ( cell != null ) 
      {
        cell.setActivity(activity);
      }
    }
    return cell;
  }
  
  
  /**
   * Gets the width of the frame in mm.
   *
   * @return width of the frame in mm
   */
  float getWidth()
  {
    return config.columns * 2 * SIN60 * config.cellRadius;
  }
  
  
  /**
   * Gets the height of the frame in mm.
   *
   * @return height of the frame in mm
   */
  float getHeight()
  {
    return config.rows * 1.5 * config.cellRadius; 
  }  

  
  /**
   * Renders all the cells.
   */   
  void render()
  {
    for ( Cell[] rows : cells )
    {
      for ( Cell cell : rows )
      {
        if ( cell != null ) cell.render();
      }
    }
  }
  
  
  /**
   * Gets the frame data as a JSON object.
   *
   * @return the JSON object with the frame data
   */
  JSONObject getJSON()
  {
    JSONObject o = new JSONObject();
    // write config data first
    o.setJSONObject("config", config.getJSON());
    // write cell data next
    JSONArray arrCells = new JSONArray();
    for ( int rowIdx = 0 ; rowIdx < config.rows ; rowIdx++ )
    {
      JSONArray arrRow = new JSONArray();
      for ( int columnIdx = 0 ; columnIdx < config.columns ; columnIdx++ )
      {
        Cell c = cells[rowIdx][columnIdx];
        // store activity as number between 1 and 9, and a missing cell as a 0
        int activity = 0;
        if ( c != null )
        {
          activity = (int) constrain(map(c.activity, 0, 1, 1, 9), 1, 9);
        }
        arrRow.append(activity);
      }
      arrCells.setJSONArray(rowIdx, arrRow);
    }
    o.setJSONArray("cells", arrCells);
    
    return o;
  }
  
  
  /**
   * Writes the cell data to an STL file.
   */
  void writeSTL(PrintWriter w)
  {
    w.println("solid Surface");
    for ( Cell[] rows : cells )
    {
      for ( Cell cell : rows )
      {
        if ( cell != null ) cell.writeSTL(w);
      }
    }
    w.println("endsolid");
  }
  
  
  // cell data
  private Cell[][] cells;
}