 extern number time;
 vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
   vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color

   //Creates time-dependent pulse modulation effect
   number phase = time * 3;
   number noise = 0.01 * floor(sin((2*3.14) * 5 * texture_coords.y - phase));
   number height = floor(texture_coords.y * 720);

   //This divides the image into two scan regions
   if (mod(height, 2) != 0){
       color.g = 0;
       color.b = 1 - (floor(noise*160)/16);
       color.r = (0.7 *color.r) - (floor(sin(time) * 4)/6);
       texture_coords.x += noise;
     return Texel(texture, texture_coords) * color;
     } else {
       pixel.r = 0;
       pixel.b = 0.5 * pixel.b;
       pixel.g = 0.5 * pixel.g;
       return pixel;
   }
 }
