//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_BritishOfficerWorcesters extends DH_Worcesters;

defaultproperties
{
    RolePawns(0)=(PawnClass=class'DH_BritishPlayers.DH_BritishOfficerWorcestersPawn',Weight=1.0)
    RolePawns(1)=(PawnClass=none,Weight=0.0) // to override inherited 'vest' that isn't valid for officer
    bIsArtilleryOfficer=true
    MyName="Artillery Officer"
    AltName="Artillery Officer"
    Article="an "
    PluralName="Artillery Officers"
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo4Weapon')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo2Weapon')
    GivenItems(0)="DH_Equipment.DHBinocularsItem"
    Headgear(0)=class'DH_BritishPlayers.DH_BritishTommyHelmet'
    Limit=1
}
