//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_ShermanTank_M4A376W extends DH_ShermanTank_M4A375W; // later 76mm version with HVAP instead of smoke rounds

defaultproperties
{
    VehicleNameString="M4A3(76)W Sherman"
    PassengerWeapons(0)=(WeaponPawnClass=class'DH_Vehicles.DH_ShermanCannonPawnA_76mm')
    DestroyedVehicleMesh=StaticMesh'DH_allies_vehicles_stc3.ShermanM4A3.M4A3_761dest'
    VehicleHudTurret=TexRotator'DH_InterfaceArt_tex.Tank_Hud.Sherman76_turret_rot'
    VehicleHudTurretLook=TexRotator'DH_InterfaceArt_tex.Tank_Hud.Sherman76_turret_look'
    SpawnOverlay(0)=material'DH_InterfaceArt_tex.Vehicles.sherman_m4a3_76w'
}
