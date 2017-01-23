//==============================================================================
// Darklight Games (c) 2008-2016
//==============================================================================

class UInteger extends Object;

var int Value;

static final function UInteger Create(optional int Value)
{
    local UInteger I;

    I = new class'UInteger';
    I.Value = Value;

    return I;
}

static final function ToBytes(int Integer, optional out byte Byte1, optional out byte Byte2, optional out byte Byte3, optional out byte Byte4)
{
    Byte1 = (Integer >> 24) & 0xFF;
    Byte2 = (Integer >> 16) & 0xFF;
    Byte3 = (Integer >> 8) & 0xFF;
    Byte4 = Integer & 0xFF;
}

static final function int FromBytes(optional byte Byte1, optional byte Byte2, optional byte Byte3, optional byte Byte4)
{
    return (Byte1 << 24) | (Byte2 << 16) | (Byte3 << 8) | Byte4;
}

static final function ToShorts(int Integer, optional out int Short1, optional out int Short2)
{
    Short1 = (Integer >> 16) & 0xFFFF;
    Short2 = Integer & 0xFFFF;
}

static final function int FromShorts(optional int Short1, optional int Short2)
{
    return ((Short1 << 16) & 0xFFFF) | (Short2 & 0xFFFF);
}

