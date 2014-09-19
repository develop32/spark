module engine.texture;

import engine.root;
import engine.surface;
import engine.math;
import engine.render;

import derelict.sdl2.sdl;

import std.typecons : Nullable;
import std.exception : enforce;

struct Texture
{
    SDL_Texture* ptr() { return _ptr; }
    private SDL_Texture* _ptr;

    private Nullable!Vector2i _size;

    @disable this();
    this(SDL_Texture* instance)
    {
        assert(instance !is null);
        _ptr = instance;
    }

    Color tint()
    {
        Color value;
        enforce(SDL_GetTextureColorMod(_ptr, cast(ubyte*)&value.vector[0], cast(ubyte*)&value.vector[1], cast(ubyte*)&value.vector[2]) == 0);
        enforce(SDL_GetTextureAlphaMod(_ptr, cast(ubyte*)&value.vector[3]) == 0);
        return value;
    }

    void tint(Color value)
    {
        enforce(SDL_SetTextureColorMod(_ptr, cast(ubyte)value.x, cast(ubyte)value.y, cast(ubyte)value.z) == 0);
        enforce(SDL_SetTextureAlphaMod(_ptr, cast(ubyte)value.w) == 0);   
    }

    Blend blending()
    {
        int value;
        enforce(SDL_GetTextureBlendMode(_ptr, &value) == 0);
        return cast(Blend)value;
    }

    void blending(Blend value)
    {
        enforce(SDL_SetTextureBlendMode(_ptr, value) == 0);
    }

    Vector2i size()
    {
        if (!_size.isNull)
            return _size.get();

        assert(_ptr !is null);

        int w, h;
        SDL_QueryTexture(_ptr, null, null, &w, &h);
        _size = Vector2i(w, h);
        return _size.get();
    }

    int width() { return size.x; }
    int height() { return size.y; }

    void update(const Color[] data)
    {
        assert(_ptr !is null);
        assert(data.length == width * height * Color.sizeof);

        SDL_UpdateTexture(_ptr, null, data.ptr, width * Color.sizeof);
    }

    void update(Vector4i region, const Color[] data)
    {
        assert(_ptr !is null);
        assert(region.x >= 0);
        assert(region.y >= 0);
        assert(region.z > 0);
        assert(region.w > 0);
        assert(region.x + region.z <= width);
        assert(region.y + region.w <= height);
        assert(data.length == region.z * region.w * Color.sizeof);

        SDL_Rect rect;
        rect.x = region.x;
        rect.y = region.y;
        rect.w = region.z;
        rect.h = region.w;

        SDL_UpdateTexture(_ptr, &rect, data.ptr, region.z * Color.sizeof);
    }

    void dispose()
    {
        assert(_ptr !is null);
        SDL_DestroyTexture(_ptr);
        _ptr = null;
    }
}

Texture createTexture(Root root, Surface surface)
{
    return Texture(SDL_CreateTextureFromSurface(root.renderer.ptr, surface.ptr));
}

Texture createTexture(Root root, int width, int height)
{
    return Texture(SDL_CreateTexture(root.renderer.ptr, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STATIC, width, height));
}

Texture loadTexture(Root root, const(char)[] fileName)
{
    import std.path : extension;

    auto ext = fileName.extension;

    if (ext == ".bmp")
        return root.createTexture(loadBMP(fileName));
    else
        assert(false);
}