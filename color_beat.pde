 //<>//


/* Color Beat: Detect colors of colors on video and play audio corresponding to color*/


//<A> Initialize libraries, data structures and constants 

// Specify the libraries that will be used in this project 
import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import java.util.Arrays;
import java.util.Collections;
import ddf.minim.*;


// Initialize video variables
Capture cam; // Talks to the camera on the computer
OpenCV opencv; // Processes pictures to identify the different colors on video and more...
PImage src; //image grabbed from camera

// Initialize audio variables
Minim minim; // Plays different audio files in different ways
AudioPlayer[] sounds; // Reads audio files in different formats and puts them in in a format that Minim can play
float track_volume; // volume at which a track is played
int track_idx; // index corresponding to specific track in the sounds array

 // Size of the camera image
int sWidth = 640; 
int sHeight = 480;

// Specify color detection constants 
int maxColors = 3; //The maximum number of colors that can be detected by this application
int rangeWidth = 5; //tolerance on color selection, this number can be increased to make it easier to detect colors or reduced to make it easier to kick out noise
float minColorArea=200; //Minimum color area required to display bounding box and trigger sound

//Specify color detection variables 
int[] hues; //hue values of the selected pixels
int[] colors; // color value of the selected pixels 
PImage[] outputs; // binary images that are 1 where the color is detected and 0 elsewhere
ArrayList<Contour> contours; // contours around detected color "blobs"
float[] color_areas; // areas of different color contours
float maxColorArea; //value of the largest color area 
int maxColorAreaIdx; //index to identify the color in the color_areas array that has the largest area

int colorToChange = -1;
//int ROI_is_set=-1;

// variables corresponding to the extra functions rankColorAreas and playSoundMultiple //<>//
int[] ranked_colors; //rank index of color in descending order of area
int skip_amount; 
float[] color_areas_ranked; //sorted areas of colors in descending order

//<B> Intialize camera streaming and display window, allocate memory, load files
void setup() {
  
  String[] cameras = Capture.list(); //Get a list of all the cameras pluged in 
  
  // Initilize a list of audio files
  String[] sound_files= new String[maxColors]; 
  // Specify file names for all the sound files, add other sound files to the color_beat folder
  // and specify the file name here 
  // Make sure there are as many audio tracks as there are colors 
     sound_files[0]="sound_0.wav";
     sound_files[1]="sound_1.mp3";
     sound_files[2]="sound_2.wav";
  
  
  cam = new Capture(this, sWidth, sHeight);
  opencv = new OpenCV(this, cam.width, cam.height);
  contours = new ArrayList<Contour>();
  
  size(640, 480);  
  
  if (cameras.length == 0) {
    println("There are no cameras available...");
    size(400, 400);
    exit();
  }
  else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, sWidth, sHeight);
   
   // Array for detection colors
    colors = new int[maxColors];
    ranked_colors=new int[maxColors];
    color_areas=new float[maxColors];
    hues = new int[maxColors];
    outputs = new PImage[maxColors];
   
    //Sound setup
    minim = new Minim(this);
    sounds = new AudioPlayer[maxColors];
    for (int i=0; i<maxColors; i++){
         sounds[i] = minim.loadFile(sound_files[i]);
    }

    cam.start();
    cam.loadPixels();
    
  }
 }

// <C> Run this function everytime the camera captures a new image
void draw() {
  if (cam.available() == true) {
    cam.read();
  } 
  set(0, 0, cam);
  
   // <1> Load the new frame of our movie in to OpenCV
  opencv.loadImage(cam);
  
  // Tell OpenCV to use color information
  opencv.useColor();
  src = opencv.getSnapshot();
  
  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);  

// <4> Detect any colors that are selected by the user
//     save detected colors as binary images, the variable "outputs",
//     that are 1 where the color is detected and 0 elsewhere
  detectColors();

// <5> Display rectangles around the detected colors 
// Store the areas of different color regions in the color_areas array 
  displayImages(); 

// <6> Loop through the color_areas and identify the color with the largest area
  getMaxColorArea(); 
  
// <7> Play the track corresponding to largest area, mute all other tracks
  playColorSound(); 
 
  
  // Print text if new color expected
  textSize(20);
  stroke(255);
  fill(255);
 
 // saveFrame("VideoFrames/output####.jpg"); //store output as a picture frame that can be converted into a movie later
  
   
/*  if (ROI_is_set==-1) {
    text("Select Region of Interest", 10,25);
  }
  
  if (ROI_is_set>-1 && colorToChange > -1) {
    text("click to change color " + colorToChange, 10, 25);
  } else if(ROI_is_set>-1){
    text("press key [1-3] to select color", 10, 25);
  }*/
  if (colorToChange > -1) {
    text("click to change color " + colorToChange, 10, 25);
  } else{
    text("press key [1-3] to select color", 10, 25);
  }
 }

//////////////////////
// Detect Functions
//////////////////////

// <4> Detect any colors that are selected by the user
//     save detected colors as binary images 
//     that are 1 where the color is detected and 0 elsewhere
void detectColors() {
    
  for (int i=0; i<hues.length; i++) {
    
    if (hues[i] <= 0) continue;
    
    opencv.loadImage(src);
    opencv.useColor(HSB);
    
    // <4.1> Copy the Hue channel of our image into 
    //     the gray channel, which we process.
    opencv.setGray(opencv.getH().clone());
    
    int hueToDetect = hues[i];
    //println("index " + i + " - hue to detect: " + hueToDetect);
    
    // <4.2> Filter the image based on the range of 
    //     hue values that match the object we want to track.
    opencv.inRange(hueToDetect-rangeWidth/2, hueToDetect+rangeWidth/2);
    
    // <4.3> Image filtering to detect "blobs" of color    
    opencv.erode(); //Remove small regions of detected color to get rid of noise
    opencv.dilate(); //Make the remaining regions bigger to get "blobs" of colors 
                    
 
    // <4.4> Save the processed image for reference.
    outputs[i] = opencv.getSnapshot();
 
  }
  

}

// <6> Loop through the color_areas and identify the color with the largest area
void getMaxColorArea(){

  maxColorArea=-1.0; //initialize the max area to an immpossible value
  maxColorAreaIdx=-1; // set index to a negative value to start with 
  for (int i=0; i<maxColors; i++){
    
    //Identify the maximum area bigger than the last one in the array and bigger
    // than the smallest area we allow
      if(color_areas[i]>minColorArea &&
         color_areas[i]>maxColorArea){
              maxColorArea=color_areas[i]; 
              maxColorAreaIdx=i;
         }
  }
// maxColorArea now the largest area in the array and 
// maxColorAreaIdx tells us which element in the array this area is 
// If these values are negative, we didn't find an area that's big enough
}


//////////////////////
// Display Functions
//////////////////////
//<5> Identify countours around the detected color "blobs", calculate the area
// of the biggest contours detected in an image, in every color
// Store all areas in the color_areas array for later
// Make rectangles around the different color regions and display them
void displayImages(){
  // <5.1> Show images
  image(src, 0, 0);

  for (int i=0; i<outputs.length; i++) {

    if (outputs[i] != null) {
      image(outputs[i], width-src.width/4, i*src.height/4, src.width/4, src.height/4);
      opencv.loadImage(outputs[i]);
      //<5.2> Identify countours around the detected color "blobs"
      contours = opencv.findContours(true,true);
      if(contours.size()>0){
        //<5.3> Make rectangles around the different color regions and display them
        displayContoursBoundingBoxes(i);
      }
    }
  }
    
}

void displayContoursBoundingBoxes(int i) {
  
  if(i<maxColors){
  //get the biggest contours for in color image i
    Contour contour = contours.get(0); 
    color_areas[i]=contour.area();

//Display color rectangles, but only if there are bigger than a minimum area
    if(color_areas[i]>minColorArea){

      Rectangle rect = contour.getBoundingBox();
          
      int r=(int)red(colors[i]);
      int g=(int)green(colors[i]);
      int b=(int)blue(colors[i]);
      stroke(r,g,b);
      fill(r,g,b,150);
      strokeWeight(2);
      rect(rect.x, rect.y, rect.width, rect.height);
    }
  }

}



//////////////////////
// Audio Functions
//////////////////////
// <6> Loop through the color_areas and identify the color with the largest area
 void playColorSound(){
   
  
   track_idx=maxColorAreaIdx; // This is the index corresponding to the largest color area
    
 // Loop through all the tracks 
 for (int i=0; i<maxColors; i++){

 // Set the volume to the file volume if the track is paired to the the largest color area 
   if(i==track_idx){ // Play track corresponding to the largest color area, if one is identified 
 
     track_volume=0.0; //gain in decibels
     if(sounds[i].isPlaying()==false){
          
            sounds[i].loop();
            sounds[i].setGain(track_volume);
            
     }else if(sounds[i].isPlaying()==true){
                
        sounds[i].setGain(track_volume);
     }
     
   }
   else{
  // Set the volume to much lower than file volume if the track is NOT paired to the the largest color area    
     track_volume=-60.0;//gain in decibels
     if(sounds[i].isPlaying()==true){                
        sounds[i].setGain(track_volume);
     }
   }
 }
}

//////////////////////////////////////////////
// Functions to interact with the application
// using the Keyboard / Mouse
//////////////////////////////////////////////

void mousePressed() {
    
  if (colorToChange > -1) {
    
    color c = get(mouseX, mouseY);
    println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));
   
    int hue = int(map(hue(c), 0, 255, 0, 180));
    
    colors[colorToChange-1] = c;
    hues[colorToChange-1] = hue;
    
    
    println("color index " + (colorToChange-1) + ", value: " + hue);
  }
}

void keyPressed() {
  
  if (key == '1') {
    colorToChange = 1;
    
  } else if (key == '2') {
    colorToChange = 2;
    
  } else if (key == '3') {
    colorToChange = 3;
    
  } else if (key == '4') {
    colorToChange = 4;
  }
}

void keyReleased() {
  colorToChange = -1; 
}

/////////////////////////////////////////////////////
// Some extra functions to play with
/////////////////////////////////////////////////////
// Sort Colors by Area 
// This function can be swapped with getMaxColoArea()
void rankColorAreas(){
  
  // Rank colors by area 
  color_areas_ranked=color_areas.clone();
  for (int i=0; i<maxColors; i++){
      ranked_colors[i]=i;
  }

  boolean swap_made= true;
  while (swap_made==true){
  for (int i=0; i<maxColors-1; i++){
      if(color_areas_ranked[i]<color_areas_ranked[i+1]){
         
         float temp_float=color_areas_ranked[i];
         color_areas_ranked[i]=color_areas_ranked[i+1];
         color_areas_ranked[i+1]=temp_float; 
         
         int temp_int=ranked_colors[i];
         ranked_colors[i]=ranked_colors[i+1];
         ranked_colors[i+1]=temp_int;
         
         swap_made=true;
         
      }else{
         swap_made=false;
      }
  } 
 }  
}

// Play multiple sounds all at once
// Adjust volume in proportion to color area
// this function can be swapped with playColorSound
 void playColorSoundMultiple(){
 for (int i=0; i<maxColors; i++){
   
   track_idx=ranked_colors[i];
   track_volume=10*log(color_areas_ranked[i]/color_areas_ranked[0]); 
   
   if(track_idx==0 &&
      sounds[track_idx].isPlaying()==false &&
      color_areas_ranked[track_idx]>0.1*color_areas_ranked[0]){
        
          sounds[track_idx].loop();
          sounds[track_idx].setGain(track_volume);
          
   }else if(track_idx>0 &&
            sounds[track_idx].isPlaying()==false &&
            color_areas_ranked[track_idx]>0.1*color_areas_ranked[0]){
        
      // start a new track in sync with the previous track
          skip_amount=sounds[track_idx-1].position();
          sounds[track_idx].skip(skip_amount);      
          sounds[track_idx].loop();
          sounds[track_idx].setGain(track_volume);
      
   }else if(color_areas_ranked[track_idx]>0.1*color_areas_ranked[0] &&
            sounds[track_idx].isPlaying()==true){
      sounds[track_idx].setGain(track_volume);
   }
 }
 }
 