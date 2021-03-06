//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_StenMkIIDamType extends DHWeaponProjectileDamageType
    abstract;

defaultproperties
{
    WeaponClass=class'DH_Weapons.DH_StenMkIIWeapon'
    HUDIcon=texture'InterfaceArt_tex.deathicons.b762mm'
    KDamageImpulse=1000.0
    KDeathVel=100.0
    KDeathUpKick=0.0
}
