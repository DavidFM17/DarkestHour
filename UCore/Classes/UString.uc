//==============================================================================
// UCore
// Darklight Games (c) 2008-2015
//==============================================================================

class UString extends Object
    abstract;

static final function string Join(string Divider, array<string> Strings)
{
    local string S;
    local int i;

    if (Strings.Length == 0)
    {
        return S;
    }

    S $= Strings[0];

    for (i = 1; i < Strings.Length; ++i)
    {
        S $= Divider $ Strings[i];
    }

    return S;
}

static final function string Remove(string S, int Offset, int Count)
{
    return Mid(S, 0, Offset) $ Mid(S, Offset + Count);
}

static final function string Insert(string Dst, string Src, int Offset)
{
    return Left(Dst, Offset) $ Src $ Mid(Dst, Offset, Len(Dst));
}

static final function array<int> ToBytes(string S)
{
    local int i;
    local array<int> Bytes;

    for (i = 0; i < Len(S); ++i)
    {
        Bytes[i] = Asc(Mid(S, i, 1));
    }

    return Bytes;
}

static final function string FromBytes(array<int> Bytes)
{
    local int i;
    local string S;

    for (i = 0; i < Bytes.Length; ++i)
    {
        S $= Chr(Bytes[i]);
    }

    return S;
}
