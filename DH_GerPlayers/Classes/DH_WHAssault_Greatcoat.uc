//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_WHAssault_Greatcoat extends DH_HeerGreatcoat;

defaultproperties
{
     MyName="Assault Trooper"
     AltName="Sto�truppe"
     Article="an "
     PluralName="Assault Troops"
     PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_STG44Weapon',AssociatedAttachment=class'ROInventory.ROSTG44AmmoPouch')
     PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_MP40Weapon',AssociatedAttachment=class'ROInventory.ROMP40AmmoPouch')
     Grenades(0)=(Item=class'DH_Weapons.DH_StielGranateWeapon')
     Headgear(0)=class'DH_GerPlayers.DH_HeerHelmetThree'
     Headgear(1)=class'DH_GerPlayers.DH_HeerHelmetTwo'
     Limit=4
}
