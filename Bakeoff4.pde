import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float lastAccTime = millis();
float magnetValue = 0;
boolean isTapped = false;
float tapCount = 0;

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

  rectMode(CENTER);
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
    for (int i=0; i<4; i++)
    {
      if (targets.get(trialIndex).target==i)
        fill(0, 255, 0);
      else
        fill(180, 180, 180);
      ellipse(i*150+100, 300, 100, 100);
    }
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
    text("Target #" + (targets.get(trialIndex).target)+1, width/2, 100);


    if (targets.get(trialIndex).action==0)
      text("1 TAP", width/2, 150);
    else
      text("2 TAPS", width/2, 150);
      
      
  } else 
  text("DONE DONE!", width/2, 100);
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

void onMagneticFieldEvent(float x, float y, float z) 
{
  /* Check to avoid out of bounds error */
  if (trialIndex >= trialCount)
    return;

  Target t = targets.get(trialIndex);
  magnetValue = sqrt(sq(x) + sq(y) + sq(z));

  if (countDownTimerWait<0) //possible hit event
  {
    if (hitTest()==t.target)//check if it is the right target
    {
      /* Convoluted code here handles one tap or two taps  */
      if (t.action == 0)
      {
        // println("Right target, Correct Magnetic Value! " + hitTest());
        if (magnetValue > 200) trialIndex++; //next trial!
      } else if (t.action == 1)
      {
        if (!isTapped) 
        {
          if (magnetValue > 200) 
          {
            isTapped = true;
          }
        } else  
        {
          /* 1st Tap Detected when magnet value goes down */
          if ((magnetValue < 200) && isTapped)
          {
            tapCount = 1;
            // println("First tap detected!");
          } else 
          {
            /* 2nd Tap detected */
            if ((tapCount == 1) && (magnetValue > 200))
            {
              println("Right target, Correct Magnetic Value! " + hitTest());
              trialIndex++; //next trial!

              /* Resetting my values */
              isTapped = false;
              tapCount = 0;
            }
          }
        }
      }
      //else
      //   println("Right target, Magnetic Value too low!");

      countDownTimerWait=6; //wait 0.1 sec before allowing next trial
    } 
    // else
    // println("Missed target! " + hitTest()); //no recording errors this bakeoff.
  }
}
int hitTest() 
{
  for (int i=0; i<4; i++)
    if (dist(i*150+100, 300, cursorX, cursorY)<100)
      return i;

  return -1;
}