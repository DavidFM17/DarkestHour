//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_WHOfficerC extends DH_HeerCamo;

defaultproperties
{
    bIsArtilleryOfficer=true
    MyName="Artillery Officer"
    AltName="Artillerieoffizier"
    Article="a "
    PluralName="Artillery Officers"
    InfoText="The artillery officer is tasked with directing artillery fire upon the battlefield through the use of long-range observation. Coordinating his efforts with a radio operator, he is able to target locations for off-grid artillery to lay down a  barrage with devastating effect."
    MenuImage=texture'DHGermanCharactersTex.Icons.Zugfuhrer'
    Models(0)="WH_C1"
    Models(1)="WH_C2"
    Models(2)="WH_C3"
    Models(3)="WH_C4"
    SleeveTexture=texture'Weapons1st_tex.Arms.german_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_Kar98Weapon',Amount=18,AssociatedAttachment=class'ROInventory.ROKar98AmmoPouch')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_P38Weapon',Amount=1)
    SecondaryWeapons(1)=(Item=class'DH_Weapons.DH_P08LugerWeapon',Amount=1)
    GivenItems(0)="DH_Engine.DH_BinocularsItem"
    Headgear(0)=class'DH_GerPlayers.DH_HeerOfficercap'
    Headgear(1)=class'DH_GerPlayers.DH_HeerCrushercap'
    PrimaryWeaponType=WT_SMG
    bEnhancedAutomaticControl=true
    Limit=1
}
