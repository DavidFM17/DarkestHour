//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHConstructionProxy extends Actor;

var class<DHConstruction>   ConstructionClass;

function SetConstructionClass(class<DHConstruction> ConstructionClass)
{
    self.ConstructionClass = ConstructionClass;

    SetStaticMesh(ConstructionClass.default.StaticMesh);

    // set all skins to simple color skin.
}

defaultproperties
{
    RemoteRole=ROLE_None
}
