//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHPassengerPawn extends DHVehicleWeaponPawn
    abstract;

/**
Matt UK, November 2014 - added new system to avoid rider pawns needing to exist on net clients unless rider position is occupied
Each rider pawn that exists on a client is a net channel that has to be maintained & updated by the server.
The new system can substantially cut down the number of net channels & associated replication, especially in maps with lots of vehicles.
We toggle the bTearOff flag for each rider pawn when it is unoccupied/occupied, which causes the usual clientside simulated actors to spawn or be destroyed.
When bTearOff is set, the actor stops being net relevant & the server closes the channel, stops replicating the actor & destroys the clientside version.
The trick is to stop the actor from actually being torn off on the client, otherwise that causes us big problems & breaks the system.
There is a built-in delay of 5 seconds before the server decides the actor isn't net relevant, closes the channel & destroys the clientside actor.
If a player switches back to the old rider position within these 5 secs, we need them to re-occupy the existing rider pawn & abort closing the channel.
I've found a way to achieve this is to delay the next NetUpdateTime to be >5 seconds in the future, which delays bTearOff from replicating to clients.
That way the server closes the channel & destroys the clientside actor before bTearOff is sent to the client, so it never actually gets torn off.
And if a player re-enters the rider position during these 5 secs, we just change bTearOff back to false & it becomes net relevant again.
A further complication is when a player exits a rider pawn, we need to introduce a very short delay before setting bTearOff on server, so a 0.5 sec timer is used.
This is necessary to allow properties updated on exit (e.g. Owner, Driver & PRI all none) to replicate to clients before shutting down all net traffic.
Changes in other classes: slight modifications to functions NumPassengers in Vehicle classes & DrawVehicleIcon in DHHud, to work with new system & avoid errors.
*/

// An array of subclasses, one specifically assigned for each index position in the vehicle's WeaponPawns array, so this actor knows its own PositionInArray
// Facilitates using a generic passenger pawn class for all vehicles, with properties being specified in vehicle's PassengerPawns array
// Avoids need for lots of passenger pawn classes for every vehicle, but we need subclasses with PositionInArray as net client has to know its index position
// Note that if really needed we can still use specific passenger classes with a vehicle, instead of the PassengerPawns array
var     array<class<DHPassengerPawn> >  PassengerClasses;

var     bool    bUseDriverHeadBoneCam; // use the driver's head bone for the camera location

///////////////////////////////////////////////////////////////////////////////////////
//  ************ ACTOR INITIALISATION, DESTRUCTION & KEY ENGINE EVENTS  ***********  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to set bTearOff to true on a server, which stops this rider pawn being replicated to clients (until entered, when we unset bTearOff)
simulated function PostBeginPlay()
{
    super(Vehicle).PostBeginPlay(); // skip over Super in DHVehicleWeaponPawn as it contains nothing relevant to a passenger

    if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
    {
        bTearOff = true;
    }
}

// Sets bTearOff to true on a server when player exits, purely so server decides the actor is no longer net relevant, kills off the clientside actor & closes the net channel
// But we don't want the clientside actor to actually get torn off, as that would cause us big problems, so we have to stop bTearOff from reaching the client
// So we delay the next update to the client for longer than the server's 5 second delay before it kills a clientside actor after it becomes net irrelevant
function Timer()
{
    if (!bDriving && !bTearOff && (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer))
    {
        NetUpdateTime = Level.TimeSeconds + (6.0 * Level.Game.GameSpeed);
        bTearOff = true;
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  VIEW/DISPLAY  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to avoid "accessed none" errors on VehicleBase & to generally optimise & match other DH vehicle classes
simulated function SpecialCalcFirstPersonView(PlayerController PC, out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local quat RelativeQuat, VehicleQuat, NonRelativeQuat;

    ViewActor = self;

    // CameraRotation is currently relative to vehicle, so now factor in the vehicle's rotation
    if (VehicleBase != none)
    {
        RelativeQuat = QuatFromRotator(Normalize(PC.Rotation));
        VehicleQuat = QuatFromRotator(VehicleBase.Rotation);
        NonRelativeQuat = QuatProduct(RelativeQuat, VehicleQuat);
        CameraRotation = Normalize(QuatToRotator(NonRelativeQuat));
    }
    else
    {
        CameraRotation = PC.Rotation;
    }

    // CameraLocation uses the player's 'head' bone if possible, otherwise there's a fall-back
    if (Driver != none && bUseDriverHeadBoneCam)
    {
        CameraLocation = Driver.GetBoneCoords('head').Origin;
    }
    else
    {
        CameraLocation = GetCameraLocationStart();
    }

    // Adjust camera location for any FPCamPos offset positioning
    if (FPCamPos != vect(0.0, 0.0, 0.0))
    {
        CameraLocation = CameraLocation + (FPCamPos >> CameraRotation);
    }

    // Finalise the camera with any shake
    CameraLocation = CameraLocation + (PC.ShakeOffset >> PC.Rotation);
    CameraRotation = Normalize(CameraRotation + PC.ShakeRot);
}

// Modified to remove everything except drawing basic vehicle HUD info
simulated function DrawHUD(Canvas C)
{
    local PlayerController PC;

    PC = PlayerController(Controller);

    // Draw vehicle, turret, passenger list
    if (PC != none && !PC.bBehindView && ROHud(PC.myHUD) != none && VehicleBase != none)
    {
        ROHud(PC.myHUD).DrawVehicleIcon(C, VehicleBase, self);
    }
}

// From deprecated ROPassengerPawn
simulated function vector GetCameraLocationStart()
{
    if (VehicleBase != none)
    {
        return VehicleBase.GetBoneCoords(CameraBone).Origin;
    }

    return Location;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ***************************** VEHICLE ENTRY & EXIT ***************************** //
///////////////////////////////////////////////////////////////////////////////////////

// From deprecated ROPassengerPawn, which removed all 'Gun' references from the Supers
// Modified to unset bTearOff on a server, which makes this rider pawn potentially relevant to clients & always to the one entering the rider position
// Also to set rotation to match the way the rider is facing, so his view starts facing the same way, & to remove redundancy & optimise the ordering of the function
function KDriverEnter(Pawn P)
{
    local Controller C;
    local rotator    NewRotation;

    // On a server, disable bTearOff so this actor replicates to relevant net clients
    if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
    {
        SetTimer(0.0, false); // clear any timer, so we don't risk setting bTearOff to true again just after we enter
        bTearOff = false;     // don't need to do quick net update as normal entering sequence already does it
    }

    bDriving = true;
    StuckCount = 0;

    // Set player's current controller to control this vehicle pawn instead & make the player our 'Driver'
    C = P.Controller;
    Driver = P;
    Driver.StartDriving(self);

    // Make the player unpossess its DHPawn body & possess this vehicle pawn
    C.bVehicleTransition = true; // to keep Bots from doing Restart()
    C.Unpossess();
    Driver.SetOwner(self); // this keeps the driver relevant
    C.Possess(self);
    C.bVehicleTransition = false;
    DrivingStatusChanged();
    Level.Game.DriverEnteredVehicle(self, P);

    // Match player's rotation to match the way the rider is facing, so his view starts facing the same way
    NewRotation.Yaw = DriveRot.Yaw;
    SetRotation(NewRotation);
    Driver.bSetPCRotOnPossess = false; // so when player gets out, he'll be facing the same direction as he was in the vehicle

    if (PlayerController(C) != none)
    {
        VehicleLostTime = 0.0;
    }

    if (VehicleBase != none)
    {
        VehicleBase.ResetTime = Level.TimeSeconds - 1.0; // cancel any CheckReset timer as vehicle now occupied
    }
}

// Modified to set rotation to match the way the rider is facing, so his view starts facing the same way
simulated function ClientKDriverEnter(PlayerController PC)
{
    local rotator NewRotation;

    super.ClientKDriverEnter(PC);

    NewRotation.Yaw = DriveRot.Yaw;
    SetRotation(NewRotation);
}

// Modified (from deprecated ROPassengerPawn) to avoid confusing attachment to CameraBone & instead use the usual WeaponBone specified in the vehicle's PassengerWeapons array
simulated function AttachDriver(Pawn P)
{
    local name AttachBone;

    if (VehicleBase != none && VehicleBase.PassengerWeapons[PositionInArray].WeaponBone != '')
    {
        AttachBone = VehicleBase.PassengerWeapons[PositionInArray].WeaponBone;
        P.bHardAttach = true;
        P.SetLocation(VehicleBase.GetBoneCoords(AttachBone).Origin);
        P.SetPhysics(PHYS_None);
        VehicleBase.AttachToBone(P, AttachBone);
        P.SetRelativeLocation(DrivePos + P.default.PrePivot);
        P.SetRelativeRotation(DriveRot);
        P.PrePivot = vect(0.0, 0.0, 0.0);
    }
}

// Modified to set bTearOff to true (after a short timer) on a server when player exits, which kills off the clientside actor & closes the net channel
// Need to use timer to add short delay, to allow properties updated on exit (e.g. Owner, Driver & PRI all none) to replicate to client before shutting down all net traffic
simulated event DrivingStatusChanged() // TODO: think this fits better in DriverLeft() as only happens on server, which will now always get DriverLeft
{
    super.DrivingStatusChanged();

    if (!bDriving && (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer))
    {
        SetTimer(0.5, false);
    }
}

// Modified to remove need to have specified CameraBone, which is irrelevant (in conjunction with modified AttachDriver)
simulated function DetachDriver(Pawn P)
{
    P.PrePivot = P.default.PrePivot;

    if (VehicleBase != none)
    {
        VehicleBase.DetachFromBone(P);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  MISCELLANEOUS ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to set up our properties, using what has been specified in the vehicle's PassengerPawns array, allowing use of a generic passenger pawn class
// Note this will do nothing if specific passenger classes have been used with the vehicle, instead of the PassengerPawns array (because PassengerPawns.Length will be 0)
simulated function InitializeVehicleBase()
{
    local DHVehicle V;
    local int       Index;

    V = DHVehicle(VehicleBase);

    if (V != none && V.PassengerPawns.Length > 0)
    {
        Index = PositionInArray - V.FirstRiderPositionIndex;

        if (Index >= 0 && Index < V.PassengerPawns.Length)
        {
            DrivePos = V.PassengerPawns[Index].DrivePos;
            DriveRot = V.PassengerPawns[Index].DriveRot;
            DriveAnim = V.PassengerPawns[Index].DriveAnim;
            FPCamPos = V.PassengerPawns[Index].FPCamPos;
        }
    }

    super.InitializeVehicleBase();
}

// From ROPassengerPawn
function float ModifyThreat(float Current, Pawn Threat)
{
    if (Vehicle(Threat) != none)
    {
        return Current - 1.5;
    }

    return Current + 1.0;
}

// Functions emptied out as a passenger pawn has no VehicleWeapon:
function BeginPlay(); // the Super only tries to spawn the GunClass, which is none
simulated function InitializeVehicleWeapon();
function Fire(optional float F); // prevents unnecessary replicated VehicleFire() function calls to server
function VehicleFire(bool bWasAltFire);
event FiredPendingPrimary();
event ApplyFireImpulse(bool bAlt);
function VehicleCeaseFire(bool bWasAltFire);
function ClientVehicleCeaseFire(bool bWasAltFire);
function ClientOnlyVehicleCeaseFire(bool bWasAltFire);
function bool StopWeaponFiring() { return false; }
function float GetAmmoReloadState() { return 0.0; }
simulated event SetRotatingStatus(byte NewRotationStatus);
simulated function ServerSetRotatingStatus(byte NewRotatingStatus);
function bool ResupplyAmmo() { return false; }

defaultproperties
{
    bPassengerOnly=true
    bSinglePositionExposed=true
    bZeroPCRotOnEntry=false // no point, as on entering we're now setting rotation to match the way the rider is facing
    bUseDriverHeadBoneCam=true
    WeaponFOV=90.0
    HudName="Rider"

    PassengerClasses(0)=class'DH_Engine.DHPassengerPawnZero'
    PassengerClasses(1)=class'DH_Engine.DHPassengerPawnOne'
    PassengerClasses(2)=class'DH_Engine.DHPassengerPawnTwo'
    PassengerClasses(3)=class'DH_Engine.DHPassengerPawnThree'
    PassengerClasses(4)=class'DH_Engine.DHPassengerPawnFour'
    PassengerClasses(5)=class'DH_Engine.DHPassengerPawnFive'
    PassengerClasses(6)=class'DH_Engine.DHPassengerPawnSix'
    PassengerClasses(7)=class'DH_Engine.DHPassengerPawnSeven'
    PassengerClasses(8)=class'DH_Engine.DHPassengerPawnEight'
    PassengerClasses(9)=class'DH_Engine.DHPassengerPawnNine'
}
