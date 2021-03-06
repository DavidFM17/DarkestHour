//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_PantherGTank_SnowTwo extends DH_PantherGTank;

defaultproperties
{
    DestroyedVehicleMesh=StaticMesh'DH_German_vehicles_stc.PantherG.PantherG_Destroyed7'
    Skins(0)=texture'DH_VehiclesGE_tex3.ext_vehicles.PantherG_body_snow2'
    Skins(1)=texture'axis_vehicles_tex.Treads.PantherG_treadsnow'
    Skins(2)=texture'axis_vehicles_tex.Treads.PantherG_treadsnow'
    CannonSkins(0)=texture'DH_VehiclesGE_tex3.ext_vehicles.PantherG_body_snow2'
    RandomAttachment=(Skin=none) // TODO: we don't have a schurzen skin for this camo variant, so add here if one gets made
}
