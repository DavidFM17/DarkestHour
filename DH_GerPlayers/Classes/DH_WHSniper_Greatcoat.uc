//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_WHSniper_Greatcoat extends DH_HeerGreatcoat;

defaultproperties
{
    MyName="Sniper"
    AltName="Scharfsch�tze"
    Article="a "
    PluralName="Snipers"
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_Kar98ScopedWeapon',AssociatedAttachment=class'ROInventory.ROKar98AmmoPouch')
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_G43ScopedWeapon')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_P38Weapon')
    SecondaryWeapons(1)=(Item=class'DH_Weapons.DH_P08LugerWeapon')
    Headgear(0)=class'DH_GerPlayers.DH_HeerHelmetOne'
    Headgear(1)=class'DH_GerPlayers.DH_HeerHelmetTwo'
    Limit=1
}
