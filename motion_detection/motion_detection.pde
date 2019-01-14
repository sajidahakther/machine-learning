//2 continuous inputs

import processing.video.*;

//OSC communication with Wekinator
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress dest;

Capture video;
PImage prev;
float threshold = 25;
float motionX = 0;
float motionY = 0;
float posX = 0;
float posY = 0;

void setup() {
  size(640, 360);
  String[] cameras = Capture.list();
  printArray(cameras);
  video = new Capture(this, cameras[3]);
  video.start();
  prev = createImage(640, 360, RGB);
  
  //Start oscP5, listening for incoming messages at Port: 12000 
  oscP5 = new OscP5(this,9000);
  dest = new NetAddress("127.0.0.1",6448);
}

void captureEvent(Capture video) {
  prev.copy(video, 0, 0, video.width, video.height, 0, 0, prev.width, prev.height);
  prev.updatePixels();
  video.read();
}

void draw() {
  video.loadPixels();
  prev.loadPixels();
  image(video, 0, 0);

  //Increased threshold so it eliminates noise
  threshold = 70;
  int count = 0;
  float avgX = 0;
  float avgY = 0;

  loadPixels();
  //Begin loop to walk through every pixel
  for (int x = 0; x < video.width; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;
      //What is current color
      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      color prevColor = prev.pixels[loc];
      float r2 = red(prevColor);
      float g2 = green(prevColor);
      float b2 = blue(prevColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d > threshold*threshold) {
        avgX += x;
        avgY += y;
        count++;
        pixels[loc] = color(255);
      } else {
        pixels[loc] = color(0);
      }
    }
  }
  updatePixels();
  
  textSize(15);
  fill(255);
  text("Continuously sends 2 inputs to Wekinator, port 6448", 20, 20);

  if (count > 500) { 
    motionX = avgX / count;
    motionY = avgY / count;
    textSize(15);
    fill(255,0,0);
    text("Detecting motion", 20, 35); 
    sendOsc(); //Send the OSC message with current position
    posX = lerp(posX, motionX, 0.1); 
    posY = lerp(posY, motionY, 0.1);
    } else {
    fill(255);
    text("No motion detected", 20, 35);
  } 
  
  //Rectangle signifying where movement has been detected
  fill(255, 0, 0);
  strokeWeight(2.0);
  stroke(0);
  rect(posX, posY, 20, 20);
}

//Calculating the euclidean distance
float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

//Send 2 inputs to Wekinator via oSC: the detected x, y positions
void sendOsc() {
  OscMessage msg = new OscMessage("/wek/inputs");
  msg.add((float)posX); 
  msg.add((float)posY);
  oscP5.send(msg, dest);
}
