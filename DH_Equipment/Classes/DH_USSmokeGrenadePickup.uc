//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_USSmokeGrenadePickup extends DHOneShotWeaponPickup
   notplaceable;

defaultproperties
{
    InventoryType=class'DH_Equipment.DH_USSmokeGrenadeWeapon'
    PickupSound=sound'Inf_Weapons_Foley.Misc.ammopickup'
    StaticMesh=StaticMesh'DH_WeaponPickups.Weapons.USSmokeGrenade'
    PrePivot=(Z=3.000000)
    CollisionRadius=15.000000
    CollisionHeight=3.000000
}
