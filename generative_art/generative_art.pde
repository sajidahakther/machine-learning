//3 continuous outputs

//OSC communication with wekinator
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress dest;

//default parameters set for wekinator
float p1 = 0; //change pattern (0-1)
float p2 = 0.5; //create/delete lines (0-1)
float p3 = 0.5; //shift (0-1)
float p4 = 0.6; //colour (0-0.6)

//generative art variables
float l; 
float numOfl = l;
float angle = 0;
float v1 = 0.4;
float v2;
boolean increment = false;
float shift = 0.00001;

void setup() {
  size(500, 500);

  //initialising OSC communication
  oscP5 = new OscP5(this, 12000); //listens for OSC messages on port: 12000 
  dest = new NetAddress("127.0.0.1", 6448); //sends messages back to wekinator on port: 6448 (localhost)

  v1 = random(0.4) + 0.2;
  smooth(2);
}

void draw() {
  background(20);
  angle += 0.01;
  translate(width/2, height/2);
  rotate(sin(angle));

  for (int i = 1; i < numOfl; i++) {  
    //colour of points
    strokeWeight(4);
    stroke(155 * p4, p4, 100);
    point(x2(l+i), y2(l+i));
    stroke(255 * p4, p4, 100);
    point(x1(l+i), y1(l+i));

    //colour of line
    strokeWeight(1.2);
    stroke(255 * 0.2, 0.2, 100);
    line(x1(l+i), y1(l+i), x2(l+i), y2(l+i));
  }

  l += 0.005;
  if (increment) {
    v1 += shift;
  }

  //generate new random pattern
  if (p1 >= 0.9) {
    v1 = random(0.4) + 0.2;
  }  

  //create or delete lines
  if (p2 >= 0.9) {
    numOfl += 1;
    println("line count: " + numOfl);
  } else if (p2 <= 0.1) {
    numOfl -= 1;
    println("line count: " + numOfl);
    if (numOfl == 0) {
      p2 = 0.5; //default - stationary
    }
  }

  //shift and re-arrange lines
  if (p3 >= 0.9) {
    increment = true;
    shift = -0.00005;
    println("left: " + shift);
  } else if (p3 <= 0.1) {
    increment = true;
    shift = 0.0001;
    println("right: " + shift);
    if (p3 == 0.5) {
      increment = false;
    }
  }
}

//generative drawing using sine/cosine for x1,y1,x2,y2
float x1(float l) { 
  return sin(l/10) * 100 + cos(l/v1) * 100;
}
float y1(float l) { 
  return cos(l/10) * 100 + sin(l/v1) * 100;
}
float x2(float l) { 
  return sin(l/10) * 10 + cos(l/v1) * 100;
}
float y2(float l) { 
  return cos(l/10) * 10 + sin(l/v1) * 100;
}

//called when OSC message is received, checks for p1-p4
void oscEvent(OscMessage theOscMessage) { 
  if (theOscMessage.checkAddrPattern("/wek/outputs")==true) {
    if (theOscMessage.checkTypetag("fff")) { 
      p1 = theOscMessage.get(0).floatValue(); 
      p2 = theOscMessage.get(1).floatValue(); 
      p3 = theOscMessage.get(2).floatValue();
      //p4 = theOscMessage.get(3).floatValue(); 
      println("Received new params value from Wekinator");
    } else {
      println("error: unexpected param type tag received by processing");
    }
  }
}
