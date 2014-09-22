module engine.state;

import engine.math;
import engine.world;
import engine.component;

struct States
{
	mixin ComponentManager!(Vector2, "position");
}