//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_RKKA_StandardFireteamLeader extends DH_RKKA_Standard;

defaultproperties
{
    MyName="Corporal"
    AltName="Komandir zvena"
    Article="a "
    PluralName="Corporals"
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_SVT40Weapon',Amount=6,AssociatedAttachment=class'ROInventory.SVT40AmmoPouch')
    Grenades(0)=(Item=class'DH_Weapons.DH_F1GrenadeWeapon',Amount=2)
    Headgear(0)=class'DH_SovietPlayers.DH_SovietSidecap'
    Headgear(1)=class'DH_SovietPlayers.DH_SovietSidecap'
    Headgear(2)=class'DH_SovietPlayers.DH_SovietSidecap'
    Limit=2
}
