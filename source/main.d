import engine;

import std.datetime : Clock;

void main()
{
    auto root = Root("Spark", 800, 600);
    scope(success) root.dispose();

    auto test = root.loadTexture("test.bmp");
    test.blending = Blend.additive;

    auto oldTick = Clock.currSystemTick();

    auto angle = 0f;

    while (true)
    {
        if (!root.pollEvents())
            break;

        auto newTick = Clock.currSystemTick();
        auto elapsed = (newTick - oldTick).usecs / 1000000f;
        oldTick = newTick;

        angle += elapsed;

        with (root.renderer)
        {
            clear(Color(0, 0, 0, 255));

            test.blending = Blend.none;
            test.tint = Color(255, 255, 255, 255);
            blit(test, 16, 16);

            test.blending = Blend.additive;
            test.tint = Color(255, 0, 0, 255);
            blit(test, 32, 32, angle);

            present();
        }
    }
}
