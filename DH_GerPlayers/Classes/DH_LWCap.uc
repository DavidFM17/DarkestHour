//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_LWCap extends DHHeadgear;

#exec OBJ LOAD FILE=..\Textures\DHGermanCharactersTex.utx

static function StaticPrecache(LevelInfo L)
{
    L.AddPrecacheMaterial(material'DHGermanCharactersTex.GerHeadGear.LW_HG');
}

defaultproperties
{
    bIsHelmet=false
    Mesh=SkeletalMesh'gear_anm.ger_tankercap_cap'
    Skins(0)=texture'DHGermanCharactersTex.GerHeadgear.LW_HG'
}
