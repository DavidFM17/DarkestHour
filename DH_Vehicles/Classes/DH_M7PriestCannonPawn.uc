//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_M7PriestCannonPawn extends DHAmericanCannonPawn;

// Modified to update sight rotation, if gun pitch has changed
function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange)
{
    local rotator R;

    super.HandleTurretRotation(DeltaTime, YawChange, PitchChange);

    if (Level.NetMode != NM_DedicatedServer && ((YawChange != 0.0 && !bTurretRingDamaged) || (PitchChange != 0.0 && !bGunPivotDamaged)) && Gun != none)
    {
        R = Gun.GetBoneRotation('gun');
        Log(R); // TEMPDEBUG - remove before release
        R.Yaw = 0;
        Gun.SetBoneRotation('gunsight', R);
    }
}

//ViewLocation=(X=21.0,Y=19.0,Z=4.0)

defaultproperties
{
    GunClass=class'DH_Vehicles.DH_M7PriestCannon'
    // gunsight
    DriverPositions(0)=(ViewLocation=(Y=-19.8,Z=47.4),ViewFOV=24.0,ViewPitchUpLimit=4551,ViewPitchDownLimit=64079,ViewPositiveYawLimit=19000,ViewNegativeYawLimit=-20000,bDrawOverlays=true,bExposed=true)
    // periscope // TODO: query this as it's a commander's 360 degree periscope?
    DriverPositions(1)=(ViewLocation=(Y=-19.8,Z=47.4),ViewFOV=90.0,ViewPitchUpLimit=1,ViewPitchDownLimit=65535,ViewPositiveYawLimit=65536,ViewNegativeYawLimit=-65536,bDrawOverlays=true,bExposed=true)
    // kneeling
    DriverPositions(2)=(ViewFOV=90.0,DriverTransitionAnim="crouch_idle_binoc",TransitionUpAnim="com_open",ViewPitchUpLimit=10000,ViewPitchDownLimit=63500,ViewPositiveYawLimit=65536,ViewNegativeYawLimit=-65536,bExposed=true)
    // standing
    DriverPositions(3)=(ViewFOV=90.0,DriverTransitionAnim="stand_idlehip_binoc",TransitionDownAnim="com_close",ViewPitchUpLimit=10000,ViewPitchDownLimit=63500,ViewPositiveYawLimit=65536,ViewNegativeYawLimit=-65536,bExposed=true)
    // binoculars
    DriverPositions(4)=(ViewFOV=12.0,DriverTransitionAnim="stand_idleiron_binoc",ViewPitchUpLimit=10000,ViewPitchDownLimit=63500,ViewPositiveYawLimit=65536,ViewNegativeYawLimit=-65536,bDrawOverlays=true,bExposed=true)
    UnbuttonedPositionIndex=0
    RaisedPositionIndex=3
    PeriscopePositionIndex=1
    BinocPositionIndex=4
    DriveAnim="crouch_idle_binoc"
    bManualTraverseOnly=true
    bHasAltFire=false
    GunsightOverlay=texture'DH_VehicleOptics_tex.Allied.m12a7_sight_2'
    OverlayCenterSize=0.542
    DestroyedGunsightOverlay=texture'DH_VehicleOpticsDestroyed_tex.Allied.Sherman_sight_destroyed'
    AmmoShellTexture=texture'DH_InterfaceArt_tex.Tank_Hud.ShermanShell'
    AmmoShellReloadTexture=texture'DH_InterfaceArt_tex.Tank_Hud.ShermanShell_reload'
    FireImpulse=(X=-110000.0)
}
