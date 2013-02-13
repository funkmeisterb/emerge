// ******************************************************************
// This class represent an environment, as observable by an agent.
// ******************************************************************
class QualiaOscMunchkin extends Munchkin
{
  float fx;
  float fy;
  //float xHeat;
  //float yHeat;
  //float xSize;
  //float ySize;
  
  // Influence = contribution to the force from closest neighbors in each quadrant
  float influence[] = new float[4];
  
  // Distance of closest neighbor.
  float distClosest;

  boolean hasClosest = false;
  
  // ============================================
  // Constructors
  // ============================================
  QualiaOscMunchkin(int nation, float x, float y, float size, float heat)
  {
    super(nation, x, y, size, heat);
  }

  QualiaOscMunchkin(int nation, float x, float y, float size)
  {
    super(nation, x, y, size);
  }
  
  QualiaOscMunchkin(int nation, float x, float y)
  {
    super(nation, x, y);
  }

  // ============================================
  // Member functions
  // ============================================ 
  void move(World world) 
  {
    // IMPORTANT: KEEP THESE LINES AS IS: THERE IS AN ISSUE WITH THE FORCES GETTING TO NAN IN SOME UNKNOWN CIRCUMSTANCES; THIS FIXES IT
    if (Double.isNaN(getForceX()) || Double.isNaN(getForceY()))
    {
      resetForces();
    }

    float heatFactor = getHeat() * getHeat() * 10;
    //print("FX FY : " + fx + " " + fy + " " + + heatFactor);
    fx *= heatFactor;
    fy *= heatFactor;
    //println("  --- > " + fx + " " + fy);
    addForce(fx, fy);
    //println(this);
    float forceStrength = sqrt(fx*fx + fy*fy);
    setHeat(getHeat() - constrain(forceStrength, 0.0f, 1.0f) * HEAT_DECREASE_ON_ACTION);
    resetMoveForce();
  }
  
  // Checks position of Thing relative to this and classifies it in one of the following quadrants:
  //  \ 3  /
  //   \  /
  // 2  \/ 0
  //    /\
  //   /  \
  //  / 1  \
  int getRelativeQuadrant(Thing t) {
    float diffX = t.x() - x();
    float diffY = t.y() - y();
    float angle = atan2(diffY, diffX);
  
    if (angle < -3*PI/4 || angle >= 3*PI/4)
      return 2;
    else if (angle < -PI/4)
      return 3;
    else if (angle < PI/4)
      return 0;
    else
      return 1;
  }
  
  void step(World world) {
    super.step(world);
    
    float observationRadius = MUNCHKIN_OBSERVATION_RADIUS;//MUNCHKIN_OBSERVATION_RADIUS_FACTOR * getActionRadius();
    Vector<Thing> neighbors = getNeighbors(world, observationRadius);
    
    // Init closest distances to max value.
    float[] distClosestInQuadrant = new float[4];
    for (int i=0; i<4; i++) {
      distClosestInQuadrant[i] = width;
      influence[i] = 0;
    }
    distClosest = width;

    if (neighbors.size() == 0)
    {
      hasClosest = false;
    }
    else
    {
      hasClosest = true;
      for (Thing t : neighbors)
      {
        // Quadrant mappings:
        // I  | II
        // IV | III
        int quadrant = getRelativeQuadrant(t);
        
        float d = distance(x(), y(), t.x(), t.y());
        
        if (d < distClosestInQuadrant[quadrant])
        {
          distClosestInQuadrant[quadrant] = d;
          influence[quadrant] = t.size() / (d*d + 1e-10f) * 1000;
        }
      }
      
    }
    
    for (int i=0; i<4; i++)
      distClosest = min(distClosest, distClosestInQuadrant[i]);

/*
    xHeat = 0;
    yHeat = 0;
    xSize = 0;
    ySize = 0;
    for (Thing t : neighbors) {
      float xdiff = map(x() - t.x(), -observationRadius, observationRadius, -1., +1.);
      float ydiff = map(y() - t.y(), -observationRadius, observationRadius, -1., +1.);
      float d = distance(x(), y(), t.x(), t.y());
      float power = 1-d; // closest are stronger
      xHeat += xdiff * t.getHeat();
      yHeat += ydist * t.getHeat();
      xSize += xdist * t.size();
      ySize += ydist * t.size();
    }
    */
    
    // Increase size every now and then.
    if (random(0.0, 1.0) <  0.1f / (size() * size() + 1))
    {
      setSize(size()+1);
    }
  }
  
  void resetMoveForce()
  {
    this.fx = this.fy = 0;
  }
  
  void addMoveForce(float fx, float fy)
  {
    this.fx += fx * ACTION_FORCE_FACTOR;
    this.fy += fy * ACTION_FORCE_FACTOR;
  }
  
  // ============================================
  // Setters & getters
  // ============================================  
  float getReward() {
    float baseReward = 0;
    
    // Absolute localization: try to avoid borders and occupy center ///////////////////////////////////////////////////////
    
    // Avoid borders at all costs
    int tooCloseToBorder = max(width/10, 10);
    if (x() < tooCloseToBorder || x() >= width-tooCloseToBorder || y() < tooCloseToBorder || y() >= height-tooCloseToBorder) {
      baseReward -= 10; // bad, very bad!
    }

    float distCenter = distance(x(), y(), width/2, height/2); // distance to center
    float dist01     = distance(x(), y(), width/2, height/2) / (width/2); // distance to center remapped to 01
    
    // Stay close to center.
    if (dist01 > 0.5)
      baseReward -= ( 0.1 + dist01);
    else
      baseReward += +(1 - dist01);
    
    // Center zone is delightful.
    if (distCenter < 2*tooCloseToBorder)
      baseReward += 1.0f;
      
    float normalizedDistClosest = (hasClosest ? distClosest / (float)MUNCHKIN_OBSERVATION_RADIUS : 1.0);
    //println(normalizedDistClosest + " " + baseReward);
    
    switch (nation) {

      // Cuddlers.
      case Thing.RED:
        return baseReward + 10*(1 - normalizedDistClosest*normalizedDistClosest);
      
      // Normal.
      case Thing.GREEN:
        return baseReward + 10*(1 - abs(normalizedDistClosest - 0.1));

      // Loners.
      case Thing.BLUE:
        return baseReward + 10*normalizedDistClosest*normalizedDistClosest; // less influenced by wanting to stay in the center

      // Agressive.
      case Thing.YELLOW:
        return baseReward ;

      default:
        println("Wrong nation: " + nation);
        exit();
        return 0;
    }
  }
  
  float[] getObservation() {
    float[] obs = new float[] {

      map(x(), 0.0f, (float)width, -1., 1.),
      map(y(), 0.0f, (float)height, -1., 1.),
      getVelocityX() /100,
      getVelocityY() /100,
      size() / 30,
      
      hasClosest ? 1.0f : 0.0f,
      (hasClosest ? distClosest / (float)width : 1.0),
      
      influence[0],
      influence[1],
      influence[2],
      influence[3],

      getReward()
    };
    //println(obs);
    if (obs.length-1 != OBSERVATION_DIM)
    {
      println("Wrong number of observations: " + obs.length);
      exit();
    }      
    return obs;
  }
 
  void draw(processing.core.PGraphics applet) {
    super.draw(applet);
    
    // Uncomment to display influence information.
    int fontSize = 10;
    textSize(fontSize);
    fill(#555555);
    text(getReward(), (int)x() + 2, (int) y());
/*    textAlign(LEFT);
    text(influence[0], (int)x()+2, (int)y());
    textAlign(CENTER);
    text(influence[1], (int)x(), (int)y()+fontSize);
    textAlign(RIGHT);
    text(influence[2], (int)x()-2, (int)y());
    textAlign(CENTER);
    text(influence[3], (int)x(), (int)y()-fontSize);*/
  }
}
