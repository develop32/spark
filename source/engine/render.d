module engine.render;

import engine.math;
import engine.texture;

import derelict.sdl2.sdl;

enum Flip
{
    none = SDL_FLIP_NONE,
    h = SDL_FLIP_HORIZONTAL,
    v = SDL_FLIP_VERTICAL
}

enum Blend
{
    none = SDL_BLENDMODE_NONE,
    alpha = SDL_BLENDMODE_BLEND,
    additive = SDL_BLENDMODE_ADD
}

struct Renderer
{
    SDL_Renderer* ptr() { return _ptr; }
    private SDL_Renderer* _ptr;

    @disable this();
    this(SDL_Renderer* instance)
    {
        assert(instance !is null);
        _ptr = instance;
    }

    void clear(Color color)
    {
        assert(_ptr !is null);

        SDL_SetRenderDrawColor(_ptr, cast(ubyte)color.x, cast(ubyte)color.y, cast(ubyte)color.z, cast(ubyte)color.w);
        SDL_RenderClear(_ptr);
    }

    void blit(Texture texture, Vector4i source, Vector4i dest, float angle, Vector2i origin, int flip)
    {
        assert(_ptr !is null);
        assert(texture.ptr !is null);
        assert(source.x >= 0);
        assert(source.y >= 0);
        assert(source.z >= 0);
        assert(source.w >= 0);
        assert(source.x + source.z <= texture.width);
        assert(source.y + source.w <= texture.height);
        assert(dest.z >= 0);
        assert(dest.w >= 0);

        import std.math : isNaN;
        assert(!angle.isNaN);

        SDL_Rect src;
        src.x = source.x;
        src.y = source.y;
        src.w = source.z;
        src.h = source.w;

        SDL_Rect dst;
        dst.x = dest.x;
        dst.y = dest.y;
        dst.w = dest.z;
        dst.h = dest.w;

        SDL_Point center;
        center.x = origin.x;
        center.y = origin.y;

        import std.math : PI;
        SDL_RenderCopyEx(_ptr, texture.ptr, &src, &dst, angle * 180f / PI, &center, flip);
    }

    void blit(Texture texture, int x, int y, int width, int height, float angle, Vector2i origin, Flip flip = Flip.none)
    {
        blit(texture, Vector4i(0, 0, texture.width, texture.height), Vector4i(x, y, width, height), angle, origin, flip);
    }

    void blit(Texture texture, int x, int y, float angle, Vector2i origin, Flip flip = Flip.none)
    {
        blit(texture, Vector4i(0, 0, texture.width, texture.height), Vector4i(x, y, texture.width, texture.height), angle, origin, flip);
    }

    void blit(Texture texture, int x, int y, float angle, Flip flip = Flip.none)
    {
        blit(texture, Vector4i(0, 0, texture.width, texture.height), Vector4i(x, y, texture.width, texture.height), angle, Vector2i(texture.width / 2, texture.height / 2), flip);
    }

    void blit(Texture texture, int x, int y, int width, int height, Flip flip = Flip.none)
    {
        blit(texture, Vector4i(0, 0, texture.width, texture.height), Vector4i(x, y, width, height), 0, Vector2i(texture.width / 2, texture.height / 2), flip);
    }

    void blit(Texture texture, int x, int y, Flip flip = Flip.none)
    {
        blit(texture, Vector4i(0, 0, texture.width, texture.height), Vector4i(x, y, texture.width, texture.height), 0, Vector2i(texture.width / 2, texture.height / 2), flip);
    }

    void present()
    {
        assert(_ptr !is null);
        SDL_RenderPresent(_ptr);
    }
}