# ColorBeats
Detect colors and play audio corresponding to the most prominent color

Color tracking implemented by 
Greg Borenstein
https://github.com/atduskgreg/opencv-processing-book/blob/master/code/hsv_color_tracking/HSVColorTracking/HSVColorTracking.pde
Modified color tracking and added audio for PlayersOfTheLight by Sana Sarfraz, Bob Rumer and Linda Erlich

In order to run this implementation, you will need to download the Processing IDE https://processing.org/download/?processing

Go to Sketch->Import Libraries->Install Video library for video handling
Go to Sketch->Import Libraries->Install Minim library for audio handling
Go to Sketch->Import Libraries->Install OpenCV library for computer vision processing

color_beat.pde is the main file. It initializes the cameras and data stuructes, plays the video, detects colors and plays audio files corresponding to colors.

Colors are selected and assigned numbers 1,2 and 3 by pressing and holding the number key while clicking on a color on the video. 

Click the play button on color_beat.pde to start the show! 
