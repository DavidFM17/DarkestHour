//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_StuH42MountedMGPawn extends DHVehicleMGPawn;

#exec OBJ LOAD FILE=..\Textures\DH_VehicleOptics_tex.utx

// Can't fire unless buttoned up & controlling the remote MG
function bool CanFire()
{
    return (DriverPositionIndex < UnbuttonedPositionIndex && !IsInState('ViewTransition')) || !IsHumanControlled();
}

// Modified to show a hint that player must be buttoned to fire, but unbuttoned to reload the remote controlled external MG
simulated function ClientKDriverEnter(PlayerController PC)
{
    super.ClientKDriverEnter(PC);

    if (DHPlayer(PC) != none)
    {
        DHPlayer(PC).QueueHint(47, true);
    }
}

// Modified so if player buttons up & is now on the gun, rotation is set to match the direction MG is facing (after looking around while unbuttoned)
simulated state ViewTransition
{
    simulated function EndState()
    {
        super.EndState();

        if (DriverPositionIndex < UnbuttonedPositionIndex)
        {
            MatchRotationToGunAim();
        }
    }
}

defaultproperties
{
    GunClass=class'DH_Vehicles.DH_StuH42MountedMG'
    bKeepDriverAuxCollision=true // necessary for new player hit detection system, which basically uses normal hit detection as for an infantry player pawn
    bMultiPosition=true
    DriverPositions(0)=(ViewFOV=41.0,PositionMesh=SkeletalMesh'DH_Stug3G_anm.StuH_mg_remote',TransitionUpAnim="com_open",DriverTransitionAnim="VPanzer3_com_close",ViewPitchUpLimit=4500,ViewPitchDownLimit=64500,ViewPositiveYawLimit=19000,ViewNegativeYawLimit=-20000,bDrawOverlays=true)
    DriverPositions(1)=(ViewFOV=90.0,PositionMesh=SkeletalMesh'DH_Stug3G_anm.StuH_mg_remote',TransitionDownAnim="com_close",DriverTransitionAnim="VPanzer3_com_open",ViewPitchUpLimit=4500,ViewPitchDownLimit=63500,ViewPositiveYawLimit=5500,ViewNegativeYawLimit=-5500,bExposed=true)
    DriverPositions(2)=(ViewFOV=12.0,PositionMesh=SkeletalMesh'DH_Stug3G_anm.StuH_mg_remote',DriverTransitionAnim="stand_idleiron_binoc",ViewPitchUpLimit=4500,ViewPitchDownLimit=63500,ViewPositiveYawLimit=5500,ViewNegativeYawLimit=-5500,bDrawOverlays=true,bExposed=true)
    BinocPositionIndex=2
    bMustUnbuttonToReload=true
    bDrawDriverInTP=true
    DrivePos=(X=-1.5,Y=5.0,Z=-12.0)
    BinocsDrivePos=(X=-8.0,Y=7.0,Z=-12.0)
    DriveAnim="VPanzer3_com_idle_close"
    CameraBone="loader_cam"
    GunsightCameraBone="Gun"
    GunsightOverlay=texture'DH_VehicleOptics_tex.German.KZF2_MGSight'
    OverlayCenterSize=0.7
    BinocsOverlay=texture'DH_VehicleOptics_tex.German.BINOC_overlay_6x30Germ'
}
