const fs = require('fs');
// Mock the export logic or directly use ImageMagick with a better mask.
// Since the transparent background mask was making the inner white transparent, 
// let's use Imagemagick but with a Floodfill algorithm starting strictly from coordinates 0,0!
