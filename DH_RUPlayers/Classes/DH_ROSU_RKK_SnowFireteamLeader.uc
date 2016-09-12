//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_ROSU_RKK_SnowFireteamLeader extends DH_ROSU_RKK_Snow;

function class<ROHeadgear> GetHeadgear()
{
    if (FRand() < 0.2)
    {
        if (FRand() < 0.5)
        {
            return Headgear[2];
        }
        else
        {
            return Headgear[1];
        }
    }
    else
    {
        return Headgear[0];
    }
}

defaultproperties
{
    MyName="Fireteam Leader"
    AltName="Komandir zvena"
    Article="a "
    PluralName="Fireteam Leaders"
    PrimaryWeaponType=WT_SemiAuto
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_SVT40Weapon',Amount=6,AssociatedAttachment=class'ROInventory.SVT40AmmoPouch')
    Grenades(0)=(Item=class'DH_Weapons.DH_F1GrenadeWeapon',Amount=2)
    Headgear(0)=class'DH_RUPlayers.DH_ROSovietFurHat'
    Headgear(1)=class'DH_RUPlayers.DH_ROSovietFurHat'
    Headgear(2)=class'DH_RUPlayers.DH_ROSovietFurHat'
    limit=2
}