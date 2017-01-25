//==============================================================================
// Darklight Games (c) 2008-2016
//==============================================================================

class UString extends Object;

var string Value;

static final function UString Create(optional string Value)
{
    local UString S;

    S = new class'UString';
    S.Value = Value;

    return S;
}

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

static final function int FindFirstOf(string S, string T)
{
    local int i, j;

    for (i = 0; i < Len(T); ++i)
    {
        j = InStr(S, Mid(T, i, 1));

        if (j != -1)
        {
            return j;
        }
    }

    return -1;
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

static final function bool IsWhitespace(string S)
{
    local int A;

    A = Asc(S);

    return (A >= 0x0009 && A <= 0x000D) || (A == 0x0020 || A == 0x1680) ||
           (A >= 0x2000 && A <= 0x200A) || (A >= 0x2028 && A <= 0x2029) ||
           (A == 0x202F || A == 0x205F  || A == 0x3000  || A == 0x180E ||
            A == 0x200B || A == 0x200C  || A == 0x200D  || A == 0x2060 ||
            A == 0xFEFF);
}

static final function bool IsAlpha(string S)
{
    local int A;

    A = Asc(S);

    return (A >= 0x41 && A <= 0x5A) || (A >= 0x61 && A <= 0x7A);
}

static final function bool IsDigit(string S)
{
    local int A;

    A = Asc(S);

    return A >= 0x30 && A <= 0x39;
}

static final function bool IsAlphanumeric(string S)
{
    return IsAlpha(S) || IsDigit(S);
}

static final function string Trim(string S)
{
    local int i, j;

    // Get the index of the first non-whitespace character.
    for (i = 0; i < Len(S); ++i)
    {
        if (!IsWhitespace(Mid(S, i, 1)))
        {
            break;
        }
    }

    // Get the index of the last non-whitespace character.
    for (j = Len(S) - 1; j > i; --j)
    {
        if (!IsWhitespace(Mid(S, j, 1)))
        {
            break;
        }
    }

    return Mid(S, i, j - i + 1);
}

static final function string ZFill(coerce string S, int N)
{
    N -= Len(S);

    while (N-- > 0)
    {
        S = "0" $ S;
    }

    return S;
}

static final function string CRLF()
{
    return Chr(13) $ Chr(10);
}
