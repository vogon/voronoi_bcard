import java.util.ArrayDeque;
import java.util.ArrayList;

int W = 200, H = 200;

class VoronoiSeed
{
  public color c;
  public int x;
  public int y;
  public ArrayList<VoronoiSeed> neighbors;
  
  public VoronoiSeed(int x, int y)
  {
    this.x = x;
    this.y = y;
    this.neighbors = new ArrayList<VoronoiSeed>();
  }
}

class FloodFillState
{
  public double distance;
  public int x;
  public int y;
  
  public FloodFillState(double distance, int x, int y)
  {
    this.distance = distance;
    this.x = x;
    this.y = y;
  }
}

class VoronoiData
{
  // -infinity: obstruction
  // [0..infinity): distance to voronoi seed
  // infinity: not calculated yet
  public double distance;
  
  public VoronoiSeed seed; 
  
  public VoronoiData()
  {
    distance = Double.POSITIVE_INFINITY;
    seed = null;
  }
}

VoronoiSeed[] seeds;
VoronoiData[][] g;

void voronoiFloodFill(VoronoiSeed seed)
{
  ArrayDeque<FloodFillState> frontier = 
    new ArrayDeque<FloodFillState>();
  frontier.add(new FloodFillState(0, seed.x, seed.y));
  double sqrt2 = sqrt(2);
  boolean euclidean = false;
  
  while (!frontier.isEmpty())
  {
    FloodFillState here = frontier.poll();
    VoronoiData data = g[here.x][here.y];
    
    if (here.distance < data.distance)
    {
//      println("filling at ", here.x, ", ", here.y, "; ",
//        here.distance, " < ", data.distance); 
      
      data.distance = here.distance;
      data.seed = seed;
      
      if ((here.x - 1) >= 0)
      {
        if (euclidean && (here.y - 1) >= 0)
          frontier.add(new FloodFillState(here.distance + sqrt2, here.x - 1, here.y - 1));

        frontier.add(new FloodFillState(here.distance + 1, here.x - 1, here.y));
          
        if (euclidean && (here.y + 1) <= H - 1)
          frontier.add(new FloodFillState(here.distance + sqrt2, here.x - 1, here.y + 1));
      }
      
      if ((here.x + 1) <= W - 1)
      {
        if (euclidean && (here.y - 1) >= 0)
          frontier.add(new FloodFillState(here.distance + sqrt2, here.x + 1, here.y - 1));
         
        frontier.add(new FloodFillState(here.distance + 1, here.x + 1, here.y));
       
        if (euclidean && (here.y + 1) <= H - 1)
          frontier.add(new FloodFillState(here.distance + sqrt2, here.x + 1, here.y + 1));
      }
      
      if ((here.y - 1) >= 0)
      {
        frontier.add(new FloodFillState(here.distance + 1, here.x, here.y - 1));
      }
      
      if ((here.y + 1) <= H - 1)
      {
        frontier.add(new FloodFillState(here.distance + 1, here.x, here.y + 1));
      }
    }
    else
    {
//      println("filling at ", here.x, ", ", here.y, "; ",
//        here.distance, " > ", data.distance); 
    }
  }
}

void setup() 
{
  PImage img = loadImage("biz-card.png");
  println("image is " + img.width + " x " + img.height);
  W = img.width;
  H = img.height;
  
  color seedColors[] = new color[] {
    color(99, 178, 145),
    color(239, 193, 255),
    color(167, 255, 218),
    color(204, 176, 113),
    color(178, 157, 108)
  };

  g = new VoronoiData[W][H];
  
  for (int x = 0; x < W; x++)
  {
    for (int y = 0; y < H; y++)
    {
      g[x][y] = new VoronoiData();
    }    
  }
  
  size(W, H);
  background(255);
  noFill();

  SeedStatus[][] canSeed = new SeedStatus[W][H];
  
  // load image into voronoi graph
  img.loadPixels();
  
  for (int x = 0; x < W; x++)
  {
    for (int y = 0; y < H; y++)
    {
      color c = img.pixels[y * W + x];
      
      if (brightness(c) == 0)
      {
        g[x][y].distance = Double.NEGATIVE_INFINITY;
        canSeed[x][y] = SeedStatus.TEXT;
      }
      else
      {
        canSeed[x][y] = SeedStatus.LOOP;
      }
    }
  }

  println("... image loaded");

  // find "inside" and "outside" of letters by floodfilling from corner
  ArrayDeque<FloodFillState> outsideFrontier = new ArrayDeque<FloodFillState>();
  outsideFrontier.add(new FloodFillState(0, 0, 0));
  
  while (!outsideFrontier.isEmpty())
  {
    FloodFillState here = outsideFrontier.poll();
    
    if (canSeed[here.x][here.y] == SeedStatus.LOOP)
    {
      canSeed[here.x][here.y] = SeedStatus.OUTSIDE;
      
      if ((here.x - 1) >= 0)
        outsideFrontier.add(new FloodFillState(0, here.x - 1, here.y));
        
      if ((here.x + 1) <= W - 1)
        outsideFrontier.add(new FloodFillState(0, here.x + 1, here.y));
        
      if ((here.y - 1) >= 0)
        outsideFrontier.add(new FloodFillState(0, here.x, here.y - 1));
        
      if ((here.y + 1) <= H - 1)
        outsideFrontier.add(new FloodFillState(0, here.x, here.y + 1));
    } 
  }
  
  // mark off edges
  for (int x = 0; x < W; x++)
  {
    for (int y = 0; y < H; y++)
    {
      if (x < 0.1 * W || x > 0.9 * W || y < 0.1 * H || y > 0.9 * H)
        if (canSeed[x][y] == SeedStatus.OUTSIDE)
          canSeed[x][y] = SeedStatus.TOO_CLOSE;
    }
  }
 
  boolean seedStatusDiagram = false;
  
  if (seedStatusDiagram)
  {
    // help me debug the seeding algorithm
    for (int x = 0; x < W; x++)
    {
      for (int y = 0; y < H; y++)
      {
        SeedStatus status = canSeed[x][y];
        
        switch (status)
        {
        case LOOP: stroke(127, 127, 127); break;
        case OUTSIDE: stroke(255, 255, 255); break;
        case TEXT: stroke(0, 0, 0); break;
        case TOO_CLOSE: stroke(255, 0, 0); break;
        }
        
        point(x, y);
      }
    }
  }
  else
  {  
    // actually build voronoi diagram
    float exclusionRadius = Math.max(0.06 * W, 0.06 * H);
    
    print("planting seeds");
  
    ArrayList<VoronoiSeed> seeds = new ArrayList<VoronoiSeed>();
  
    for (int i = 0; i < 50; i++)
    {
      int x, y;
      
      // find seed location
      do
      {
        x = int(random(W));
        y = int(random(H));
      }
      while (canSeed[x][y] != SeedStatus.OUTSIDE);
      
      VoronoiSeed seed = new VoronoiSeed(x, y);
      
      // rope off exclusion radius around it
      for (int checkX = 0; checkX < W; checkX++)
      {
        for (int checkY = 0; checkY < H; checkY++)
        {
          if (sq(x - checkX) + sq(y - checkY) <= sq(exclusionRadius))
          {
            if (canSeed[checkX][checkY] == SeedStatus.OUTSIDE)
              canSeed[checkX][checkY] = SeedStatus.TOO_CLOSE;
          }
        }
      }
      
      // choose color [temporary]
      int r = int(128 + random(128));
      seed.c = color(r, r, 255);
      
      // flood fill from seed
      voronoiFloodFill(seed);
      seeds.add(seed);
      print(".");
    }
    
    println("done.");
  
    for (int x = 0; x < W; x++)
    {
      for (int y = 0; y < H; y++)
      {
        VoronoiData data = g[x][y];
        
        if (data.distance == Double.NEGATIVE_INFINITY)
        {
          // obstruction
          stroke(0, 0, 0);
          point(x, y);
        }
        else if (data.seed != null)
        {
          stroke(data.seed.c);
          point(x, y);
        }
      }
    }
  }
}
