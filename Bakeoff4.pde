import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float lastAccTime = millis();
float magnetValue = 0;
boolean propClose = false; 
boolean onStageOne = true;

private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();

int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

void setup() {
  size(600, 600); //you can change this to be fullscreen
  frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();
  orientation(PORTRAIT);

  rectMode(CORNERS);
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);

  for (int i=0; i<trialCount; i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }

  Collections.shuffle(targets); // randomize the order of the button;
}

void draw() {

  background(80); //background is light grey
  noStroke(); //no stroke

  countDownTimerWait--;
  isCorrectHit(); 


  if (startTime == 0)
    startTime = millis();

  if (trialIndex==targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount, 1) + " sec per target", width/2, 150);
    return;
  }

  /* Check to avoid out of bounds error */
  if (trialIndex < trialCount)  
  {
    /* Changed to Aubrey Code */
    for (int i=0; i<4; i++)
    {
      int j = targets.get(trialIndex).target;

      if (j==i)
        fill(0, 255, 0);
      else
        fill(180, 180, 180);
      stroke(255);
      rect(((i%2)*(width/2)), ((i/2)*(height/2)), ((i%2)*(width/2)) + width/2, ((i/2)*(height/2)) + height/2);
    }
    /* End of change */
  }

  fill(255, 0, 0);
  ellipse(cursorX, cursorY, 50, 50);

  fill(255);//white
  textSize(60);
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 50);
  textSize(40);

  /* Check to avoid out of bounds error */
  if (trialIndex < trialCount) 
  {
    /* Display different text for stage one and two */
    if (onStageOne)
      text("TILT TO GREEN", width/2, 100);
    else 
    { 
      if (targets.get(trialIndex).action==0)
        text("TAP DOWN", width/2, 100);
      else
        text("TAP UP", width/2, 100);
    }
  } 
}

void onAccelerometerEvent(float x, float y, float z)
{

  if (userDone)
    return;

  if ((lastAccTime - millis()) < 20) 
  {
    cursorX = 300+x*40; //cented to window and scaled
    cursorY = 300-y*40; //cented to window and scaled
  }



  lastAccTime = millis();
}

/* Gets abs value of Magnetic field in uT */
void onMagneticFieldEvent(float x, float y, float z) 
{
  magnetValue = sqrt(sq(x) + sq(y) + sq(z));
}

/* Proximity value, either 5.0 or 0
 * When at 0, propClose is set to true. */
void onProximityEvent(float d) 
{
  if (d < 3) propClose = true;
  else propClose = false;
}

void isCorrectHit() 
{
  /* Check to avoid out of bounds error */
  if (trialIndex >= trialCount)
    return;

  Target t = targets.get(trialIndex);

  if (countDownTimerWait<0) //possible hit event
  {
    if (hitTest()==t.target)//check if it is the right target
    {
      onStageOne = false;
      /* Handle action one Magnet  */
      if ((t.action == 0) && (magnetValue > 200)) {
        trialIndex++; //next trial!
        onStageOne = true;
      }
      else if ((t.action == 1) && (propClose == true))
      {
        trialIndex++;
        onStageOne = true;
      }
      else
        println("You missed Target");
    }
    else 
      onStageOne = true;
      
    countDownTimerWait=30; //wait 0.1 sec before allowing next trial
  }
}

/* Return which Quadrant the cursor is in!! */
int hitTest() 
{

  /* Quad 0 */
  if (dist(width/4, width/4, cursorX, cursorY) < 150)
    return 0;
  else if (dist(3*width/4, width/4, cursorX, cursorY) < 150)
    return 1;
  /* Rect code draws 3 before 2 so we invert 'em to match logic */
  else if (dist(3*width/4, 3*width/4, cursorX, cursorY) < 150)
    return 3;
  else if (dist(width/4, 3*width/4, cursorX, cursorY) < 150)
    return 2;

  return -1;
}