/**
 * Class for the geometry and logical information of a single cell.
 */
class Cell
{
  FramePos pos;
  PVector  worldPos;
  float    radius, depth;
  float    activity;
  
  
  Cell(FramePos pos, float zOffset, float radius, float depth)
  {
    this.pos        = pos;
    this.worldPos   = pos.getWorldPos();
    this.worldPos.z = zOffset;
    this.radius     = radius;
    this.depth      = depth;
    
    activity  = 0;
    vtx       = null; 
    updateGeometry();
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

    final float x1 =   0;
    final float y1 =   radius;
    final float x2 =   radius * SIN60;
    final float y2 =   radius * COS60;
    final float d1 = - depth + radius / 2; 
    final float d2 = - depth; 
    final float d3 = - depth - radius / 2;
    
    vtx[ 0] = new PVector( x1,  y1, 0);
    vtx[ 1] = new PVector( x2,  y2, 0); 
    vtx[ 2] = new PVector( x2, -y2, 0);   
    vtx[ 3] = new PVector( x1, -y1, 0);
    vtx[ 4] = new PVector(-x2, -y2, 0);  
    vtx[ 5] = new PVector(-x2,  y2, 0);
    vtx[ 6] = new PVector( x1,  y1, d2);
    vtx[ 7] = new PVector( x2,  y2, d1);
    vtx[ 8] = new PVector( x2, -y2, d2);
    vtx[ 9] = new PVector( x1, -y1, d1);  
    vtx[10] = new PVector(-x2, -y2, d2);
    vtx[11] = new PVector(-x2,  y2, d1);
    vtx[12] = new PVector(  0,   0, d3);
  }


  void render()
  {  
    pushMatrix();
      translate(worldPos.x, worldPos.y, worldPos.z);
      scale(0.999);
      fill(  map(activity, 0, 1,  30, 200), map(activity, 0, 1,  15, 100), 0);
      stroke(map(activity, 0, 1, 128, 255), map(activity, 0, 1, 100, 200), 0);
      //strokeWeight(map(activity, 0, 1, 1, 2));
      renderShape();
    popMatrix();
  }


  void renderShape()
  {
    beginShape(QUADS);
      renderQuad( 0,  6,  7,  1); 
      renderQuad( 1,  7,  8,  2); 
      renderQuad( 2,  8,  9,  3); 
      renderQuad( 3,  9, 10,  4);
      renderQuad( 4, 10, 11,  5); 
      renderQuad( 5, 11,  6,  0); 
      renderQuad( 8,  7,  6, 12);
      renderQuad(10,  9,  8, 12);
      renderQuad( 6, 11, 10, 12);
    endShape();
  }  
  
  
  void renderQuad(int v1, int v2, int v3, int v4)
  {
    PVector v;
    v = vtx[v1]; vertex(v.x, v.y, v.z); 
    v = vtx[v2]; vertex(v.x, v.y, v.z); 
    v = vtx[v3]; vertex(v.x, v.y, v.z); 
    v = vtx[v4]; vertex(v.x, v.y, v.z); 
  }
  
  
  void writeSTL(PrintWriter w)
  {
    writeQuad(w,  0,  6,  7,  1); 
    writeQuad(w,  1,  7,  8,  2); 
    writeQuad(w,  2,  8,  9,  3); 
    writeQuad(w,  3,  9, 10,  4);
    writeQuad(w,  4, 10, 11,  5); 
    writeQuad(w,  5, 11,  6,  0); 
    writeQuad(w,  8,  7,  6, 12);
    writeQuad(w, 10,  9,  8, 12);
    writeQuad(w,  6, 11, 10, 12);
  }
  
  
  void writeQuad(PrintWriter w, int v1, int v2, int v3, int v4)
  {
    writeTriangle(w, v1, v2, v3);
    writeTriangle(w, v3, v4, v1);
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
  
  
  private PVector[] vtx;
}