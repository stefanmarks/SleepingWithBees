/**
 * Class for managing a rectangluar frame full of cells.
 */
class Frame
{
  final int   sizeX, sizeY;
  final float cellRadius, cellDepth;

  final float height, width;
  
  
  Frame(int _sizeX, int _sizeY, float _cellRadius, float _cellDepth)
  {
    sizeX      = _sizeX;
    sizeY      = _sizeY;
    cellRadius = _cellRadius;
    cellDepth  = _cellDepth; 
    
    width  = sizeX * 2 * SIN60 * cellRadius;
    height = sizeY * 1.5       * cellRadius; 
    
    cells = new Cell[sizeY][sizeX];
  }
  
  
  boolean hasCell(int x, int y)
  {
    return getCell(x, y) != null; 
  }
  

  Cell getCell(int x, int y)
  {
    return cells[y][x];  
  }


  Cell createCell(int x, int y)
  {
    Cell cell = getCell(x, y);
    if ( cell == null )
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
      float heightVariation = CELL_ROUGHNESS * noise(x / 10.0, y / 10.0);
      cell = new Cell(new FramePos(this, x, y), heightVariation, cellRadius, cellDepth + heightVariation);
      cell.setActivity(activity);
      cells[y][x] = cell;
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