//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_MG34Weapon extends DHMGWeapon;

#exec OBJ LOAD FILE=..\Animations\DH_Mg34_1st.ukx

// Modified to prevent the exploit of freezing your animations after firing
simulated event StopFire(int Mode) // TODO: check this shouldn't apply to all MGs, as same override is is applied to all other auto & semi-auto weapons
{
    if (FireMode[Mode].bIsFiring)
    {
        FireMode[Mode].bInstantStop = true;
    }

    if (InstigatorIsLocallyControlled() && !FireMode[Mode].bFireOnRelease && !IsAnimating(0)) // adds check that isn't animating
    {
        PlayIdle();
    }

    FireMode[Mode].bIsFiring = false;
    FireMode[Mode].StopFiring();

    if (!FireMode[Mode].bFireOnRelease)
    {
        ZeroFlashCount(Mode);
    }
}

defaultproperties
{
    ItemName="Maschinengewehr 34"
    FireModeClass(0)=class'DH_Weapons.DH_MG34AutoFire'
    FireModeClass(1)=class'DH_Weapons.DH_MG34SemiAutoFire' // this secondary fire mode is not a switch, it is done with another button
    AttachmentClass=class'DH_Weapons.DH_MG34Attachment'
    PickupClass=class'DH_Weapons.DH_MG34Pickup'

    Mesh=SkeletalMesh'DH_Mg34_1st.MG_34_Mesh' // TODO: check whether the DH version of MG34 anim file actually differs from the RO mesh & is worth keeping
    Skins(2)=shader'Weapons1st_tex.MG.mg34_s' // can't specify specularity shader as HighDetailOverlay as includes opacity mask, which doesn't seem to work with HDO system
    Skins(3)=shader'Weapons1st_tex.MG.MGBipod_S' // TODO: bipod specularity shader isn't used in the anim mesh & should be added there
    HighDetailOverlay=shader'Weapons1st_tex.MG.MGBipod_S'
    bUseHighDetailOverlayIndex=true
    HighDetailOverlayIndex=3 // can't specify MG34 specularity shader as HDO as includes opacity mask (doesn't seem to work with HDO system), so may as well specify bipod shader
    HandTex=texture'Weapons1st_tex.Arms.hands_gergloves'

    PlayerIronsightFOV=90.0
    IronSightDisplayFOV=45.0
    bCanFireFromHip=true

    MaxNumPrimaryMags=7
    InitialNumPrimaryMags=7

    InitialBarrels=2
    BarrelClass=class'DH_Weapons.DH_MG34Barrel'
    BarrelSteamBone="Barrel"
    BarrelChangeAnim="Bipod_Barrel_Change"

    IronBringUp="Rest_2_Hip"
    IronPutDown="Hip_2_Rest"
    BipodHipIdle="Hip_Idle"
    BipodHipToDeploy="Hip_2_Bipod"
    MagEmptyReloadAnim="Bipod_Reload"
    MagPartialReloadAnim="Bipod_Reload"
}
