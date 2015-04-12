//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHCanisterShotDamageType extends DHWeaponProjectileDamageType
    abstract;

defaultproperties
{
    HUDIcon=texture'DH_InterfaceArt_tex.deathicons.canisterkill'
    DeathString="%o was filled with holes by %k's canister shot."
    KDamageImpulse=2250.0
}