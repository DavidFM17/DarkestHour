//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_Sdkfz251GunPawn extends DHMountedTankMGPawn;

simulated function SpecialCalcFirstPersonView(PlayerController PC, out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local vector  x, y, z;
    local vector  VehicleZ, CamViewOffsetWorld;
    local float   CamViewOffsetZAmount;
    local rotator WeaponAimRot;

    GetAxes(CameraRotation, x, y, z);
    ViewActor = self;

    WeaponAimRot = Gun.GetBoneRotation(CameraBone);

    if (ROPlayer(Controller) != none)
    {
        ROPlayer(Controller).WeaponBufferRotation.Yaw = WeaponAimRot.Yaw;
        ROPlayer(Controller).WeaponBufferRotation.Pitch = WeaponAimRot.Pitch;
    }

    CameraRotation =  WeaponAimRot;

    CamViewOffsetWorld = FPCamViewOffset >> CameraRotation;

    if (CameraBone != '' && Gun != none)
    {
        CameraLocation = Gun.GetBoneCoords('Camera_com').Origin;

        if (bFPNoZFromCameraPitch)
        {
            VehicleZ = vect(0.0, 0.0, 1.0) >> WeaponAimRot;
            CamViewOffsetZAmount = CamViewOffsetWorld dot VehicleZ;
            CameraLocation -= CamViewOffsetZAmount * VehicleZ;
        }
    }
    else
    {
        CameraLocation = GetCameraLocationStart() + (FPCamPos >> Rotation) + CamViewOffsetWorld;

        if (bFPNoZFromCameraPitch)
        {
            VehicleZ = vect(0.0, 0.0, 1.0) >> Rotation;
            CamViewOffsetZAmount = CamViewOffsetWorld dot VehicleZ;
            CameraLocation -= CamViewOffsetZAmount * VehicleZ;
        }
    }

    CameraRotation = Normalize(CameraRotation + PC.ShakeRot);
    CameraLocation = CameraLocation + PC.ShakeOffset.X * x + PC.ShakeOffset.Y * y + PC.ShakeOffset.Z * z;
}

defaultproperties
{
    UnbuttonedPositionIndex=0
    FirstPersonGunShakeScale=2.0
    WeaponFOV=72.0
    DriverPositions(0)=(ViewFOV=90.0,PositionMesh=SkeletalMesh'DH_Sdkfz251Halftrack_anm.halftrack_gun_int',TransitionUpAnim="com_open",DriverTransitionAnim="Vhalftrack_com_close",ViewPitchUpLimit=2000,ViewPitchDownLimit=63000,ViewPositiveYawLimit=10000,ViewNegativeYawLimit=-10000,bDrawOverlays=true,bExposed=true)
    DriverPositions(1)=(ViewFOV=90.0,PositionMesh=SkeletalMesh'DH_Sdkfz251Halftrack_anm.halftrack_gun_int',TransitionDownAnim="com_close",DriverTransitionAnim="Vhalftrack_com_open",ViewPitchUpLimit=2000,ViewPitchDownLimit=63000,ViewPositiveYawLimit=10000,ViewNegativeYawLimit=-10000,bDrawOverlays=true,bExposed=true)
    bMultiPosition=true
    bMustBeTankCrew=false
    GunClass=class'DH_Vehicles.DH_Sdkfz251Gun'
    bCustomAiming=true
    PositionInArray=0
    bHasAltFire=false
    CameraBone="Camera_com"
    FirstPersonGunRefBone="1stperson_wep"
    FirstPersonOffsetZScale=3.0
    bHideMuzzleFlashAboveSights=true
    bDesiredBehindView=false
    DriveRot=(Yaw=16384)
    DriveAnim="VHalftrack_com_idle"
    EntryRadius=130.0
    HUDOverlayClass=class'ROVehicles.ROVehMG34Overlay'
    HUDOverlayFOV=45.0
    PitchUpLimit=4000
    PitchDownLimit=61000
}
