/**
 * Class for the geometry and logical information of a single cell.
 */
class Cell
{
  FramePos pos;
  PVector  worldPos;
  float    radius, depth;
  
  
  Cell(FramePos pos, float zOffset, float radius, float depth)
  {
    this.pos        = pos;
    this.worldPos   = pos.getWorldPos();
    this.worldPos.z = zOffset;
    this.radius     = radius;
    this.depth      = depth;
    
    vtx = null; 
    arrFaceIdx = pos.frame.config.mirrored ? 1 : 0; // what face array to use
    updateGeometry();

    setActivity(0);
  }


  float getActivity()
  {
    return activity;
  }
  
  
  void setActivity(float act)
  {
    activity = constrain(act, 0, 1);
    colFill   = getCellColour(activity, false);
    colStroke = getCellColour(activity, true);
  }


  void addActivity(float add)
  {
    setActivity(activity + add);
  }
  

  void updateGeometry()
  {
    if ( vtx == null ) 
    {
      vtx = new PVector[13];
      // 0 -  5: front (open)
      // 6 - 11: rear
      //     12: cap centre
    }

    final float x1 =  0;
    final float y1 =  radius;
    final float x2 =  radius * SIN60;
    final float y2 =  radius * COS60;
    final float dy = -depth * tan(radians(CELL_ANGLE)); // delta Y for slight angle in cells

    float z0 = -depth;
    float z1 =  0;
    float z2 = -radius / 4; 
    float z3 =  radius / 4;
    
    if ( pos.frame.config.mirrored )
    {
      z0 = -z0;  float tmp_z1 = z1;
      z1 = -z2;
      z2 = -tmp_z1; 
      z3 = -z3; 
    }
    
    vtx[ 0] = new PVector( x1,  y1 + dy, z0);
    vtx[ 1] = new PVector( x2,  y2 + dy, z0); 
    vtx[ 2] = new PVector( x2, -y2 + dy, z0);   
    vtx[ 3] = new PVector( x1, -y1 + dy, z0);
    vtx[ 4] = new PVector(-x2, -y2 + dy, z0);  
    vtx[ 5] = new PVector(-x2,  y2 + dy, z0);
    vtx[ 6] = new PVector( x1,  y1, z2);
    vtx[ 7] = new PVector( x2,  y2, z1);
    vtx[ 8] = new PVector( x2, -y2, z2);
    vtx[ 9] = new PVector( x1, -y1, z1);  
    vtx[10] = new PVector(-x2, -y2, z2);
    vtx[11] = new PVector(-x2,  y2, z1);
    vtx[12] = new PVector(  0,   0, z3);
  }


  void render()
  {  
    pushMatrix();
      translate(worldPos.x, worldPos.y, worldPos.z);
      scale(0.999);
      fill(colFill);
      stroke(colStroke);
      //strokeWeight(map(activity, 0, 1, 1, 2));
      renderShape();
    popMatrix();
  }


  void renderShape()
  {
    beginShape(QUADS);
      for ( int[] face : arrFaces[arrFaceIdx] )
      {  
        renderQuad(face); 
      }
    endShape();
  }  
  
  
  void renderQuad(int[] arrV)
  {
    PVector v;
    v = vtx[arrV[0]]; vertex(v.x, v.y, v.z); 
    v = vtx[arrV[1]]; vertex(v.x, v.y, v.z); 
    v = vtx[arrV[2]]; vertex(v.x, v.y, v.z); 
    v = vtx[arrV[3]]; vertex(v.x, v.y, v.z); 
  }
  
  
  void writeSTL(PrintWriter w)
  {
    for ( int[] face : arrFaces[arrFaceIdx] )
    {  
      writeQuad(w, face); 
    }
  }
  
  
  void writeQuad(PrintWriter w, int[] arrV)
  {
    writeTriangle(w, arrV[0], arrV[1], arrV[2]);
    writeTriangle(w, arrV[2], arrV[3], arrV[0]);
  }
  
  
  void writeTriangle(PrintWriter w, int v1, int v2, int v3)
  {
    PVector e1 = new PVector(); e1.set(vtx[v1]); e1.sub(vtx[v2]);
    PVector e2 = new PVector(); e2.set(vtx[v3]); e2.sub(vtx[v2]);
    PVector n = e1.cross(e2); n.normalize();
    w.println("facet normal " + n.x + " " + n.y + " " + n.z);
    w.println("outer loop");
    writeVertex(w, vtx[v1]);
    writeVertex(w, vtx[v2]);
    writeVertex(w, vtx[v3]);
    w.println("endloop");
    w.println("endfacet");
  }
  
  
  void writeVertex(PrintWriter w, PVector v)
  {
    w.println("vertex " + (worldPos.x + v.x) + " " 
                        + (worldPos.y + v.y) + " "
                        + (worldPos.z + v.z));
  }
  
  
  private       PVector[] vtx;
  private final int       arrFaceIdx;
  private       float     activity;
  private       color     colFill, colStroke;
}


static final int[][][] arrFaces = 
  { // for "normal" cells
    { { 0,  6,  7,  1},  
      { 1,  7,  8,  2}, 
      { 2,  8,  9,  3}, 
      { 3,  9, 10,  4},
      { 4, 10, 11,  5}, 
      { 5, 11,  6,  0}, 
      { 9,  8,  7, 12},
      {11, 10,  9, 12},
      { 7,  6, 11, 12},
    },
    { // for mirrored cells (cap quads need to be different to avoid non-planar surface) 
      { 0,  6,  7,  1},  
      { 1,  7,  8,  2}, 
      { 2,  8,  9,  3}, 
      { 3,  9, 10,  4},
      { 4, 10, 11,  5}, 
      { 5, 11,  6,  0},  
      { 8,  7,  6, 12},
      {10,  9,  8, 12},
      { 6, 11, 10, 12},
    }
  };
  