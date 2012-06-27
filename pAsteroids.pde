import java.util.ArrayList;

Spaceship ncc1701;
String message = "";
Space space;
int level = 0;

Star [] stars = new Star[100];

void setup() {
  size(640,360);
  colorMode(RGB, 255, 255, 255, 100);
  stroke(255);

  space = new Space();
  

  ncc1701 = new Spaceship(new PVector(320,180));
  space.add(ncc1701);
  for(int i=0; i<stars.length;i++) {
    stars[i] = new Star();
  }
}

void draw() {
  background(51);
  space.run();
}

public void keyPressed() {
  if (ncc1701.dead()) return;
  switch(keyCode) {
    case 38: // boost
      ncc1701.acc = ncc1701.head.get();
      ncc1701.acc.rotate(HALF_PI);
      ncc1701.hasBoost = true;
      break;
    case 37: // rotate left
      ncc1701.head.rotate(-PI/16);
      break;
    case 39: // rotate right
      ncc1701.head.rotate(+PI/16);
      break;
    case 32: // fire
      space.add(new Shell(ncc1701));
      break;
  }
}
public void keyReleased() {
  ncc1701.acc = ncc1701.stopThrust;
  ncc1701.hasBoost = false;
}

static PVector vector2SpaceCoordinates(PVector v,float translateX,float translateY,float rotation) {
  PMatrix3D M = new PMatrix3D();
  M.rotate(-rotation);
  M.translate(-translateX, -translateY);
  M.invert();
  PVector out = new PVector();
  M.mult(v.get(),out);
  return out;
}

static boolean isLeftOfVector(PVector pos, PVector direction, PVector vertex) {
  PVector newVertexPos = PVector.sub(vertex, pos);
  float phi = asin((direction.x*newVertexPos.y-direction.y*newVertexPos.x)/
        (sqrt(direction.x*direction.x+direction.y*direction.y)*
            sqrt(newVertexPos.x*newVertexPos.x+newVertexPos.y*newVertexPos.y)));
  boolean out = phi < 0;
  return out;
}

class Space {
  
  ArrayList<SpaceObject> spaceObjects;
  
  Space() {
    spaceObjects = new ArrayList<Asteroids.SpaceObject>();
  }
  
  void run() {
    
    for(int i=0; i<stars.length; i++){
      stars[i].draw();
    }
    stroke(255);
    if (spaceObjects.size() == 1 && spaceObjects.get(0) == ncc1701) {
      level++;
      for (int i = 0; i < level; i++) {
        space.add(new Asteroid(1,100,100));
      }
    }
    for (int i = 0; i < spaceObjects.size(); i++) {
      SpaceObject so = spaceObjects.get(i);
      so.run();
      if(so.dead()) {
        spaceObjects.remove(i);
      }
    }
    // collisions
    for (int i = 0; i < spaceObjects.size(); i++) {
      SpaceObject so1 = spaceObjects.get(i);
      if (so1 instanceof Shell) continue;
      for (int j = 0; j < spaceObjects.size(); j++) {
        SpaceObject so2 = spaceObjects.get(j);
        if (so1.equals(so2)) continue;
        if ((so1 instanceof Asteroid && so2 instanceof Shell)
            || (so1 instanceof Asteroid && so2 instanceof Spaceship)
            || (so1 instanceof Spaceship && so2 instanceof Asteroid))
        {
          for (int k = 0; k < so2.vertices.length; k++) {              
            PVector shellVertex = vector2SpaceCoordinates(so2.vertices[k], so2.loc.x, so2.loc.y, so2.head.heading2D());
            int length = so1.vertices.length;
            boolean isLeftOf = true;
            for(int r = 0; r < length; r++) {
              PVector vertex1 = vector2SpaceCoordinates(so1.vertices[r], so1.loc.x, so1.loc.y, so1.head.heading2D());
              PVector vertex2 = vector2SpaceCoordinates(so1.vertices[(r+1)%length], so1.loc.x, so1.loc.y, so1.head.heading2D());
              PVector edge = vertex2.get();
              edge.sub(vertex1);
              boolean isOut = isLeftOfVector(vertex1, edge, shellVertex);
              isLeftOf &= isOut;
              if (isLeftOf == false) break;
            }
            if (isLeftOf == true) {
              so1.destroyed();
              so2.destroyed();
            }
          }
        }
      }
    }
  }
  
  void add(SpaceObject so) {
    spaceObjects.add(so);
  }
}

abstract class SpaceObject {

  PVector [] vertices;
  PVector head, loc, vel, acc;
  abstract float timer();
  abstract void destroyed();
  void run() {
    update();
    render();
  }
  
  void update() {
    vel.add(acc);
    loc.add(vel);
    if (loc.x>width)  loc.x -= width;
    if (loc.x<    0)  loc.x += width;
    if (loc.y>height) loc.y -= height;
    if (loc.y<     0) loc.y += height;
  }
  
  void render() {
    pushMatrix();
    translate(loc.x,loc.y);
    rotate(head.heading2D());
    for (int i = 0; i < vertices.length; i++) {
      int next = (i + 1) % vertices.length;
      line(vertices[i].x,vertices[i].y,vertices[next].x,vertices[next].y);
    }
    popMatrix();
  }

  boolean dead() {
      if (timer() <= 0.0F) {
        return true;
      } else {
        return false;
      }
  }
}

class Spaceship extends SpaceObject {
  final PVector stopThrust = new PVector();
  boolean hasBoost;
  private float len = 10;
  float timer = 1.0F;

  float timer() { return timer; }
  void destroyed() { timer = -1.0F; }

  Spaceship(PVector l) {
    head = new PVector(-0.03F,0);
    acc = stopThrust;
    vel = new PVector();
    loc = l.get();
    hasBoost = false;
    vertices = new PVector[] { new PVector(0,len),new PVector(5,-len),new PVector(-5,-len) };
  }
  
  void render() {
    super.render();
    pushMatrix();
    //text(String.format("current ship pos: %f %f",loc.x,loc.y),0,150);
    translate(loc.x,loc.y);
    rotate(head.heading2D());
    if(hasBoost) {
      line(0,-len,0,-len-len/2);
      line(len/5,-len,len/4,-len-len/2);
      line(-len/5,-len,-len/4,-len-len/2);
    }
    popMatrix();
  }
  
}

class Shell extends SpaceObject {
  
  float timer = 50.0F;

  float timer() { return timer; }
  void destroyed() { timer = -1F; }
  
  Shell(Spaceship spaceship) {
    head = spaceship.head.get();
    head.rotate(HALF_PI);
    loc = spaceship.loc.get();
    vel = head.get();
    vel.scaleTo(4);
    acc = new PVector();
    vertices = new PVector[] { new PVector(0,0) };
  }
  
  void update() {
    super.update();
    timer -= 1.0F;
  }
  

}

class Asteroid extends SpaceObject {
  
  int polygone = 5;
  float rot;
  int asteroidClass;
  float timer = 1F;
  
  Asteroid(int aClass, float x, float y) {
    asteroidClass = aClass;
    rot = (random(2)-1) * PI / 200;
    head = new PVector(1,0);
    acc = new PVector();
    vel = new PVector(random(2)-1,random(2)-1);
    loc = new PVector(x,y);
    vertices = new PVector[polygone];
    float fraction = TWO_PI / polygone;
    float radius = 50F / asteroidClass;
    for (int i = 0; i < vertices.length; i++) {
      vertices[i]=new PVector(radius*sin(i*fraction)+random(6)-3,radius*cos(i*fraction)+random(6)-3);
    }
  }
  
  float timer() { return timer; }
  void destroyed() { 
    timer = -1F; 
    if(asteroidClass < 5) {
      for (int l = 0; l < 3; l++) {
        space.spaceObjects.add(new Asteroid(asteroidClass + 2, loc.x, loc.y));
      }
    }
  }
  
  void update() {
    super.update();
    head.rotate(rot);
  }
  
}

