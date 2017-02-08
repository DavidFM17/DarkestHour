//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_M7PriestCannon extends DHVehicleCannon;

defaultproperties
{
    // Turret mesh
    Mesh=SkeletalMesh'DH_M7Priest_anm.priest_turret'
    Skins(0)=texture'DH_M7Priest_tex.ext_vehicles.M7Priest'
    Skins(1)=texture'DH_M7Priest_tex.ext_vehicles.M7Priest2'
//  CollisionStaticMesh=StaticMesh'DH_allies_vehicles_stc.Sherman.Sherman_turret_75mm_Coll' // TODO: make col mesh for gun shield? (barely moves so better adding as part of hull mesh)
    FireAttachBone="Turret_placement"
    FireEffectScale=2.5 // turret fire is larger & positioned in centre of open superstructure
    FireEffectOffset=(X=-55.0,Y=-15.0,Z=100.0)

    // Cannon armour (gun shield) // TODO: set these (or remove altogether if we don't go with a separate collision for gun shield)
    GunMantletArmorFactor=2.54
    GunMantletSlope=30.0

    // Turret movement
    bHasTurret=false
    ManualRotationsPerSecond=0.02
    bLimitYaw=true
    MaxPositiveYaw=5461        // 30 degrees
    MaxNegativeYaw=-2730       // -15 degrees
    YawStartConstraint=-3000.0
    YawEndConstraint=6000.0
    CustomPitchUpLimit=6371    // 35 degrees
    CustomPitchDownLimit=64625 // -5 degrees

    // Cannon ammo
    ProjectileClass=class'DH_Vehicles.DH_M7PriestCannonShellHE'
    PrimaryProjectileClass=class'DH_Vehicles.DH_M7PriestCannonShellHE'
    SecondaryProjectileClass=class'DH_Vehicles.DH_ShermanM4A3105CannonShellHEAT'
    TertiaryProjectileClass=class'DH_Vehicles.DH_ShermanM4A3105CannonShellSmoke'
    ProjectileDescriptions(0)="HE"
    ProjectileDescriptions(1)="HEAT" // TODO: suggest make HEAT round tertiary for consistency with Sherman 105mm & other howitzer/support weapons (HEAT would very much be last resort) - Matt
    ProjectileDescriptions(2)="Smoke"
    InitialPrimaryAmmo=58
    InitialSecondaryAmmo=3
    InitialTertiaryAmmo=8
    Spread=0.005
    SecondarySpread=0.005
    TertiarySpread=0.005

    // Weapon fire
    WeaponFireOffset=18.0
    AddedPitch=68

    // Sounds
    CannonFireSound(0)=SoundGroup'Vehicle_Weapons.Tiger.88mm_fire01'
    CannonFireSound(1)=SoundGroup'Vehicle_Weapons.Tiger.88mm_fire02'
    CannonFireSound(2)=SoundGroup'Vehicle_Weapons.Tiger.88mm_fire03'
    ReloadStages(0)=(Sound=sound'Vehicle_reloads.Reloads.Pz_IV_F2_Reload_01')
    ReloadStages(1)=(Sound=sound'Vehicle_reloads.Reloads.Pz_IV_F2_Reload_02')
    ReloadStages(2)=(Sound=sound'Vehicle_reloads.Reloads.Pz_IV_F2_Reload_03')
    ReloadStages(3)=(Sound=sound'Vehicle_reloads.Reloads.Pz_IV_F2_Reload_04')
}