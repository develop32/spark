module engine.component;

import engine.math;

template iterateTypeName(string arg, T...)
{
	string genLine()
	{
		string result;
		foreach (ch; arg)
			if (ch == '@')
			{
				import std.traits : fullyQualifiedName;
				result ~= fullyQualifiedName!(T[0]);
			}
			else if (ch == '%')
				result ~= T[1];
			else
				result ~= ch;
		return result;
	}
	enum line = genLine();
	static if (T.length > 2)
		enum add = iterateTypeName!(arg, T[2..$]);
	else
		enum add = "";
	enum iterateTypeName = line ~ add;
}

mixin template ComponentManager(Args...)
{
	static assert(Args.length > 0);
	static assert(Args.length % 2 == 0);

	private size_t[Entity] _id;
	private Entity[size_t] _entity;
	private size_t _count;

	mixin(iterateTypeName!("private @[] _%s;", Args));

	@disable this();
	private this(bool temp) { }
	static States create()
	{
		import core.memory : GC;

		States states = States(false);
		mixin(iterateTypeName!("states._%s = []; GC.extend(states._%s.ptr, 1, 1); GC.setAttr(states._%s.ptr, GC.BlkAttr.NO_SCAN);", Args));
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

	mixin(iterateTypeName!("@ %(Entity entity) { return _%s[id(entity)]; }\n" ~
					       "@ %(size_t id) { assert(id < _%s.length); return _%s[id]; }\n" ~
					       "void %(Entity entity, @ value) { _%s[id(entity)] = value; }\n" ~
					       "void %(size_t id, @ value) { assert(id < _%s.length); _%s[id] = value; }",
					       Args));

	size_t register(Entity entity)
	{
		assert(entity !in _id);
		auto id = _count;
		assert(id !in _entity);

		_id[entity] = id;
		_entity[id] = entity;

		mixin(iterateTypeName!("_%s.assumeSafeAppend(); _%s ~= @.init;", Args));
		_count++;

		return id;
	}

	void unregister(Entity entity)
	{
		auto idPtr = entity in _id;
		assert(idPtr !is null);
		auto id = *idPtr;

		assert(id < _count);
		auto lastId = _count - 1;
		if (id == lastId) return;

		auto lastEntityPtr = lastId in _entity;
		assert(lastEntityPtr !is null);
		auto lastEntity = *lastEntityPtr;

		_count--;
		mixin(iterateTypeName!("_%s[id] = _%s[lastId]; _%s.length = _count;", Args));

		_id[lastEntity] = id;
		_entity[id] = lastEntity;
		_id.remove(entity);
		_entity.remove(lastId);
	}
}