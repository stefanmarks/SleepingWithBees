/**
 * Class for managing a rectangluar frame full of cells.
 */
class Frame
{
  final int     sizeX, sizeY;
  final float   cellRadius, cellDepth;

  final float   height, width;
  final boolean mirrored;
  
  /**
   * Constructor for a frame.
   *
   * @param _sizeX       amount of cells horizontally
   * @param _sizeY       amount of cells vertically
   * @param _cellRadius  radius of each cell
   * @param _cellDepth   depth of each cell
   */
  Frame(int _sizeX, int _sizeY, float _cellRadius, float _cellDepth)
  {
    sizeX      = _sizeX;
    sizeY      = _sizeY;
    cellRadius = _cellRadius;
    cellDepth  = _cellDepth; 
    
    width  = sizeX * 2 * SIN60 * cellRadius;
    height = sizeY * 1.5       * cellRadius; 
    
    cells = new Cell[sizeY][sizeX];
    mirrored = true;
  }
  
  
  /**
   * Constructor for a mirrored frame
   */
  Frame(Frame source)
  {
    sizeX      = source.sizeX;
    sizeY      = source.sizeY;
    cellRadius = source.cellRadius;
    cellDepth  = source.cellDepth; 
    
    width  = sizeX * 2 * SIN60 * cellRadius;
    height = sizeY * 1.5       * cellRadius; 

    this.mirrored = !source.mirrored;
    
    cells = new Cell[sizeY][sizeX];
    for ( int y = 0 ; y < sizeY ; y++ )
    {
      for ( int x = 0 ; x < sizeX ; x++ )
      {
        if ( source.hasCell(x, y) )
        {
          Cell cell = createCell(x, y);
          cell.setActivity(source.getCell(x, y).getActivity());
        }
      }
    }
  }

  
  boolean hasCell(int x, int y)
  {
    return getCell(x, y) != null; 
  }
  

  Cell getCell(int x, int y)
  {
    if ( (x < 0) || (x >= sizeX) ||
         (y < 0) || (y >= sizeY) ) return null;
         
    return cells[y][x];  
  }


  Cell createCell(int x, int y)
  {
    Cell cell = getCell(x, y);
    if ( (cell == null) && 
         (x >= 0) && (x < sizeX) &&
         (y >= 0) && (y < sizeY) )
    {
      float heightVariation = CELL_ROUGHNESS * noise(x / 10.0, y / 10.0);
      cell = new Cell(new FramePos(this, x, y), heightVariation, cellRadius, cellDepth + heightVariation);
      cells[y][x] = cell;
    }
    return cell;
  }
  
  
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

  
  void render()
  {
    for ( Cell[] row : cells )
    {
      for ( Cell cell : row )
      {
        if ( cell != null ) cell.render();
      }
    }
  }
  
  
  void writeSTL(PrintWriter w)
  {
    w.println("solid Surface");
    for ( Cell[] row : cells )
    {
      for ( Cell cell : row )
      {
        if ( cell != null ) cell.writeSTL(w);
      }
    }
    w.println("endsolid");
  }
  
  
  Cell[][] cells;
}