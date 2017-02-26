//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_StuartCannon extends DHVehicleCannon;

defaultproperties
{
    // Turret mesh
    Mesh=SkeletalMesh'DH_Stuart_anm.Stuart_turret_ext'
    Skins(0)=texture'DH_VehiclesUS_tex.ext_vehicles.M5_body_ext'
    Skins(1)=texture'DH_VehiclesUS_tex.int_vehicles.M5_turret_int'
    CollisionStaticMesh=StaticMesh'DH_allies_vehicles_stc.M5_Stuart.Stuart_turret_col'

    // Turret armor
    FrontArmorFactor=5.1
    RightArmorFactor=3.2
    LeftArmorFactor=3.2
    RearArmorFactor=3.2
    FrontArmorSlope=10.0
    FrontLeftAngle=323.0
    FrontRightAngle=37.0
    RearRightAngle=143.0
    RearLeftAngle=217.0

    // Turret movement
    ManualRotationsPerSecond=0.04
    PoweredRotationsPerSecond=0.083
    CustomPitchUpLimit=3641
    CustomPitchDownLimit=63352

    // Cannon ammo
    ProjectileClass=class'DH_Vehicles.DH_StuartCannonShell'
    PrimaryProjectileClass=class'DH_Vehicles.DH_StuartCannonShell'
    SecondaryProjectileClass=class'DH_Vehicles.DH_StuartCannonShellHE'
    TertiaryProjectileClass=class'DH_Engine.DHCannonShellCanister'
    ProjectileDescriptions(2)="Canister"
    InitialPrimaryAmmo=64
    InitialSecondaryAmmo=44
    InitialTertiaryAmmo=15
    SecondarySpread=0.00145
    TertiarySpread=0.04

    // Coaxial MG ammo
    AltFireProjectileClass=class'DH_Weapons.DH_30CalBullet'
    InitialAltAmmo=250
    NumMGMags=7
    AltFireInterval=0.12
    TracerProjectileClass=class'DH_Weapons.DH_30CalTracerBullet'
    TracerFrequency=5

    // Weapon fire
    WeaponFireOffset=12.5
    AddedPitch=18
    EffectEmitterClass=class'ROEffects.TankCannonFireEffectTypeC' // smaller muzzle flash effect
    AltFireOffset=(X=-59.0,Y=7.0,Z=0.5)
    ShakeRotRate=(Z=600.0)
    ShakeOffsetMag=(Z=5.0)
    ShakeOffsetTime=6.0
    AltShakeRotMag=(X=0.01,Y=0.01,Z=0.01)
    AltShakeRotRate=(X=1000.0,Y=1000.0,Z=1000.0)

    // Sounds
    CannonFireSound(0)=SoundGroup'Inf_Weapons.PTRD.PTRD_fire01'
    CannonFireSound(1)=SoundGroup'Inf_Weapons.PTRD.PTRD_fire02'
    CannonFireSound(2)=SoundGroup'Inf_Weapons.PTRD.PTRD_fire03'
    AltFireSoundClass=SoundGroup'DH_WeaponSounds.30Cal.30cal_FireLoop01'
    AltFireEndSound=SoundGroup'DH_WeaponSounds.30Cal.30cal_FireEnd01'
    ReloadStages(0)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_01s_01')
    ReloadStages(1)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_01s_02')
    ReloadStages(2)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_01s_03')
    ReloadStages(3)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_01s_04')
}
