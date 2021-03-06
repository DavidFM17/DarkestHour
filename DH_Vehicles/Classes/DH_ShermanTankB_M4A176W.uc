//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_ShermanTankB_M4A176W extends DH_ShermanTankA_M4A176W; // later version with HVAP instead of smoke rounds, & with muzzle brake & sandbags on hull front

defaultproperties
{
    PassengerWeapons(0)=(WeaponPawnClass=class'DH_Vehicles.DH_ShermanCannonPawnB_76mm')
    DestroyedVehicleMesh=StaticMesh'DH_allies_vehicles_stc2.ShermanM4A1W.ShermanM4A1W_DestB'
    DriverPositions(0)=(PositionMesh=SkeletalMesh'DH_ShermanM4A1_anm.ShermanM4A1_body_intB')
    DriverPositions(1)=(PositionMesh=SkeletalMesh'DH_ShermanM4A1_anm.ShermanM4A1_body_intB')
    DriverPositions(2)=(PositionMesh=SkeletalMesh'DH_ShermanM4A1_anm.ShermanM4A1_body_intB')
    Mesh=SkeletalMesh'DH_ShermanM4A1_anm.ShermanM4A1_body_extB'
    SpawnOverlay(0)=material'DH_InterfaceArt_tex.Vehicles.sherman_m4a1_76_b'
}
