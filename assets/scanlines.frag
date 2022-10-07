// Public domain:
// Copyright (C) 2017 by Matthias Richter <vrld@vrld.org>
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.
number width = 2;
extern number phase = 0;
number thickness = 0.25;
number opacity = 1;
vec3 color = vec3(0, 0, 0);

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 _) {
  number v = .5*(sin(tc.y * 3.14159 / width * love_ScreenSize.y + phase) + 1.);
  c = Texel(tex,tc);
  //c.rgb = mix(color, c.rgb, mix(1, pow(v, thickness), opacity));
  c.rgb -= (color - c.rgb) * (pow(v,thickness) - 1.0) * opacity;
  return c;
}
