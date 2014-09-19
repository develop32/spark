module engine.surface;

import derelict.sdl2.sdl;

struct Surface
{
    SDL_Surface* ptr() { return _ptr; }
    int width() { return _ptr.w; }
    int height() { return _ptr.h; }
    private SDL_Surface* _ptr;

    @disable this();
    this(SDL_Surface* instance)
    {
        assert(instance !is null);
        _ptr = instance;
    }

    void dispose()
    {
        assert(_ptr !is null);
        SDL_FreeSurface(_ptr);
        _ptr = null;
    }
}

Surface createSurface(int width, int height)
{
    return Surface(SDL_CreateRGBSurface(0, width, height, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000));
}

Surface loadBMP(const(char)[] fileName)
{
    import std.string : toStringz;
    return Surface(SDL_LoadBMP(fileName.toStringz));
}