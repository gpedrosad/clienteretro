// Retro76: como se ve a si mismo un GM con /invisible (los demas no lo ven): el outfit con sus colores,
// lavado hacia un gris azulado y a medias transparente. Lo prende game_shaders/shaders.lua.
uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform sampler2D u_Tex0;
void main()
{
    gl_FragColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    if(texcolor.r > 0.9) {
        gl_FragColor *= texcolor.g > 0.9 ? u_Color[0] : u_Color[1];
    } else if(texcolor.g > 0.9) {
        gl_FragColor *= u_Color[2];
    } else if(texcolor.b > 0.9) {
        gl_FragColor *= u_Color[3];
    }
    if(gl_FragColor.a < 0.01) discard;
    float grey = dot(gl_FragColor.rgb, vec3(0.299, 0.587, 0.114));
    gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(grey) * vec3(0.85, 0.95, 1.15), 0.5);
    gl_FragColor.a *= 0.45;
}
