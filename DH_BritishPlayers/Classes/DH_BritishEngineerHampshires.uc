//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_BritishEngineerHampshires extends DH_Hampshires;

defaultproperties
{
    MyName="Combat Engineer"
    AltName="Combat Engineer"
    Article="a "
    PluralName="Combat Engineers"
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo4Weapon')
    Grenades(0)=(Item=class'DH_Weapons.DH_M1GrenadeWeapon')
    Grenades(1)=(Item=class'DH_Equipment.DH_USSmokeGrenadeWeapon')
    GivenItems(0)="DH_Equipment.DHWireCuttersItem"
    Headgear(0)=class'DH_BritishPlayers.DH_BritishTurtleHelmet'
    Headgear(1)=class'DH_BritishPlayers.DH_BritishTurtleHelmetNet'
    Headgear(2)=class'DH_BritishPlayers.DH_BritishTommyHelmet'
    Limit=3
}
