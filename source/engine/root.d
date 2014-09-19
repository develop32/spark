module engine.root;

import engine.render;
import engine.world;

import derelict.sdl2.sdl;

import std.exception : enforce;

shared static this()
{
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_EVERYTHING);
}

struct Root
{
	private SDL_Window* _window;
	private SDL_Renderer* _renderer;

    World world() nothrow { return _world; }
    private World _world;

	@disable this();

    this(string title, int width, int height)
    {
        assert(width > 0);
        assert(height > 0);

        enum flags = SDL_WINDOW_SHOWN;

        enforce(SDL_CreateWindowAndRenderer(width, height, flags, &_window, &_renderer) == 0, "Failed to initialize SDL window and renderer!");

        import std.string : toStringz;
        SDL_SetWindowTitle(_window, title.toStringz);

        _world = World.create();
    }

    Renderer renderer()
    {
        return Renderer(_renderer);
    }

    bool pollEvents()
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
            switch (event.type)
            {
                case SDL_QUIT: return false;
                case SDL_WINDOWEVENT:
                    switch (event.window.event)
                    {
                        case SDL_WINDOWEVENT_CLOSE: issueQuit(); break;
                        default:
                    }
                    break;
                default:
            }

        return true;
    }

    void dispose()
    {
        assert(_window !is null);
        assert(_renderer !is null);

        SDL_DestroyRenderer(_renderer);
        SDL_DestroyWindow(_window);

        _renderer = null;
        _window = null;
    }
}

void issueQuit()
{
    SDL_Event event;
    event.type = SDL_QUIT;
    SDL_PushEvent(&event);
}