module engine.world;

import engine.root;

private enum entityIndexBits = 22;
private enum entityIndexMask = (1 << entityIndexBits) - 1;
private enum entityGenerationBits = 8;
private enum entityGenerationMask = (1 << entityGenerationBits) - 1;
private enum minimumFreeIndices = 1024;

enum isComponentManager(T) = is(T == struct);

private bool checkIfUpdateable(T)()
{
    T inst;
    return __traits(compiles, inst.update(float.init));
}
enum isUpdateableComponentManager(T) = isComponentManager && checkIfUpdateable!T;

struct Entity
{
    uint id;

    uint index() const pure nothrow { return id & entityIndexMask; }
    uint generation() const pure nothrow { return (id >> entityIndexBits) & entityGenerationMask; }
}

struct World
{
    private interface Updateable
    {
        void update(float elapsed);
    }

    struct Data
    {
        ubyte[] generation;
        size_t freeIndexCount;

        import std.container : SList;
        SList!uint freeIndices;

        size_t[TypeInfo_Struct] managers;
        Updateable[TypeInfo_Struct] updateables;
    }

    private Data* _data;

    private this(bool temp) { }

    @disable this();

    static World create()
    {
        import core.memory : GC;

        World world = World(true);
        world._data = new Data;
        world._data.generation = [];
        GC.extend(world._data.generation.ptr, 1, 1);
        GC.setAttr(world._data.generation.ptr, GC.BlkAttr.NO_SCAN);
        return world;
    }

    T* register(T)(T instance)
    {
        static assert(isComponentManager!T);

        enum ti = typeid(T);
        assert(ti !in _data.managers);
        auto inst = (T*)GC.malloc(T.sizeof);
        *inst = instance;
        _data.managers[ti] = inst;

        static if (isUpdateableComponentManager!T)
        {
            final class Impl : Updateable
            {
                T* inst;

                this(T* inst)
                {
                    this.inst = inst;
                }

                void update(float elapsed)
                {
                    inst.update(elapsed);
                }
            }

            _data.updateables[ti] = new Impl(inst);
        }

        return inst;
    }

    void unregister(T)()
    {
        static assert(isComponentManager);

        enum ti = typeid(T);
        auto ptr = ti in _data.managers;
        assert(ptr);
        _data.managers.remove(*ptr);

        static if (isUpdateableComponentManager!T)
        {
            auto u = ti in _data.updateables;
            assert(u);
            _data.updateables.remove(*u);
        }
    }

    T* get(T)()
    {
        static assert(isComponentManager);

        enum ti = typeid(T);
        auto ptr = ti in _managers;
        if (ptr is null) return null;
        return *ptr;
    }

    Entity createEntity()
    {
        uint index;

        if (_data.freeIndexCount > minimumFreeIndices)
        {
            _data.freeIndexCount--;
            index = _data.freeIndices.removeAny();
            assert(index < _data.generation.length);
        }
        else
        {
            _data.generation ~= 0;
            index = _data.generation.length - 1;
            assert(index < (1 << entityIndexBits));
        }

        return Entity(index + _data.generation[index] << entityIndexBits);
    }

    bool alive(Entity entity) const pure nothrow
    {
        assert(_data.generation.length > entity.index);
        return _data.generation[entity.index] == entity.generation;
    }

    void destroy(Entity entity)
    {
        auto index = entity.index();
        assert(_data.generation.length > index);
        _data.generation[index]++;
        _data.freeIndices.insertFront(index);
        _data.freeIndexCount++;
    }

    void update(float elapsed)
    {
        foreach (u; _data.updateables.byValue)
            u.update(elapsed);
    }
}