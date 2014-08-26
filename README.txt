VERTICAL SPECTOGRAM ALGORITHM - Image Interpreter and Gcode Generator
Created by Doug Biehl (doug.biehl@gmail.com) - August 2014

Follows vertical paths at intervals down a picture
At each step, assesses how dark the average darkness is neighbors adjacent to the vertical path
Draws a horizontal line whose thickness correlates to the average darnkess of neighbors
Encodes path in gcode and renders/saves results as a .jpg

NOTES:
Images are not scaled and are intepreted at original size!1 pixel of original image = 1 drawbot step
I recommend scaling your image to have it's maximum dimention fit the corresponding maximum travel of your drawbot
My drawbot uses custom defined gcodes;You should edit the gcodes below to match yours
