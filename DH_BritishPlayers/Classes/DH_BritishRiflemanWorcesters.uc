//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_BritishRiflemanWorcesters extends DH_Worcesters;

defaultproperties
{
    MyName="Rifleman"
    AltName="Rifleman"
    Article="a "
    PluralName="Riflemen"
    InfoText="The rifleman is the basic soldier of the battlefield that is tasked with the important role of capturing and holding objectives, as well as the defense of key positions. Armed with the standard-issue battle rifle, the rifleman's efficiency is determined by his ability to work as a member of a larger unit."
    MenuImage=texture'DHBritishCharactersTex.Icons.Brit_Rifleman'
    Models(0)="Wor_1"
    Models(1)="Wor_2"
    Models(2)="Wor_3"
    Models(3)="Wor_4"
    Models(4)="Wor_5"
    Models(5)="Wor_6"
    SleeveTexture=texture'DHBritishCharactersTex.Sleeves.brit_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo4Weapon',Amount=6)
    Grenades(0)=(Item=class'DH_Weapons.DH_M1GrenadeWeapon',Amount=1)
    Headgear(0)=class'DH_BritishPlayers.DH_BritishTurtleHelmet'
    Headgear(1)=class'DH_BritishPlayers.DH_BritishTurtleHelmetNet'
    Headgear(2)=class'DH_BritishPlayers.DH_BritishTommyHelmet'
}
