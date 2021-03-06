//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_ShermanFireFlyCannon extends DHVehicleCannon;

defaultproperties
{
    // Turret mesh
    Mesh=SkeletalMesh'DH_ShermanFirefly_anm.ShermanFirefly_turret_ext'
    Skins(0)=texture'DH_VehiclesUK_tex.ext_vehicles.FireFly_body_ext'
    Skins(1)=texture'DH_VehiclesUK_tex.ext_vehicles.FireFly_armor_ext'
    Skins(2)=texture'DH_VehiclesUS_tex.int_vehicles.Sherman_turret_int'
    WeaponAttachOffset=(X=4.5,Y=2.0,Z=3.0)
    CollisionStaticMesh=StaticMesh'DH_allies_vehicles_stc.Sherman.Firefly_turret_Col'

    // Turret armor
    FrontArmorFactor=7.6
    RightArmorFactor=5.1
    LeftArmorFactor=5.1
    RearArmorFactor=6.4
    RightArmorSlope=5.0
    LeftArmorSlope=5.0
    FrontLeftAngle=316.0
    FrontRightAngle=44.0
    RearRightAngle=136.0
    RearLeftAngle=224.0

    // Turret movement
    ManualRotationsPerSecond=0.025
    PoweredRotationsPerSecond=0.056
    CustomPitchUpLimit=4551
    CustomPitchDownLimit=64625

    // Cannon ammo
    ProjectileClass=class'DH_Vehicles.DH_ShermanFireFlyCannonShell'
    PrimaryProjectileClass=class'DH_Vehicles.DH_ShermanFireFlyCannonShell'
    SecondaryProjectileClass=class'DH_Vehicles.DH_ShermanFireFlyCannonShellAPDS'
    TertiaryProjectileClass=class'DH_Vehicles.DH_ShermanFireFlyCannonShellHE'
    ProjectileDescriptions(1)="APDS"
    ProjectileDescriptions(2)="HE"
    InitialPrimaryAmmo=48
    InitialSecondaryAmmo=4
    InitialTertiaryAmmo=25
    SecondarySpread=0.006
    TertiarySpread=0.00156

    // Coaxial MG ammo
    AltFireProjectileClass=class'DH_Weapons.DH_30CalBullet'
    InitialAltAmmo=250
    NumMGMags=8
    AltFireInterval=0.12
    TracerProjectileClass=class'DH_Weapons.DH_30CalTracerBullet'
    TracerFrequency=5

    // Weapon fire
    WeaponFireOffset=6.0
    AltFireOffset=(X=-181.0,Y=-23.0,Z=0.0)
    AltFireSpawnOffsetX=48.0
    AltShakeRotMag=(X=0.01,Y=0.01,Z=0.01)
    AltShakeRotRate=(X=1000.0,Y=1000.0,Z=1000.0)

    // Sounds
    CannonFireSound(0)=SoundGroup'DH_AlliedVehicleSounds.17pounder.DH17pounder'
    CannonFireSound(1)=SoundGroup'DH_AlliedVehicleSounds.17pounder.DH17pounder'
    CannonFireSound(2)=SoundGroup'DH_AlliedVehicleSounds.17pounder.DH17pounder'
    AltFireSoundClass=SoundGroup'DH_WeaponSounds.30Cal.30cal_FireLoop01'
    AltFireEndSound=SoundGroup'DH_WeaponSounds.30Cal.30cal_FireEnd01'
    ReloadStages(0)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_02s_01')
    ReloadStages(1)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_02s_02')
    ReloadStages(2)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_01s_03')
    ReloadStages(3)=(Sound=sound'DH_Vehicle_Reloads.Reloads.reload_02s_04')

    // Cannon range settings
    RangeSettings(1)=200
    RangeSettings(2)=400
    RangeSettings(3)=600
    RangeSettings(4)=800
    RangeSettings(5)=1000
    RangeSettings(6)=1200
    RangeSettings(7)=1400
    RangeSettings(8)=1600
    RangeSettings(9)=1800
    RangeSettings(10)=2000
    RangeSettings(11)=2400
    RangeSettings(12)=2800
    RangeSettings(13)=3200
    RangeSettings(14)=3600
    RangeSettings(15)=4000
}
