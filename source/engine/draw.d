module engine.draw;

import engine.math;
import engine.render;
import engine.texture;

struct Sprite
{
    Texture texture;
    Blend blending;
    Color tint;
    int flip;
}

struct DrawManager
{
}