//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_FJCap extends DHHeadgear;

// Current cap doesn't fit new FJ model, so this is temporarily displaying as a grey helmet instead

static function StaticPrecache(LevelInfo L)
{
//  L.AddPrecacheMaterial(material'DHGermanCharactersTex.GerHeadgear.LW_HG');
//  L.AddPrecacheMaterial(material'DHGermanCharactersTex.GerHeadgear.FJ_Helmet1');
}

defaultproperties
{
    Mesh=SkeletalMesh'dhgear_anm.Ger_Fallsch_Helmet'
    Skins(0)=texture'DHGermanCharactersTex.GerHeadgear.FJ_Helmet1'
}
