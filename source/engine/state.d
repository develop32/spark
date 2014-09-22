module engine.state;

import engine.math;
import engine.world;
import engine.component;

struct States
{
	mixin ComponentManager!(Vector2, "position");

	private size_t[Entity] _id;
	private Entity[size_t] _entity;
	private Vector2[] _positions;

	@disable this();
	private this(bool temp) { }
	static States create()
	{
		import core.memory : GC;

		States states = States(false);
		states._positions = [];
        GC.extend(states._positions.ptr, 1, 1);
        GC.setAttr(states._positions.ptr, GC.BlkAttr.NO_SCAN);
        return states;
	}

	bool registered(Entity entity)
	{
		return (entity in _id) !is null;
	}

	size_t id(Entity entity)
	{
		auto ptr = entity in _id;
		assert(ptr !is null);
		return *ptr;
	}

	Vector2 position(Entity entity)
	{
		return _positions[id(entity)];	
	}

	Vector2 position(size_t id)
	{
		assert(id < _positions.length);
		return _positions[id];
	}

	void position(Entity entity, Vector2 value)
	{
		_positions[id(entity)] = value;
	}

	void position(size_t id, Vector2 value)
	{
		assert(id < _positions.length);
		_positions[id] = value;
	}

	size_t register(Entity entity)
	{
		assert(entity !in _id);
		auto id = _positions.length;
		assert(id !in _entity);

		_id[entity] = id;
		_entity[id] = entity;

		_positions.assumeSafeAppend();
		_positions ~= Vector2.init;

		return id;
	}

	void unregister(Entity entity)
	{
		auto idPtr = entity in _id;
		assert(idPtr !is null);
		auto id = *idPtr;

		assert(id < _positions.length);
		auto lastId = _positions.length - 1;
		if (id == lastId) return;

		auto lastEntityPtr = lastId in _entity;
		assert(lastEntityPtr !is null);
		auto lastEntity = *lastEntityPtr;

		_positions[id] = _positions[lastId];
		_id[lastEntity] = id;
		_entity[id] = lastEntity;

		_id.remove(entity);
		_entity.remove(lastId);
	}
}