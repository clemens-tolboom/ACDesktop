import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;

Maxim maxim;
AudioPlayer kickerSound, wallSound;
AudioPlayer[] noteSounds;

Physics physics;

CollisionDetector detector; 

final int DEBUG = 0;

Body kicker;
Body [] notes;
String [] noteKeys;

int noteSize = 80;
int ballSize = 60;

PImage rotatorImage;
int rotatorWidth = 200;
int rotatorHeight = 10;

PImage noteImage;
PImage ballImage;
PImage background;

int score = 0;

boolean dragging = false;

Body [] rotator;

void setup() {
  size(1024,768);
  frameRate(60);

  textSize(26);
  textAlign(CENTER);

  // http://pixabay.com/static/uploads/photo/2011/05/25/14/46/piano-keys-7624_640.jpg
  background = loadImage("piano.jpg");
  
  //noteImage = loadImage("crate.jpeg");
  ballImage = loadImage("g7.png");
  rotatorImage = loadImage("rotator.png");

  imageMode(CENTER);

  physics = new Physics(this, width, height, 0, 0, width*2, height*2, width, height, 25);
 
  if (DEBUG == 0) {
    physics.setCustomRenderingMethod(this, "myCustomRenderer");
  }

  // No friction
  physics.setFriction(0.01);
  // Elastic collisions (keep going)
  physics.setRestitution(1.0);

  physics.setDensity(6.0);

  rotator = new Body[3];
  rotator[0] = createRotator( width / 2, height / 4 * 3, rotatorWidth, rotatorHeight);
  rotator[1] = createRotator( width / 4, height / 4, rotatorWidth, rotatorHeight);
  rotator[2] = createRotator( width / 4 * 3, height / 4, rotatorWidth, rotatorHeight);
  
  // Setup notes  
  int numNotes = 4;
  notes = new Body[numNotes];
  noteKeys = new String[numNotes];
  int i;
  for(i=0; i< notes.length; i++) {
    float x1 = width/2 + noteSize/6 * i;
    float y1 =  height/2 -i;
    notes[i] = physics.createCircle(x1, y1, noteSize/2);
    noteKeys[i] = "C";
  }

  // circle parameters are center x,y and radius
  kicker = physics.createCircle(width/2, -100, ballSize/2);

  // sets up the collision callbacks
  detector = new CollisionDetector (physics, this);

  maxim = new Maxim(this);
  kickerSound = maxim.loadFile("piano-c.wav");
  wallSound = loadSound("piano-c.wav");

  noteSounds = new AudioPlayer[notes.length];
  for (i=0;i<noteSounds.length;i++){
    noteSounds[i] = loadSound("piano-c.wav");
  }
}

AudioPlayer loadSound(String filename) {
  AudioPlayer sound = maxim.loadFile(filename);
  sound.setLooping(false);
  sound.volume(1);
  return sound;
}

void debug(Object x) {
  debug(x , "debug");
}

void debug(Object x, String message) {
  if (DEBUG > 0) {
    println(message, ":", x);
  }
}

void draw() {
  image(background, width/2, height/2, width, height);

  if (DEBUG == 1) {
    myCustomRenderer(physics.getWorld());
  }
}

void mouseDragged()
{
  dragging = true;
  kicker.setLinearVelocity(new Vec2(0,0));
  kicker.setPosition(physics.screenToWorld(new Vec2(mouseX, mouseY)));
}

void mouseReleased()
{
  if (dragging) {
    dragging = false;
    Vec2 mouse = physics.screenToWorld( new Vec2(mouseX, mouseY));
    Vec2 pmouse = physics.screenToWorld( new Vec2(pmouseX, pmouseY));
    Vec2 impulse = mouse.sub(pmouse);
    impulse = impulse.mul(500);
    kicker.applyImpulse(impulse, kicker.getWorldCenter());
  }
}

String indexToNote(int index) {
  String [] lookup = { "C", "C/D", "D", "D/E", "E", "F", "F/G", "G", "G/A", "A", "A/B", "B"};
  debug(index, "indexToNote");
  return lookup[index%12];
}

int impulseToNote(float impulse) {
  float speed = map(impulse, 0, 1500, .5, 2.0);
  int note = (int) map(speed, 0.5, 2.0, 0, 24);
  debug(note, "impulseToNote");
  return note;
}

/**
 * Joins to Body rect together
 *
 * One rect is fixed and the other dynamic.
 *
 * @return Body
 *  Dynamic rectagle useful for animation purposes.
 */
Body createRotator(float x, float y, float width, float height)
{
  float density = physics.getDensity();
  
  physics.setDensity(0.0f);
  Body rectFix = physics.createRect( x - 5, y - 5, x + 5, y + 5);
  
  physics.setDensity(density);
  Body rect = physics.createRect( x - width / 2, y - height / 2, x + width / 2 , y + height / 2);

  physics.createRevoluteJoint(rectFix, rect, x, y);
  
  return rect;
}

void runPlayer(AudioPlayer player, float speed) {
  player.volume(0.0);
  player.setLooping(false);
  player.cue(0);
  player.volume(1.8);
  player.speed(speed);
  player.play();
}

void collision(Body b1, Body b2, float impulse)
{
  debug(b1.getLinearVelocity().length(), "velocity");
  int note = impulseToNote(impulse);
  float playSpeed = map(note, 0, 24, 0.5, 2.0);  

  AudioPlayer player;

  // kicker
  if (b1 == kicker || b2 == kicker) {
    runPlayer(kickerSound, playSpeed / 2);
  }
  // Notes
  for (int i=0;i<notes.length;i++){
    if (b1 == notes[i] || b2 == notes[i]){
      if (!noteSounds[i].isPlaying()) {
        runPlayer(noteSounds[i], playSpeed);
        noteKeys[i] = indexToNote(note);
      }
    }
  }
}

void myCustomRenderer(World world) {
  stroke(0);

  Vec2 screenkickerPos = physics.worldToScreen(kicker.getWorldCenter());
  float kickerAngle = physics.getAngle(kicker);
  pushMatrix();
  translate(screenkickerPos.x, screenkickerPos.y);
  rotate(-radians(kickerAngle));
  image(ballImage, 0, 0, ballSize, ballSize);
  popMatrix();

  for (int i = 0; i < notes.length; i++)
  {
    Vec2 worldCenter = notes[i].getWorldCenter();
    Vec2 notePos = physics.worldToScreen(worldCenter);
    float noteAngle = physics.getAngle(notes[i]);
    pushMatrix();
    translate(notePos.x, notePos.y);
    rotate(-noteAngle);
    //image(noteImage, 0, 0, noteSize, noteSize);
    color(128,128,128);
    stroke(128,128,0);
    fill(255);
    ellipse(0,0, noteSize, noteSize);
    fill(0);
    text(noteKeys[i], 0, 0);
    popMatrix();
  }

  for (int i = 0; i < rotator.length; i++)
  {
    Vec2 worldCenter = rotator[i].getWorldCenter();
    Vec2 notePos = physics.worldToScreen(worldCenter);
    float noteAngle = physics.getAngle(rotator[i]);
    pushMatrix();
    translate(notePos.x, notePos.y);
    rotate(-noteAngle);
    image(rotatorImage, 0, 0, rotatorWidth, rotatorHeight);
    popMatrix();
  }
}

