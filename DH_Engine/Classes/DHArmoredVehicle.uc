//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHArmoredVehicle extends DHVehicle
    abstract;

#exec OBJ LOAD FILE=..\sounds\Amb_Destruction.uax
#exec OBJ LOAD FILE=..\Textures\DH_VehicleOptics_tex.utx
#exec OBJ LOAD FILE=..\Textures\DH_VehiclesGE_tex2.utx

struct ArmorSection
{
var     float   Thickness;         // in cm
var     float   Slope;             // in degrees from vertical (must specify a negative if armor slopes 'inwards')
var     float   MaxRelativeHeight; // max height (in UU) of this armor section, relative to hull mesh's centre
var     string  LocationName;      // e.g. "lower front", "driver's upstand plate"
};

enum ENewHitPointType
{
    NHP_Normal,
    NHP_GunOptics,
    NHP_PeriscopeOptics,
    NHP_Traverse,
    NHP_GunPitch,
    NHP_Hull,
};

var     ENewHitPointType    NewHitPointType;    // array of new DH special vehicle hit points that may be hit & damaged

struct NewHitpoint
{
    var   float             PointRadius;        // squared radius of the head of the pawn that is vulnerable to headshots
    var   float             PointHeight;        // distance from base of neck to center of head - used for headshot calculation
    var   float             PointScale;         // scale factor for radius & height
    var   name              PointBone;          // bone to reference in offset
    var   vector            PointOffset;        // amount to offset the hitpoint from the bone
    var   bool              bPenetrationPoint;  // this is a penetration point, open hatch, etc
    var   float             DamageMultiplier;   // amount to scale damage to the vehicle if this point is hit
    var   ENewHitPointType  NewHitPointType;    // what type of hit point this is
};

// General
var     int         UnbuttonedPositionIndex;    // lowest DriverPositions index where driver is unbuttoned & exposed
var     bool        bMustUnbuttonToSwitchToRider; // stops driver 'teleporting' outside to rider position if buttoned up
var     vector      OverlayFPCamPos;            // optional camera offset for overlay position, so can snap to exterior view position, avoiding camera anims passing through hull
var     texture     PeriscopeOverlay;           // driver's periscope overlay texture
var     texture     DamagedPeriscopeOverlay;    // gunsight overlay to show if optics have been broken

// Armor penetration
var     array<ArmorSection> FrontArmor;        // array of armor properties (divided into horizontal bands) for each side of vehicle
var     array<ArmorSection> RightArmor;
var     array<ArmorSection> LeftArmor;
var     array<ArmorSection> RearArmor;
var     bool        bHasAddedSideArmor;         // this vehicle has added side armour skirts (schurzen) that will stop HEAT rounds
var     bool        bProjectilePenetrated;      // shell has passed penetration tests & has entered the vehicle (used in TakeDamage)
var     bool        bTurretPenetration;         // shell has penetrated the turret (used in TakeDamage)
var     bool        bRearHullPenetration;       // shell has penetrated the rear hull (so TakeDamage can tell if an engine hit should stop the round penetrating any further)

// Damage
var     array<NewHitpoint>  NewVehHitpoints;    // an array of possible small points that can be hit. Index zero is always the driver
var     int         GunOpticsHitPointIndex;     // index of any special hit point for exposed gunsight optics, which may be damaged by a bullet
var     float       AmmoIgnitionProbability;    // chance that direct hit on ammo store will ignite it
var     float       TurretDetonationThreshold;  // chance that shrapnel will detonate turret ammo
var     float       DriverKillChance;           // chance that shrapnel will kill driver
var     float       CommanderKillChance;        // chance that shrapnel will kill commander
var     float       GunnerKillChance;           // chance that shrapnel will kill bow gunner
var     float       GunDamageChance;            // chance that shrapnel will damage gun pivot mechanism
var     float       TraverseDamageChance;       // chance that shrapnel will damage gun traverse mechanism or turret ring is jammed
var     float       OpticsDamageChance;         // chance that shrapnel will break gunsight optics
var     float       SpikeTime;                  // saved future time when a disabled vehicle will be automatically blown up, if empty at that time

// Fire stuff- Shurek & Ch!cKeN (modified by Matt)
var     class<DamageType>           VehicleBurningDamType;
var     class<VehicleDamagedEffect> FireEffectClass;
var     VehicleDamagedEffect        DriverHatchFireEffect;
var     name        FireAttachBone;
var     vector      FireEffectOffset;
var     float       HullFireChance;
var     float       HullFireHEATChance;
var     bool        bOnFire;               // the vehicle itself is on fire
var     float       HullFireDamagePer2Secs;
var     float       PlayerFireDamagePer2Secs;
var     float       NextHullFireDamageTime;
var     float       EngineFireChance;
var     float       EngineFireHEATChance;
var     bool        bEngineOnFire;
var     float       EngineFireDamagePer3Secs;
var     float       NextEngineFireDamageTime;
var     bool        bSetHullFireEffects;
var     bool        bDriverHatchFireNeeded;
var     float       DriverHatchFireSpawnTime;
var     bool        bTurretFireNeeded;
var     float       TurretHatchFireSpawnTime;
var     bool        bHullMGFireNeeded;
var     float       HullMGHatchFireSpawnTime;
var     float       FireDetonationChance;   // chance of a fire blowing a vehicle up, runs each time the fire does damage
var     float       EngineToHullFireChance; // chance of an engine fire spreading to the rest of the vehicle, runs each time engine takes fire damage
var     bool        bFirstPenetratingHit;
var     bool        bHEATPenetration;       // a penetrating round is a HEAT round
var     Controller  WhoSetOnFire;
var     int         HullFireStarterTeam;
var     Controller  WhoSetEngineOnFire;
var     int         EngineFireStarterTeam;
var     sound       SmokingEngineSound;

// Debugging
var     bool        bDebugPenetration;    // debug lines & text on screen, relating to turret hits & penetration calculations
var     bool        bLogDebugPenetration; // similar debug log entries

replication
{
    // Variables the server will replicate to all clients
    reliable if (bNetDirty && Role == ROLE_Authority)
        bOnFire, bEngineOnFire;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ********************** ACTOR INITIALISATION & DESTRUCTION  ********************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to set fire damage properties
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        // Set fire damage rates
        HullFireDamagePer2Secs = HealthMax * 0.02;             // so approx 100 seconds from full vehicle health to detonation due to fire
        EngineFireDamagePer3Secs = default.EngineHealth * 0.1; // so approx 30 seconds engine fire until engine destroyed
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ***************************** KEY ENGINE EVENTS  ******************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle fire effects
simulated function PostNetReceive()
{
    super.PostNetReceive();

    if (bOnFire)
    {
        // Vehicle fire has started
        if (!bSetHullFireEffects && Health > 0)
        {
            SetFireEffects();
        }
    }
    else if (bEngineOnFire)
    {
        // Engine fire has started (DEHFireFactor of 1.0 would flag that the engine fire effect is already on)
        if (DamagedEffectHealthFireFactor != 1.0 && Health > 0)
        {
            SetFireEffects();
        }
    }
    // Engine is dead & engine fire has burned out, so set it to smoke instead of burn
    else if (EngineHealth <= 0 && (DamagedEffectHealthFireFactor != 0.0 || DamagedEffectHealthHeavySmokeFactor != 1.0) && Health > 0)
    {
        SetFireEffects();
    }
}

// Modified to use a system of interwoven timers instead of constantly checking for things in Tick() - fire damage, spiked vehicle timer
simulated function Timer()
{
    local float Now;

    if (Health <= 0)
    {
        return;
    }

    Now = Level.TimeSeconds;

    if (Role == ROLE_Authority)
    {
        // Handle any hull fire damage due
        if (bOnFire && Now >= NextHullFireDamageTime)
        {
            TakeFireDamage();
        }

        // Handle any engine fire damage due
        if (bEngineOnFire && Now >= NextEngineFireDamageTime)
        {
            TakeEngineFireDamage();
        }

        // Check to see if we need to destroy a spiked, abandoned vehicle
        if (bSpikedVehicle && Now >= SpikeTime)
        {
            if (IsVehicleEmpty() && !bOnFire)
            {
                KilledBy(self);
            }
            else
            {
                bSpikedVehicle = false; // cancel spike timer if vehicle is now occupied or burning (just let the fire destroy it)
            }
        }
    }

    // Vehicle is burning, so check if we need to spawn any hatch fire effects
    if (bOnFire && Level.NetMode != NM_DedicatedServer)
    {
        if (bDriverHatchFireNeeded && Now >= DriverHatchFireSpawnTime && DriverHatchFireSpawnTime != 0.0)
        {
            StartDriverHatchFire();
        }

        if (bTurretFireNeeded && Now >= TurretHatchFireSpawnTime && TurretHatchFireSpawnTime != 0.0)
        {
            bTurretFireNeeded = false;

            if (Cannon != none)
            {
                Cannon.StartHatchFire();
            }
        }

        if (bHullMGFireNeeded && Now >= HullMGHatchFireSpawnTime && HullMGHatchFireSpawnTime != 0.0)
        {
            bHullMGFireNeeded = false;

            if (MGun != none)
            {
                MGun.StartHatchFire();
            }
        }
    }

    // Engine is dead, but there's no fire, so make sure it is set to smoke instead of burn
    if (EngineHealth <= 0 && !bEngineOnFire && !bOnFire && (DamagedEffectHealthFireFactor != 0.0 || DamagedEffectHealthHeavySmokeFactor != 1.0))
    {
        SetFireEffects();
    }

    SetNextTimer(Now);
}

// New function as we are using timers for different things in different net modes, so work out which one (if any) is due next
simulated function SetNextTimer(optional float Now)
{
    local float NextTimerTime;

    if (Now == 0.0)
    {
        Now = Level.TimeSeconds;
    }

    if (Role == ROLE_Authority)
    {
        if (bOnFire && NextHullFireDamageTime > Now)
        {
            NextTimerTime = NextHullFireDamageTime;
        }

        if (bEngineOnFire && (NextEngineFireDamageTime < NextTimerTime || NextTimerTime == 0.0) && NextEngineFireDamageTime > Now)
        {
            NextTimerTime = NextEngineFireDamageTime;
        }

        if (bSpikedVehicle && (SpikeTime < NextTimerTime || NextTimerTime == 0.0) && SpikeTime > Now)
        {
            NextTimerTime = SpikeTime;
        }
    }

    if (Level.NetMode != NM_DedicatedServer && bOnFire)
    {
        if (bDriverHatchFireNeeded && (DriverHatchFireSpawnTime < NextTimerTime || NextTimerTime == 0.0) && DriverHatchFireSpawnTime > Now)
        {
            NextTimerTime = DriverHatchFireSpawnTime;
        }

        if (bTurretFireNeeded && (TurretHatchFireSpawnTime < NextTimerTime || NextTimerTime == 0.0) && TurretHatchFireSpawnTime > Now)
        {
            NextTimerTime = TurretHatchFireSpawnTime;
        }

        if (bHullMGFireNeeded && (HullMGHatchFireSpawnTime < NextTimerTime || NextTimerTime == 0.0) && HullMGHatchFireSpawnTime > Now)
        {
            NextTimerTime = HullMGHatchFireSpawnTime;
        }
    }

    // Finally set the next timer, if we need one
    if (NextTimerTime > Now)
    {
        SetTimer(NextTimerTime - Now, false);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  VIEW/DISPLAY  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add support for periscope texture overlay
simulated function DrawHUD(Canvas C)
{
    local PlayerController PC;
    local float            SavedOpacity;

    PC = PlayerController(Controller);

    if (PC != none && !PC.bBehindView)
    {
        // Player is in a position where an overlay should be drawn
        if (DriverPositions[DriverPositionIndex].bDrawOverlays && (!IsInState('ViewTransition') || DriverPositions[PreviousPositionIndex].bDrawOverlays))
        {
            if (HUDOverlay == none)
            {
                // Draw periscope overlay
                if (PeriscopeOverlay != none)
                {
                    // Save current HUD opacity & then set up for drawing overlays
                    SavedOpacity = C.ColorModulate.W;
                    C.ColorModulate.W = 1.0;
                    C.DrawColor.A = 255;
                    C.Style = ERenderStyle.STY_Alpha;

                    DrawPeriscopeOverlay(C);

                    C.ColorModulate.W = SavedOpacity; // reset HudOpacity to original value
                }
            }
            // Draw any HUD overlay
            else if (!Level.IsSoftwareRendering())
            {
                HUDOverlay.SetLocation(PC.CalcViewLocation + (HUDOverlayOffset >> PC.CalcViewRotation));
                HUDOverlay.SetRotation(PC.CalcViewRotation);
                C.DrawActor(HUDOverlay, false, true, FClamp(HUDOverlayFOV * (PC.DesiredFOV / PC.DefaultFOV), 1.0, 170.0));
            }
        }

        // Draw vehicle, turret, ammo count, passenger list
        if (ROHud(PC.myHUD) != none)
        {
            ROHud(PC.myHUD).DrawVehicleIcon(C, self);
        }
    }
}

// New function to draw any textured driver's periscope overlay
simulated function DrawPeriscopeOverlay(Canvas C)
{
    local float ScreenRatio;

    ScreenRatio = float(C.SizeY) / float(C.SizeX);
    C.SetPos(0.0, 0.0);
    C.DrawTile(PeriscopeOverlay, C.SizeX, C.SizeY, 0.0, (1.0 - ScreenRatio) * float(PeriscopeOverlay.VSize) / 2.0, PeriscopeOverlay.USize, float(PeriscopeOverlay.VSize) * ScreenRatio);
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************** VEHICLE ENTRY  ******************************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add an extra section from deprecated ROTreadCraft class that was commented "code to get the bots using tanks better"
function Vehicle FindEntryVehicle(Pawn P)
{
    local int i;

    if (P != none && Bot(P.Controller) != none && WeaponPawns.Length > 0 && IsVehicleEmpty())
    {
        for (i = WeaponPawns.Length - 1; i >= 0; --i)
        {
            if (WeaponPawns[i] != none && WeaponPawns[i].Driver == none)
            {
                return WeaponPawns[i];
            }
        }
    }

    return super.FindEntryVehicle(P);
}

// Modified to prevent entry if either vehicle is on fire
function bool TryToDrive(Pawn P)
{
    // Don't allow entry to burning vehicle (with message)
    if (bOnFire || bEngineOnFire)
    {
        DisplayVehicleMessage(9, P); // vehicle is on fire

        return false;
    }

    return super.TryToDrive(P);
}

// Modified to handle optional camera offset for initial overlay position
simulated function ClientKDriverEnter(PlayerController PC)
{
    super.ClientKDriverEnter(PC);

    // If initial position is an overlay position (e.g. driver's periscope), apply any optional 1st person camera offset for the overlay
    if (DriverPositions[InitialPositionIndex].bDrawOverlays && OverlayFPCamPos != vect(0.0, 0.0, 0.0))
    {
        FPCamPos = OverlayFPCamPos;
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ***************************** DRIVER VIEW POINTS  ****************************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle optional camera offset for initial overlay position
simulated state ViewTransition
{
    simulated function HandleTransition()
    {
        super.HandleTransition();

        if (Level.NetMode != NM_DedicatedServer && OverlayFPCamPos != vect(0.0, 0.0, 0.0) && DriverPositions[PreviousPositionIndex].bDrawOverlays
            && IsHumanControlled() && !PlayerController(Controller).bBehindView)
        {
            FPCamPos = default.FPCamPos; // if moving away from overlay, remove offset immediately
        }
    }

    simulated function EndState()
    {
        super.EndState();

        if (Level.NetMode != NM_DedicatedServer && OverlayFPCamPos != vect(0.0, 0.0, 0.0) && DriverPositions[DriverPositionIndex].bDrawOverlays
            && IsHumanControlled() && !PlayerController(Controller).bBehindView)
        {
            FPCamPos = OverlayFPCamPos; // if moving into overlay, apply offset at end of transition
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************** VEHICLE EXIT  ********************************* //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add clientside check to stop call to server if player selected a rider position but is buttoned up (no 'teleporting' outside to external rider position)
simulated function SwitchWeapon(byte F)
{
    if (Role < ROLE_Authority && StopExitToRiderPosition(F - 2))
    {
        return;
    }

    super.SwitchWeapon(F);
}

// Modified to prevent 'teleporting' outside to external rider position while buttoned up inside vehicle
function ServerChangeDriverPosition(byte F)
{
    if (!StopExitToRiderPosition(F - 2))
    {
        super.ServerChangeDriverPosition(F);
    }
}

// New function to check if player is trying to 'teleport' outside to external rider position while buttoned up (just saves repeating code in different functions)
simulated function bool StopExitToRiderPosition(byte ChosenWeaponPawnIndex)
{
    return ChosenWeaponPawnIndex >= FirstRiderPositionIndex && ChosenWeaponPawnIndex < PassengerWeapons.Length && bMustUnbuttonToSwitchToRider && !CanExit();
}

// Implemented to prevent exit if player is buttoned up, displaying an appropriate "unbutton the hatch" message if he can't
simulated function bool CanExit()
{
    if (DriverPositionIndex < UnbuttonedPositionIndex || (IsInState('ViewTransition') && DriverPositionIndex == UnbuttonedPositionIndex))
    {
        if (DriverPositions.Length > UnbuttonedPositionIndex) // means it is possible to unbutton
        {
            DisplayVehicleMessage(4,, true); // must unbutton the hatch
        }
        else if (MGun != none && MGun.WeaponPawn != none && MGun.WeaponPawn.DriverPositions.Length > MGun.WeaponPawn.UnbuttonedPositionIndex) // means it's possible to exit MG position
        {
            DisplayVehicleMessage(11); // must exit through commander's or MG hatch
        }
        else
        {
            DisplayVehicleMessage(5); // must exit through commander's hatch
        }

        return false;
    }

    return true;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ************************* ENGINE START/STOP & EFFECTS ************************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle extended vehicle fire system, plus setting manual/powered turret
simulated function SetEngine()
{
    if (bEngineOff || Health <= 0 || EngineHealth <= 0)
    {
        TurnDamping = 0.0;

        if (bOnFire || bEngineOnFire)
        {
            AmbientSound = VehicleBurningSound;
            SoundVolume = 255;
            SoundRadius = 200.0;
        }
        else if (EngineHealth <= 0)
        {
            AmbientSound = SmokingEngineSound;
            SoundVolume = 64;
            SoundRadius = 200.0;
        }
        else
        {
            AmbientSound = none;
        }

        if (bEmittersOn)
        {
            StopEmitters();
        }
    }
    else
    {
        if (IdleSound != none)
        {
            AmbientSound = IdleSound;
            SoundVolume = default.SoundVolume;
            SoundRadius = default.SoundRadius;
        }

        if (!bEmittersOn)
        {
            StartEmitters();
        }
    }

    if (Cannon != none && DHVehicleCannonPawn(Cannon.WeaponPawn) != none)
    {
        DHVehicleCannonPawn(Cannon.WeaponPawn).SetManualTurret(bEngineOff);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************** VEHICLE FIRES  ******************************** //
///////////////////////////////////////////////////////////////////////////////////////

// New function to handle starting a hull fire
function StartHullFire(Pawn InstigatedBy)
{
    bOnFire = true;

    if (bDebuggingText)
    {
        Level.Game.Broadcast(self, "Vehicle set on fire");
    }

    // Record the player responsible for starting fire, so score can be awarded later if results in a kill
    if (InstigatedBy != none)
    {
        WhoSetOnFire = InstigatedBy.Controller;
        DelayedDamageInstigatorController = WhoSetOnFire;
    }

    if (WhoSetOnFire != none)
    {
        HullFireStarterTeam = WhoSetOnFire.GetTeamNum();
    }

    // Set the 1st hull damage due in 2 seconds
    NextHullFireDamageTime = Level.TimeSeconds + 2.0;

    // Fire effects, including timers for delayed hatch fires
    if (Level.NetMode != NM_DedicatedServer)
    {
        SetFireEffects();
    }
    else
    {
        SetNextTimer(); // for damage only on server
    }
}

// New function to handle starting an engine fire
function StartEngineFire(Pawn InstigatedBy)
{
    bEngineOnFire = true;

    if (bDebuggingText)
    {
        Level.Game.Broadcast(self, "Engine set on fire");
    }

    // Record the player responsible for starting fire, so score can be awarded later if results in a kill
    if (InstigatedBy != none)
    {
        WhoSetEngineOnFire = InstigatedBy.Controller;

        if (WhoSetEngineOnFire != none)
        {
            EngineFireStarterTeam = WhoSetEngineOnFire.GetTeamNum();

            if (DelayedDamageInstigatorController == none) // don't override DDIC if already set, e.g. someone else may already have set hull on fire
            {
                DelayedDamageInstigatorController = WhoSetEngineOnFire;
            }
        }
    }

    // Set fire damage due immediately & call Timer() directly (it handles damage & setting of next due Timer)
    NextEngineFireDamageTime = Level.TimeSeconds;
    Timer();

    // Engine fire effect
    SetFireEffects();
}

// Set up for spawning various hatch fire effects, but randomise start times to desync them
simulated function SetFireEffects()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (bOnFire || bEngineOnFire)
        {
            // Engine fire effect
            if (DamagedEffectHealthFireFactor != 1.0)
            {
                DamagedEffectHealthFireFactor = 1.0;
                DamagedEffectHealthSmokeFactor = 1.0; // appears necessary to get native code to spawn a DamagedEffect if it doesn't already exist
                                                      // (presumably doesn't check for fire unless vehicle is at least damaged enough to smoke)

                if (DamagedEffect == none && Health == HealthMax) // clientside Health hack to get native code to spawn DamagedEffect (it won't unless vehicle has taken some damage)
                {
                    Health--;
                }
            }

            // Hatch fire effects
            if (bOnFire && !bSetHullFireEffects)
            {
                bSetHullFireEffects = true;

                // If bClientInitialized or we're an authority role (single player or listen server) then this must have been called as the fire breaks out
                // Randomise the fire effect start times (spreading from the engine forwards) & set a timer
                if (bClientInitialized || Role == ROLE_Authority)
                {
                    if (Cannon != none)
                    {
                        bTurretFireNeeded = true;
                        TurretHatchFireSpawnTime = Level.TimeSeconds + 2.0 + (FRand() * 3.0); // turret hatch fire starts 2-5 secs after fire starts in engine
                    }

                    bDriverHatchFireNeeded = true;
                    DriverHatchFireSpawnTime = FMax(TurretHatchFireSpawnTime, Level.TimeSeconds) + 2.0 + (FRand() * 3.0); // driver hatch fire starts 2-5 secs after turret fire

                    if (MGun != none)
                    {
                        bHullMGFireNeeded = true;
                        HullMGHatchFireSpawnTime = DriverHatchFireSpawnTime + 1.0 + (FRand() * 2.0); // MG hatch fire starts 1-3 secs after turret fire
                    }

                    SetNextTimer();
                }
                // Otherwise this must have been called when an already burning vehicle is replicated to a net client
                // Start driver's hatch fire effect immediately, but let VehicleWeapons start their own fires as those actors replicate
                else
                {
                    StartDriverHatchFire();
                }
            }
        }
        // Engine is dead, but there's no fire, so make sure it is set to smoke instead of burn
        else if (EngineHealth <= 0 && (DamagedEffectHealthFireFactor != 0.0 || DamagedEffectHealthHeavySmokeFactor != 1.0))
        {
            DamagedEffectHealthFireFactor = 0.0;
            DamagedEffectHealthHeavySmokeFactor = 1.0;
            DamagedEffectHealthSmokeFactor = 1.0; // appears necessary to get native code to spawn a DamagedEffect if it doesn't already exist
                                                  // (presumably doesn't check for fire or dark smoke unless vehicle is at least damaged enough to lightly smoke)
            if (DamagedEffect != none)
            {
                DamagedEffect.UpdateDamagedEffect(false, 0.0, false, false); // reset existing effect
                DamagedEffect.UpdateDamagedEffect(false, 0.0, false, true);  // then set to dark smoke
            }
            else if (Health == HealthMax) // clientside Health hack to get native code to spawn DamagedEffect (it won't unless vehicle has taken some damage)
            {
                Health--;
            }
        }
    }

    // If engine is off, update sound to burning or smoking sound)
    if (bEngineOff)
    {
        SetEngine();
    }
}

// New function to start a driver's hatch fire effect
simulated function StartDriverHatchFire()
{
    bDriverHatchFireNeeded = false;

    if (DriverHatchFireEffect == none && Level.NetMode != NM_DedicatedServer)
    {
        DriverHatchFireEffect = Spawn(FireEffectClass);
    }

    if (DriverHatchFireEffect != none)
    {
        AttachToBone(DriverHatchFireEffect, FireAttachBone);
        DriverHatchFireEffect.SetRelativeLocation(FireEffectOffset);
        DriverHatchFireEffect.UpdateDamagedEffect(true, 0.0, false, false);

        if (DamagedEffectScale != 1.0)
        {
            DriverHatchFireEffect.SetEffectScale(DamagedEffectScale);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ************************  HIT DETECTION & PENETRATION  ************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New function to check if something hit a certain DH NewVehHitpoints
function bool IsNewPointShot(vector Loc, vector Ray, float AdditionalScale, int Index)
{
    local coords C;
    local vector HeadLoc, B, M, Diff;
    local float  t, DotMM, Distance;

    if (NewVehHitpoints[Index].PointBone == '')
    {
        return false;
    }

    C = GetBoneCoords(NewVehHitpoints[Index].PointBone);

    HeadLoc = C.Origin + (NewVehHitpoints[Index].PointHeight * NewVehHitpoints[Index].PointScale * AdditionalScale * C.XAxis);
    HeadLoc = HeadLoc + (NewVehHitpoints[Index].PointOffset >> rotator(C.XAxis));

    // Express snipe trace line in terms of B + tM
    B = Loc;
    M = Ray * 150.0;

    // Find point-line squared distance
    Diff = HeadLoc - B;
    t = M dot Diff;

    if (t > 0.0)
    {
        DotMM = M dot M;

        if (t < DotMM)
        {
            t = t / DotMM;
            Diff = Diff - (t * M);
        }
        else
        {
            t = 1.0;
            Diff -= M;
        }
    }
    else
    {
        t = 0;
    }

    Distance = Sqrt(Diff dot Diff);

    return (Distance < (NewVehHitpoints[Index].PointRadius * NewVehHitpoints[Index].PointScale * AdditionalScale));
}

// Re-written from deprecated ROTreadCraft class for DH's armour penetration system
// Handles penetration calcs for any shell type, & adds including an option for multiple armor sections for each side
simulated function bool ShouldPenetrate(DHAntiVehicleProjectile P, vector HitLocation, vector ProjectileDirection, float MaxArmorPenetration)
{
    local vector  HitLocationRelativeOffset, HitSideAxis, ArmorNormal, X, Y, Z;
    local rotator ArmourSlopeRotator;
    local float   HitLocationAngle, AngleOfIncidence, ArmorThickness, ArmorSlope;
    local float   OverMatchFactor, SlopeMultiplier, EffectiveArmorThickness, PenetrationRatio;
    local int     i;
    local string  HitSide, OppositeSide, DebugString1, DebugString2;
    local bool    bRearHit;
    local array<ArmorSection> HitSideArmorArray;

    ProjectileDirection = Normal(ProjectileDirection); // should be passed as a normal but we need to be certain
    GetAxes(Rotation, X, Y, Z);

    // Calculate the angle direction of hit relative to vehicle's facing direction, so we can work out out which side was hit (a 'top down 2D' angle calc)
    // Start by getting the offset of HitLocation from vehicle's centre, relative to vehicle's facing direction
    // Then convert to a rotator &, because it's relative, we can simply use the yaw element to give us the angle direction of hit, relative to vehicle
    // Must ignore relative height of hit (represented now by rotator's pitch) as isn't a factor in 'top down 2D' calc & would sometimes actually distort result
    HitLocationRelativeOffset = (HitLocation - Location) << Rotation;
    HitLocationAngle = class'UUnits'.static.UnrealToDegrees(rotator(HitLocationRelativeOffset).Yaw);

    if (HitLocationAngle < 0.0)
    {
        HitLocationAngle += 360.0; // convert negative angles to 180 to 360 degree format
    }

    // Assign settings based on which side we hit
    if (HitLocationAngle >= FrontLeftAngle || HitLocationAngle < FrontRightAngle) // frontal hit
    {
        HitSide = "front";
        OppositeSide = "rear";
        HitSideAxis = X;
    }
    else if (HitLocationAngle >= FrontRightAngle && HitLocationAngle < RearRightAngle) // right side hit
    {
        HitSide = "right";
        OppositeSide = "left";
        HitSideAxis = Y;
    }
    else if (HitLocationAngle >= RearRightAngle && HitLocationAngle < RearLeftAngle) // rear hit
    {
        HitSide = "rear";
        OppositeSide = "front";
        HitSideAxis = -X;
    }
    else if (HitLocationAngle >= RearLeftAngle && HitLocationAngle < FrontLeftAngle) // left side hit
    {
        HitSide = "left";
        OppositeSide = "right";
        HitSideAxis = -Y;
    }
    else // didn't hit any side !! (angles must be screwed up, so fix those)
    {
        Log("ERROR: hull angles not set up correctly for" @ Tag @ "(took hit from" @ HitLocationAngle @ "degrees & couldn't resolve which side that was");

        if ((bDebugPenetration || class'DH_LevelInfo'.static.DHDebugMode()) && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "ERROR: hull angles not set up correctly for" @ Tag @ "(took hit from" @ HitLocationAngle @ "degrees & couldn't resolve which side that was");
        }

        ResetTakeDamageVariables();

        return false;
    }

    // Check for 'hit bug', where a projectile may pass through the 1st face of vehicle's collision & be detected as a hit on the opposite side (on the way out)
    // Calculate incoming angle of the shot, relative to perpendicular from the side we think we hit (ignoring armor slope for now; just a reality check on calculated side)
    // If the angle is too high it's impossible, so we do a crude fix by switching the hit to the opposite
    // Angle of over 90 degrees is theoretically impossible, but in reality vehicles aren't regular shaped boxes & it is possible for legitimate hits a bit over 90 degrees
    // So have softened the threshold to 120 degrees, which should still catch genuine hit bugs
    // Also modified to skip this check for deflected shots, which can ricochet onto another part of the vehicle at weird angles
    if (P.NumDeflections == 0)
    {
        AngleOfIncidence = class'UUnits'.static.RadiansToDegrees(Acos(-ProjectileDirection dot HitSideAxis));

        if (AngleOfIncidence > 120.0)
        {
            if (bLogDebugPenetration || class'DH_LevelInfo'.static.DHDebugMode())
            {
                Log("Hit detection bug - switching from" @ HitSide @ "to" @ OppositeSide
                    @ "as angle of incidence to original side was" @ int(Round(AngleOfIncidence)) @ "degrees");
            }

            if ((bDebugPenetration || class'DH_LevelInfo'.static.DHDebugMode()) && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit detection bug - switching from" @ HitSide @ "to" @ OppositeSide
                    @ "as angle of incidence to original side was" @ int(Round(AngleOfIncidence)) @ "degrees");
            }

            HitSide = OppositeSide;
            HitSideAxis = -HitSideAxis;
        }
    }

    // Get the relevant armour array to use, based on which side we hit
    if (HitSide ~= "front")
    {
        HitSideArmorArray = FrontArmor;
    }
    else if (HitSide ~= "rear")
    {
        HitSideArmorArray = RearArmor;
        bRearHit = true; // so we can set bRearHullPenetration if we do penetrate (it's used in TakeDamage)
    }
    else if (HitSide ~= "right" || HitSide ~= "left")
    {
        // No penetration if vehicle has extra side armor that stops HEAT projectiles, so exit here (after any debug options)
        if (bHasAddedSideArmor && P.RoundType == RT_HEAT)
        {
            if (bLogDebugPenetration)
            {
                Log("Hit hull" @ HitSide $ ": no penetration as extra side armor stops HEAT projectiles");
            }

            if (bDebugPenetration && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit hull" @ HitSide $ ": no penetration as extra side armor stops HEAT projectiles");
            }

            ResetTakeDamageVariables();

            return false;
        }

        if (HitSide ~= "right")
        {
            HitSideArmorArray = RightArmor;
        }
        else
        {
            HitSideArmorArray = LeftArmor;
        }
    }

    // Loop through the armor array for the side of the vehicle we hit, to find which height band (relative to hull mesh centre) our hit fits within
    // Then get the armor thickness & slope for that section, & append any extra location description for the armor plate
    for (i = 0; i < HitSideArmorArray.Length; ++i)
    {
        if (HitLocationRelativeOffset.Z <= HitSideArmorArray[i].MaxRelativeHeight || i == HitSideArmorArray.Length - 1)
        {
            ArmorThickness = HitSideArmorArray[i].Thickness;
            ArmorSlope = HitSideArmorArray[i].Slope;

            if (HitSideArmorArray[i].LocationName != "")
            {
                HitSide @= HitSideArmorArray[i].LocationName;
            }

            break;
        }
    }

    // Calculate the effective armor thickness, factoring in projectile's angle of incidence, & compare to projectile's penetration capability
    // We can skip these calcs if MaxArmorPenetration doesn't exceed ArmorThickness, because that means we can't ever penetrate
    // But if a debug option is enabled, we'll do the calcs as they get used in the debug
    if (MaxArmorPenetration > ArmorThickness || ((bLogDebugPenetration || bDebugPenetration) && P.NumDeflections == 0))
    {
        // Calculate the projectile's angle of incidence to the actual armor slope
        // Apply armor slope to HitSideAxis to get an ArmorNormal (a normal from the sloping face of the armor), then calculate an AOI relative to that
        ArmourSlopeRotator.Pitch = class'UUnits'.static.DegreesToUnreal(ArmorSlope);
        ArmorNormal = Normal(vector(ArmourSlopeRotator) >> rotator(HitSideAxis));
        AngleOfIncidence = class'UUnits'.static.RadiansToDegrees(Acos(-ProjectileDirection dot ArmorNormal));

        // Get the armor's slope multiplier to calculate effective armor thickness
        OverMatchFactor = ArmorThickness / P.ShellDiameter;
        SlopeMultiplier = GetArmorSlopeMultiplier(P, AngleOfIncidence, OverMatchFactor);
        EffectiveArmorThickness = ArmorThickness * SlopeMultiplier;

        // Get the penetration ratio (penetration capability vs effective thickness)
        PenetrationRatio = MaxArmorPenetration / EffectiveArmorThickness;
    }

    // Check & record whether or not we penetrated the vehicle (including check if shattered on the armor)
    P.bRoundShattered = P.bShatterProne && PenetrationRatio >= 1.0 && CheckIfShatters(P, PenetrationRatio, OverMatchFactor);
    bProjectilePenetrated = PenetrationRatio >= 1.0 && !P.bRoundShattered;

    // Set variables used in TakeDamage()
    bHEATPenetration = P.RoundType == RT_HEAT && bProjectilePenetrated;
    bRearHullPenetration = bRearHit && bProjectilePenetrated;
    bTurretPenetration = false;

    // Debugging options
    if ((bLogDebugPenetration || bDebugPenetration) && P.NumDeflections == 0)
    {
        DebugString1 = Caps("Hit hull" @ HitSide) $ ": penetrated =" @ Locs(bProjectilePenetrated) $ ", hit location angle ="
            @ int(Round(HitLocationAngle)) @ "deg, armor =" @ int(Round(ArmorThickness * 10.0)) $ "mm @" @ int(Round(ArmorSlope)) @ "deg";

        DebugString2 = "Shot penetration =" @ int(Round(MaxArmorPenetration * 10.0)) $ "mm, effective armor =" @ int(Round(EffectiveArmorThickness * 10.0))
            $ "mm, shot AOI =" @ int(Round(AngleOfIncidence)) @ "deg, armor slope multiplier =" @ SlopeMultiplier;

        if (bLogDebugPenetration)
        {
            Log(DebugString1);
            Log(DebugString2);
            Log("------------------------------------------------------------------------------------------------------");
        }

        if (bDebugPenetration)
        {
            if (Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, DebugString1);
                Level.Game.Broadcast(self, DebugString2);
            }

            if (Level.NetMode != NM_DedicatedServer)
            {
                ClearStayingDebugLines();
                DrawStayingDebugLine(HitLocation, HitLocation + (600.0 * ArmorNormal), 0, 0, 255); // blue line for ArmorNormal

                if (bProjectilePenetrated)
                {
                    DrawStayingDebugLine(HitLocation, HitLocation + (2000.0 * -ProjectileDirection), 0, 255, 0); // green line for penetration
                }
                else
                {
                    DrawStayingDebugLine(HitLocation, HitLocation + (2000.0 * -ProjectileDirection), 255, 0, 0); // red line if failed to penetrate
                }
            }
        }
    }

    // Finally return whether or not we penetrated the vehicle hull
    return bProjectilePenetrated;
}

// New function to calculate the appropriate armor slope multiplier for various projectile types & angles
// A static function so it can be used by cannon class for turret armor, avoiding lots of armor code repetition (same with several others)
simulated static function float GetArmorSlopeMultiplier(DHAntiVehicleProjectile P, float AngleOfIncidence, optional float OverMatchFactor)
{
    local float CompoundExp, BaseLookupAngle, DegreesSpread, ExtraAngleDegrees, BaseSlopeMultiplier, NextSlopeMultiplier, MultiplierDifference;

    if (P.RoundType == RT_HVAP)
    {
        if (P.ShellDiameter > 8.5) // HVAP rounds bigger than 85mm shell diameter (instead of using separate RoundType RT_HVAPLarge)
        {
            if (AngleOfIncidence <= 30.0)
            {
               CompoundExp = AngleOfIncidence ** 1.75;

               return 2.71828 ** (CompoundExp * 0.000662);
            }
            else
            {
               CompoundExp = AngleOfIncidence ** 2.2;

               return 0.9043 * (2.71828 ** (CompoundExp * 0.0001987));
            }
        }
        else // smaller HVAP rounds
        {
            if (AngleOfIncidence <= 25.0)
            {
               CompoundExp = AngleOfIncidence ** 2.2;

               return 2.71828 ** (CompoundExp * 0.0001727);
            }
            else
            {
               CompoundExp = AngleOfIncidence ** 1.5;

               return 0.7277 * (2.71828 ** (CompoundExp * 0.003787));
            }
        }
    }
    else if (P.RoundType == RT_APDS)
    {
        CompoundExp = AngleOfIncidence ** 2.6;

        return 2.71828 ** (CompoundExp * 0.00003011);
    }
    else if (P.RoundType == RT_HEAT)
    {
        return 1.0 / Cos(class'UUnits'.static.DegreesToRadians(Abs(AngleOfIncidence)));
    }
    else // should mean RoundType is RT_APC, RT_HE or RT_Smoke, but treating this as a catch-all default (will also handle DO's AP & APBC shells)
    {
        if (AngleOfIncidence < 10.0)
        {
            BaseLookupAngle = 10.0; // we'll start with base multiplier for 10 degrees & then reduce based on how far much lower than 10 we are
            DegreesSpread = 10.0;
        }
        else
        {
            BaseLookupAngle = float(int(AngleOfIncidence / 5.0)) * 5.0; // to nearest 5 degrees, rounded down
            DegreesSpread = 5.0;
        }

        ExtraAngleDegrees = AngleOfIncidence - BaseLookupAngle;
        BaseSlopeMultiplier = ArmorSlopeTable(P, BaseLookupAngle, OverMatchFactor);
        NextSlopeMultiplier = ArmorSlopeTable(P, BaseLookupAngle + 5.0, OverMatchFactor);
        MultiplierDifference = NextSlopeMultiplier - BaseSlopeMultiplier;

        return BaseSlopeMultiplier + (ExtraAngleDegrees / DegreesSpread * MultiplierDifference);
    }

    return 1.0; // fail-safe neutral return value
}

// New lookup function to calculate the appropriate armor slope multiplier for various projectile types & angles
// All from "WWII Ballistics: Armor & Gunnery" by Bird & Livingston
// A static function so it can be used by cannon class for turret armor, avoiding lots of armor code repetition (same with several others)
simulated static function float ArmorSlopeTable(DHAntiVehicleProjectile P, float AngleOfIncidence, float OverMatchFactor)
{
    if (P.RoundType == RT_AP) // from Darkest Orchestra
    {
        if      (AngleOfIncidence <= 10.0)  return 0.98  * (OverMatchFactor ** 0.06370); // at 10 degrees
        else if (AngleOfIncidence <= 15.0)  return 1.00  * (OverMatchFactor ** 0.09690);
        else if (AngleOfIncidence <= 20.0)  return 1.04  * (OverMatchFactor ** 0.13561);
        else if (AngleOfIncidence <= 25.0)  return 1.11  * (OverMatchFactor ** 0.16164);
        else if (AngleOfIncidence <= 30.0)  return 1.22  * (OverMatchFactor ** 0.19702);
        else if (AngleOfIncidence <= 35.0)  return 1.38  * (OverMatchFactor ** 0.22546);
        else if (AngleOfIncidence <= 40.0)  return 1.63  * (OverMatchFactor ** 0.26313);
        else if (AngleOfIncidence <= 45.0)  return 2.00  * (OverMatchFactor ** 0.34717);
        else if (AngleOfIncidence <= 50.0)  return 2.64  * (OverMatchFactor ** 0.57353);
        else if (AngleOfIncidence <= 55.0)  return 3.23  * (OverMatchFactor ** 0.69075);
        else if (AngleOfIncidence <= 60.0)  return 4.07  * (OverMatchFactor ** 0.81826);
        else if (AngleOfIncidence <= 65.0)  return 6.27  * (OverMatchFactor ** 0.91920);
        else if (AngleOfIncidence <= 70.0)  return 8.65  * (OverMatchFactor ** 1.00539);
        else if (AngleOfIncidence <= 75.0)  return 13.75 * (OverMatchFactor ** 1.07400);
        else if (AngleOfIncidence <= 80.0)  return 21.87 * (OverMatchFactor ** 1.17973);
        else                                       return 34.49 * (OverMatchFactor ** 1.28631); // at 85 degrees
    }
    else if (P.RoundType == RT_APBC) // from Darkest Orchestra
    {
        if      (AngleOfIncidence <= 10.0)  return 1.04  * (OverMatchFactor ** 0.01555); // at 10 degrees
        else if (AngleOfIncidence <= 15.0)  return 1.06  * (OverMatchFactor ** 0.02315);
        else if (AngleOfIncidence <= 20.0)  return 1.08  * (OverMatchFactor ** 0.03448);
        else if (AngleOfIncidence <= 25.0)  return 1.11  * (OverMatchFactor ** 0.05134);
        else if (AngleOfIncidence <= 30.0)  return 1.16  * (OverMatchFactor ** 0.07710);
        else if (AngleOfIncidence <= 35.0)  return 1.22  * (OverMatchFactor ** 0.11384);
        else if (AngleOfIncidence <= 40.0)  return 1.31  * (OverMatchFactor ** 0.16952);
        else if (AngleOfIncidence <= 45.0)  return 1.44  * (OverMatchFactor ** 0.24604);
        else if (AngleOfIncidence <= 50.0)  return 1.68  * (OverMatchFactor ** 0.37910);
        else if (AngleOfIncidence <= 55.0)  return 2.11  * (OverMatchFactor ** 0.56444);
        else if (AngleOfIncidence <= 60.0)  return 3.50  * (OverMatchFactor ** 1.07411);
        else if (AngleOfIncidence <= 65.0)  return 5.34  * (OverMatchFactor ** 1.46188);
        else if (AngleOfIncidence <= 70.0)  return 9.48  * (OverMatchFactor ** 1.81520);
        else if (AngleOfIncidence <= 75.0)  return 20.22 * (OverMatchFactor ** 2.19155);
        else if (AngleOfIncidence <= 80.0)  return 56.20 * (OverMatchFactor ** 2.56210);
        else                                       return 221.3 * (OverMatchFactor ** 2.93265); // at 85 degrees
    }
    else // should mean RoundType is RT_APC (also covers APCBC) or RT_HE, but treating this as a catch-all default
    {
        if      (AngleOfIncidence <= 10.0)  return 1.01  * (OverMatchFactor ** 0.0225); // at 10 degrees
        else if (AngleOfIncidence <= 15.0)  return 1.03  * (OverMatchFactor ** 0.0327);
        else if (AngleOfIncidence <= 20.0)  return 1.10  * (OverMatchFactor ** 0.0454);
        else if (AngleOfIncidence <= 25.0)  return 1.17  * (OverMatchFactor ** 0.0549);
        else if (AngleOfIncidence <= 30.0)  return 1.27  * (OverMatchFactor ** 0.0655);
        else if (AngleOfIncidence <= 35.0)  return 1.39  * (OverMatchFactor ** 0.0993);
        else if (AngleOfIncidence <= 40.0)  return 1.54  * (OverMatchFactor ** 0.1388);
        else if (AngleOfIncidence <= 45.0)  return 1.72  * (OverMatchFactor ** 0.1655);
        else if (AngleOfIncidence <= 50.0)  return 1.94  * (OverMatchFactor ** 0.2035);
        else if (AngleOfIncidence <= 55.0)  return 2.12  * (OverMatchFactor ** 0.2427);
        else if (AngleOfIncidence <= 60.0)  return 2.56  * (OverMatchFactor ** 0.2450);
        else if (AngleOfIncidence <= 65.0)  return 3.20  * (OverMatchFactor ** 0.3354);
        else if (AngleOfIncidence <= 70.0)  return 3.98  * (OverMatchFactor ** 0.3478);
        else if (AngleOfIncidence <= 75.0)  return 5.17  * (OverMatchFactor ** 0.3831);
        else if (AngleOfIncidence <= 80.0)  return 8.09  * (OverMatchFactor ** 0.4131);
        else                                       return 11.32 * (OverMatchFactor ** 0.4550); // at 85 degrees
    }

    return 1.0; // fail-safe neutral return value
}

// New function to check whether a projectile should shatter on vehicle's armor, based on the 'shatter gap' for different round types
// A static function so it can be used by cannon class for turret armor, avoiding lots of armor code repetition (same with several others)
simulated static function bool CheckIfShatters(DHAntiVehicleProjectile P, float PenetrationRatio, optional float OverMatchFactor)
{
    if (P.RoundType == RT_HVAP)
    {
        if (P.ShellDiameter >= 9.0) // HVAP rounds of at least 90mm shell diameter, e.g. Jackson's 90mm cannon (instead of using separate RoundType RT_HVAPLarge)
        {
            if (PenetrationRatio >= 1.1 && PenetrationRatio <= 1.27)
            {
                return true;
            }
        }
        else // smaller HVAP rounds
        {
            if (PenetrationRatio >= 1.1 && PenetrationRatio <= 1.34)
            {
                return true;
            }
        }
    }
    else if (P.RoundType == RT_APDS)
    {
        if (PenetrationRatio >= 1.06 && PenetrationRatio <= 1.2)
        {
            return true;
        }
    }
    else if (P.RoundType == RT_HEAT) // no chance of shatter for HEAT round
    {
    }
    else // should mean RoundType is RT_APC, RT_HE or RT_Smoke, but treating this as a catch-all default (will also handle DO's AP & APBC shells)
    {
        if (OverMatchFactor > 0.8 && PenetrationRatio >= 1.06 && PenetrationRatio <= 1.19)
        {
            return true;
        }
    }

    return false;
}

///////////////////////////////////////////////////////////////////////////////////////
//  *********************************  DAMAGE  ************************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to DH special damage points, random special damage and/or crew deaths if penetrated, & possibility of setting engine or vehicle on fire
// Also to use TankDamageModifier instead of VehicleDamageModifier (unless an APC)
function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
    local DHVehicleCannonPawn CannonPawn;
    local Controller InstigatorController;
    local float      VehicleDamageMod, TreadDamageMod, HullChanceModifier, TurretChanceModifier;
    local int        InstigatorTeam, i;
    local bool       bEngineStoppedProjectile, bAmmoDetonation;

    // Suicide/self-destruction
    if (DamageType == class'Suicided' || DamageType == class'ROSuicided')
    {
        super(Vehicle).TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, class'ROSuicided');

        ResetTakeDamageVariables();

        return;
    }

    // Quick fix for the vehicle giving itself impact damage
    if (InstigatedBy == self && DamageType != VehicleBurningDamType)
    {
        ResetTakeDamageVariables();

        return;
    }

    // Prevent griefer players from damaging own team's vehicles that haven't yet been entered, i.e. are sitting in a spawn area (not applicable in single player)
    if (!bDriverAlreadyEntered && Level.NetMode != NM_Standalone)
    {
        if (InstigatedBy != none)
        {
            InstigatorController = InstigatedBy.Controller;
        }

        if (InstigatorController == none && DamageType.default.bDelayedDamage)
        {
            InstigatorController = DelayedDamageInstigatorController;
        }

        if (InstigatorController != none)
        {
            InstigatorTeam = InstigatorController.GetTeamNum();

            if (GetTeamNum() != 255 && InstigatorTeam != 255 && GetTeamNum() == InstigatorTeam)
            {
                ResetTakeDamageVariables();

                return;
            }
        }
    }

    // Set damage modifiers from the DamageType, based on type of vehicle
    if (class<ROWeaponDamageType>(DamageType) != none)
    {
        if (bIsApc)
        {
            VehicleDamageMod = class<ROWeaponDamageType>(DamageType).default.APCDamageModifier;
        }
        else
        {
            VehicleDamageMod = class<ROWeaponDamageType>(DamageType).default.TankDamageModifier;
        }

        if (bHasTreads)
        {
            TreadDamageMod = class<ROWeaponDamageType>(DamageType).default.TreadDamageModifier;
        }
    }
    else if (class<ROVehicleDamageType>(DamageType) != none)
    {
        if (bIsApc)
        {
            VehicleDamageMod  = class<ROVehicleDamageType>(DamageType).default.APCDamageModifier;
        }
        else
        {
            VehicleDamageMod = class<ROVehicleDamageType>(DamageType).default.TankDamageModifier;
        }

        if (bHasTreads)
        {
            TreadDamageMod = class<ROVehicleDamageType>(DamageType).default.TreadDamageModifier;
        }
    }

    // Add in the DamageType's vehicle damage modifier & a little damage randomisation (but not for fire damage as it messes up timings)
    if (DamageType != VehicleBurningDamType)
    {
        Damage *= (VehicleDamageMod * RandRange(0.75, 1.08));
    }
    else
    {
        Damage *= VehicleDamageMod;
    }

    // Exit if no damage
    if (Damage < 1)
    {
        ResetTakeDamageVariables();

        return;
    }

    // Check RO VehHitpoints (engine, ammo)
    // Note driver hit check is deprecated as we use a new player hit detection system, which basically uses normal hit detection as for an infantry player pawn
    if (bProjectilePenetrated)
    {
        for (i = 0; i < VehHitpoints.Length; ++i)
        {
            if (IsPointShot(HitLocation, Momentum, 1.0, i))
            {
                if (bLogDebugPenetration)
                {
                    Log("We hit VehHitpoints[" $ i $ "]:" @ GetEnum(enum'EHitPointType', VehHitpoints[i].HitPointType));
                }

                // Engine hit
                if (VehHitpoints[i].HitPointType == HP_Engine)
                {
                    if (bDebuggingText)
                    {
                        Level.Game.Broadcast(self, "Hit vehicle engine");
                    }

                    DamageEngine(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
                    Damage *= 0.55; // reduce damage to vehicle itself if hit engine

                    // Shot from the rear that hits engine will stop shell from passing through to cabin, so don't check any more VehHitpoints
                    if (bRearHullPenetration)
                    {
                        bEngineStoppedProjectile = true;
                        break;
                    }
                }
                // Hit ammo store
                else if (VehHitpoints[i].HitPointType == HP_AmmoStore)
                {
                    // Random chance that ammo explodes & vehicle is destroyed
                    if ((bHEATPenetration && FRand() < 0.85) || (!bHEATPenetration && FRand() < AmmoIgnitionProbability))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Hit vehicle ammo store - exploded");
                        }

                        Damage *= Health;
                        bAmmoDetonation = true; // stops unnecessary penetration checks, as the vehicle is going to explode anyway
                        break;
                    }
                    // Even if ammo did not explode, increase the chance of a fire breaking out
                    else
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Hit vehicle ammo store but did not explode");
                        }

                        HullFireChance = FMax(0.75, HullFireChance);
                        HullFireHEATChance = FMax(0.90, HullFireHEATChance);
                    }
                }
            }
        }
    }

    if (!bEngineStoppedProjectile && !bAmmoDetonation) // we can skip lots of checks if either has been flagged true
    {
        if ((bProjectilePenetrated || NewVehHitpoints.Length > 0) && Cannon != none)
        {
            CannonPawn = DHVehicleCannonPawn(Cannon.WeaponPawn);
        }

        // Check additional DH NewVehHitPoints
        for (i = 0; i < NewVehHitpoints.Length; ++i)
        {
            if (IsNewPointShot(HitLocation, Momentum, 1.0, i))
            {
                if (bLogDebugPenetration)
                {
                    Log("We hit NewVehHitpoints[" $ i $ "]:" @ GetEnum(enum'EHitPointType', NewVehHitpoints[i].NewHitPointType));
                }

                // Hit periscope optics
                if (NewVehHitpoints[i].NewHitPointType == NHP_PeriscopeOptics)
                {
                    // does nothing at present - possibly add in future
                }
                else if (CannonPawn != none)
                {
                    // Hit exposed gunsight optics
                    if (NewVehHitpoints[i].NewHitPointType == NHP_GunOptics)
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Hit gunsight optics");
                        }

                        CannonPawn.DamageCannonOverlay();
                    }
                    else if (bProjectilePenetrated)
                    {
                        // Hit turret ring or gun traverse mechanism
                        if (NewVehHitpoints[i].NewHitPointType == NHP_Traverse)
                        {
                            if (bDebuggingText)
                            {
                                Level.Game.Broadcast(self, "Hit gun/turret traverse");
                            }

                            CannonPawn.bTurretRingDamaged = true;
                        }
                        // Hit gun pivot mechanism
                        else if (NewVehHitpoints[i].NewHitPointType == NHP_GunPitch)
                        {
                            if (bDebuggingText)
                            {
                                Level.Game.Broadcast(self, "Hit gun pivot");
                            }

                            CannonPawn.bGunPivotDamaged = true;
                        }
                    }
                }
            }
        }

        // Random damage to crew or vehicle components, caused by shrapnel etc flying around inside the vehicle from penetration, regardless of where it hit
        if (bProjectilePenetrated)
        {
            if (Cannon != none)
            {
                // Although shrapnel etc can get everywhere, modify chance of random damage based on whether penetration was to hull or turret
                if (Cannon.bHasTurret)
                {
                    if (bTurretPenetration)
                    {
                        HullChanceModifier = 0.5;   // half usual chance of damage to things in the hull
                        TurretChanceModifier = 1.0;
                    }
                    else
                    {
                        HullChanceModifier = 1.0;
                        TurretChanceModifier = 0.5; // half usual chance of damage to things in the turret
                    }
                }
                else // normal chance of damage to everything in vehicles without a turret (e.g. casemate-style tank destroyers)
                {
                    HullChanceModifier = 1.0;
                    TurretChanceModifier = 1.0;
                }

                if (CannonPawn != none)
                {
                    // Random chance of shrapnel killing commander
                    if (CannonPawn != none && CannonPawn.Driver != none && FRand() < (float(Damage) / CommanderKillChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Commander killed by shrapnel");
                        }

                        CannonPawn.Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
                    }

                    // Random chance of shrapnel damaging gunsight optics
                    if (FRand() < (float(Damage) / OpticsDamageChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Gunsight optics destroyed by shrapnel");
                        }

                        CannonPawn.DamageCannonOverlay();
                    }

                    // Random chance of shrapnel damaging gun pivot mechanism
                    if (FRand() < (float(Damage) / GunDamageChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Gun pivot damaged by shrapnel");
                        }

                        CannonPawn.bGunPivotDamaged = true;
                    }

                    // Random chance of shrapnel damaging gun traverse mechanism
                    if (FRand() < (float(Damage) / TraverseDamageChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Gun/turret traverse damaged by shrapnel");
                        }

                        CannonPawn.bTurretRingDamaged = true;
                    }
                }
            }

            // Random chance of shrapnel detonating turret ammo & destroying the vehicle
            if (FRand() < (float(Damage) / TurretDetonationThreshold * TurretChanceModifier))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Turret ammo detonated by shrapnel");
                }

                Damage *= Health;
                bAmmoDetonation = true; // stops unnecessary penetration checks, as the vehicle is going to explode anyway
            }
            else if (bTurretPenetration)
            {
                Damage *= 0.55; // reduce damage to vehicle itself from a turret hit, if the turret ammo didn't detonate
            }

            // Random chance of shrapnel killing driver
            if (Driver != none && FRand() < (float(Damage) / DriverKillChance * HullChanceModifier))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Driver killed by shrapnel");
                }

                Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
            }

            // Random chance of shrapnel killing hull machine gunner
            if (MGun != none && MGun.WeaponPawn != none && MGun.WeaponPawn.Driver != none && FRand() < (float(Damage) / GunnerKillChance * HullChanceModifier))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Hull gunner killed by shrapnel");
                }

                MGun.WeaponPawn.Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
            }
        }

        // Check if we hit & damaged either track
        if (bHasTreads && TreadDamageMod >= TreadDamageThreshold && !bTurretPenetration && !bRearHullPenetration)
        {
            CheckTreadDamage(HitLocation, Momentum);
        }
    }

    // Call the Super from Vehicle (skip over others)
    super(Vehicle).TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);

    // Vehicle is still alive, so check for possibility of a fire breaking out
    if (Health > 0)
    {
        if (bProjectilePenetrated && !bEngineStoppedProjectile && !bOnFire)
        {
            // Random chance of penetration causing a hull fire // TODO: relate probability to damage, as currently even tiny damage has a high chance of starting a fire
            if ((bHEATPenetration && FRand() < HullFireHEATChance) || (!bHEATPenetration && FRand() < HullFireChance))
            {
                StartHullFire(InstigatedBy);
            }
            // If we didn't start a fire & this is the 1st time a projectile has penetrated, increase the chance of causing a hull fire for any future penetrations
            else if (bFirstPenetratingHit)
            {
                bFirstPenetratingHit = false;
                HullFireChance = FMax(0.75, HullFireChance);
                HullFireHEATChance = FMax(0.90, HullFireHEATChance);
            }
        }

        // If an APC's health is very low, kill the engine & start a fire
        if (bIsApc && Health <= (HealthMax / 3) && EngineHealth > 0)
        {
            EngineHealth = 0;
            bEngineOff = true;
            StartEngineFire(InstigatedBy);
        }
    }

    ResetTakeDamageVariables();
}

// New function to reset all variables used in TakeDamage, ready for next time
function ResetTakeDamageVariables()
{
    bProjectilePenetrated = false;
    bTurretPenetration = false;
    bRearHullPenetration = false;
    bHEATPenetration = false;
}

// Modified to add random chance of engine fire breaking out
function DamageEngine(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    // Apply new damage
    if (EngineHealth > 0)
    {
        if (DamageType != VehicleBurningDamType)
        {
            Damage = Level.Game.ReduceDamage(Damage, self, InstigatedBy, HitLocation, Momentum, DamageType);
        }

        EngineHealth -= Damage;
    }

    // Kill the engine if its health has now fallen to zero
    if (EngineHealth <= 0)
    {
        if (bDebuggingText)
        {
            Level.Game.Broadcast(self, "Engine is dead");
        }

        if (!bEngineOff)
        {
            bEngineOff = true;
            PlaySound(DamagedShutDownSound, SLOT_None, FClamp(Abs(Throttle), 0.3, 0.75));
        }

        SetEngine();
    }
    // Or if engine still alive, a random chance of engine fire breaking out // TODO: relate probability to damage, as currently even tiny damage has a high chance of starting a fire
    else if (DamageType != VehicleBurningDamType && !bEngineOnFire && Damage > 0 && Health > 0)
    {
        if ((bHEATPenetration && FRand() < EngineFireHEATChance) || (!bHEATPenetration && FRand() < EngineFireChance))
        {
            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Engine fire started");
            }

            StartEngineFire(InstigatedBy);
        }
    }
}

// New function to handle hull fire damage
function TakeFireDamage()
{
    local Pawn PawnWhoSetOnFire;
    local int  i;

    if (Role == ROLE_Authority)
    {
        if (WhoSetOnFire != none)
        {
            // If the instigator gets teamswapped before a burning vehicle dies, make sure they don't get friendly kills for it
            if (WhoSetOnFire.GetTeamNum() != HullFireStarterTeam)
            {
                WhoSetOnFire = none;
                DelayedDamageInstigatorController = none;
            }
            else
            {
                PawnWhoSetOnFire = WhoSetOnFire.Pawn;
            }
        }

        // Burn the driver
        if (Driver != none)
        {
            Driver.TakeDamage(PlayerFireDamagePer2Secs, PawnWhoSetOnFire, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }

        // Burn any other vehicle occupants
        for (i = 0; i < WeaponPawns.Length; ++i)
        {
            if (WeaponPawns[i] != none && WeaponPawns[i].Driver != none)
            {
                WeaponPawns[i].Driver.TakeDamage(PlayerFireDamagePer2Secs, PawnWhoSetOnFire, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
            }
        }

        // Chance of cooking off ammo before health runs out
        if (FRand() < FireDetonationChance)
        {
            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Fire detonated ammo");
            }

            TakeDamage(Health, PawnWhoSetOnFire, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }
        // Otherwise the vehicle takes normal fire damage
        else
        {
            TakeDamage(HullFireDamagePer2Secs, PawnWhoSetOnFire, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }

        // Set next hull damage due in another 2 seconds, unless vehicle is now dead
        if (Health > 0)
        {
            NextHullFireDamageTime += 2.0;
        }
    }
}

// New function to handle engine fire damage
function TakeEngineFireDamage()
{
    local Pawn PawnWhoSetOnFire;

    if (Role == ROLE_Authority)
    {
        // Damage engine if not already dead
        if (EngineHealth > 0)
        {
            if (WhoSetEngineOnFire != none)
            {
                // If the instigator gets teamswapped before a burning vehicle dies, make sure they don't get friendly kills for it
                if (WhoSetEngineOnFire.GetTeamNum() != EngineFireStarterTeam)
                {
                    WhoSetEngineOnFire = none;
                    DelayedDamageInstigatorController = none;
                }
                else
                {
                    PawnWhoSetOnFire = WhoSetEngineOnFire.Pawn;
                }
            }

            DamageEngine(EngineFireDamagePer3Secs, PawnWhoSetOnFire, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);

            // Small chance each time of engine fire spreading & setting whole vehicle on fire
            if (!bOnFire && FRand() < EngineToHullFireChance)
            {
                StartHullFire(PawnWhoSetOnFire);
            }

            // Engine not dead, so set next engine damage due in the normal 3 seconds
            if (EngineHealth > 0)
            {
                NextEngineFireDamageTime += 3.0;
            }
            // Engine is dead, but use NextEngineFireDamageTime to set next timer so engine fire dies down 30 secs after engine health hits zero (unless hull has caught fire)
            else if (!bOnFire)
            {
                NextEngineFireDamageTime += 30.0;
            }
        }
        // Engine fire dies down 30 seconds after engine health hits zero, unless hull has caught fire
        else if (!bOnFire)
        {
            bEngineOnFire = false;
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *************************  SETUP, UPDATE, CLEAN UP  ***************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add periscope materials
static function StaticPrecache(LevelInfo L)
{
    super.StaticPrecache(L);

    L.AddPrecacheMaterial(default.PeriscopeOverlay);
    L.AddPrecacheMaterial(default.DamagedPeriscopeOverlay);
}

// Modified to add periscope materials
simulated function UpdatePrecacheMaterials()
{
    super.UpdatePrecacheMaterials();

    Level.AddPrecacheMaterial(PeriscopeOverlay);
    Level.AddPrecacheMaterial(DamagedPeriscopeOverlay);
}

// Modified to include extra attachment
simulated function DestroyAttachments()
{
    super. DestroyAttachments();

    if (DriverHatchFireEffect != none)
    {
        DriverHatchFireEffect.Kill();
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  MISCELLANEOUS ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to stop vehicle from prematurely destroying itself when on fire; instead just let the fire run its course
function MaybeDestroyVehicle()
{
    if (!bOnFire && !bEngineOnFire)
    {
        super.MaybeDestroyVehicle();
    }
}

// Modified to work with interwoven Timer system instead of directly setting a timer for VehicleSpikeTime duration
function SetSpikeTimer()
{
    SpikeTime = Level.TimeSeconds + VehicleSpikeTime;
    SetNextTimer();
}

// Bot functions from deprecated ROTreadCraft class
function bool RecommendLongRangedAttack()
{
    return true;
}

function bool StronglyRecommended(Actor S, int TeamIndex, Actor Objective)
{
    return true;
}

function float ModifyThreat(float Current, Pawn Threat)
{
    local vector to, t;
    local float  r;

    if (Vehicle(Threat) != none)
    {
        Current += 0.2;

        if (DHArmoredVehicle(Threat) != none)
        {
            Current += 0.2;

            // Big bonus points for perpendicular tank targets
            to = Normal(Threat.Location - Location);
            to.z = 0.0;
            t = Normal(vector(Threat.Rotation));
            t.z = 0.0;
            r = to dot t;

            if ((r >= 0.90630 && r < -0.73135) || (r >= -0.73135 && r < 0.90630))
            {
                Current += 0.3;
            }
        }
        else if (ROWheeledVehicle(Threat) != none && ROWheeledVehicle(Threat).bIsAPC)
        {
            Current += 0.1;
        }
    }
    else
    {
        Current += 0.25;
    }

    return Current;
}

///////////////////////////////////////////////////////////////////////////////////////
//  *************************** DEBUG EXEC FUNCTIONS  *****************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New debug exec for testing hull fire damage & effects
exec function HullFire()
{
    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && !bOnFire)
    {
        StartHullFire(none);
    }
}

// New debug exec for testing engine fire damage & effects
exec function EngineFire()
{
    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && !bEngineOnFire)
    {
        StartEngineFire(none);
    }
}

// New debug exec to adjust location of driver's hatch fire position
exec function SetFEOffset(int NewX, int NewY, int NewZ)
{
    if (Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode())
    {
        if (NewX != 0 || NewY != 0 || NewZ != 0)
        {
            FireEffectOffset.X = NewX;
            FireEffectOffset.Y = NewY;
            FireEffectOffset.Z = NewZ;
        }

        StartDriverHatchFire();
        Log(VehicleNameString @ "FireEffectOffset =" @ FireEffectOffset);
    }
}

defaultproperties
{
    // Vehicle properties
    VehicleMass=12.5
    CollisionRadius=175.0
    CollisionHeight=60.0
    PointValue=3.0
    MaxDesireability=1.9
    EngineRestartFailChance=0.1

    // Driver & positions
    bMustBeTankCommander=true
    UnbuttonedPositionIndex=2
    bMustUnbuttonToSwitchToRider=true
    DriverAttachmentBone="Driver_attachment"
    BeginningIdleAnim="driver_hatch_idle_close"
    PeriscopeOverlay=texture'DH_VehicleOptics_tex.Allied.PERISCOPE_overlay_Allied'

    // Damage
    Health=525
    HealthMax=525.0
    EngineHealth=300
    VehHitpoints(0)=(PointBone="Body") // default engine hit point bone
    GunOpticsHitPointIndex=-1 // set in subclass if vehicle has exposed gunsight optics
    TreadDamageThreshold=0.75
    ImpactDamageThreshold=5000.0
    ImpactDamageMult=0.001
    DamagedPeriscopeOverlay=texture'DH_VehicleOptics_tex.Allied.Destroyed'

    // Component damage probabilities
    DriverKillChance=1150.0
    GunnerKillChance=1150.0
    CommanderKillChance=950.0
    OpticsDamageChance=3000.0
    GunDamageChance=1250.0
    TraverseDamageChance=2000.0
    TurretDetonationThreshold=1750.0
    AmmoIgnitionProbability=0.75

    // Vehicle fires
    HullFireChance=0.25
    HullFireHEATChance=0.5
    EngineFireChance=0.5
    EngineFireHEATChance=0.85
    EngineToHullFireChance=0.05
    PlayerFireDamagePer2Secs=15.0
    FireDetonationChance=0.07
    bFirstPenetratingHit=true
    VehicleBurningDamType=class'DHVehicleBurningDamageType'

    // Burning/smoking vehicle effects
    DamagedEffectOffset=(X=-40.0,Y=10.0,Z=10.0) // position of engine smoke or fire
    HeavyEngineDamageThreshold=0.5
    DamagedEffectHealthSmokeFactor=0.85
    DamagedEffectHealthMediumSmokeFactor=0.65
    DamagedEffectHealthHeavySmokeFactor=0.35
    DamagedEffectHealthFireFactor=0.0
    FireEffectClass=class'ROEngine.VehicleDamagedEffect' // driver's hatch fire
    FireAttachBone="driver_player"
    FireEffectOffset=(X=0.0,Y=0.0,Z=-10.0)

    // Vehicle destruction
    DestructionEffectClass=class'ROEffects.ROVehicleDestroyedEmitter'
    DestructionEffectLowClass=class'ROEffects.ROVehicleDestroyedEmitter_simple'
    DisintegrationEffectClass=class'ROEffects.ROVehicleObliteratedEmitter'
    DisintegrationEffectLowClass=class'ROEffects.ROVehicleObliteratedEmitter_simple'
    DisintegrationHealth=-10000.0 // -10000 default to make classes enable disintegration
    DestructionLinearMomentum=(Min=100.0,Max=350.0)
    DestructionAngularMomentum=(Min=50.0,Max=150.0)
    ExplosionDamage=575.0
    ExplosionRadius=900.0
    ExplosionSoundRadius=1000.0

    // Vehicle reset/respawn
    VehicleSpikeTime=60.0     // if disabled
    TimeTilDissapear=90.0     // after destroyed
    IdleTimeBeforeReset=200.0 // if empty & no friendlies nearby

    // Treads & track wheels
    bHasTreads=true
    LeftTreadIndex=1
    RightTreadIndex=2
    LeftTreadPanDirection=(Pitch=0,Yaw=0,Roll=16384)
    RightTreadPanDirection=(Pitch=0,Yaw=0,Roll=16384)
    TreadVelocityScale=450.0
    WheelRotationScale=700

    // Sounds
    SoundRadius=650.0
    TransientSoundRadius=700.0
    SmokingEngineSound=sound'Amb_Constructions.steam.Krasnyi_Steam_Deep'
    TrackDamagedSound=sound'Vehicle_Engines.track_broken'
    LeftTrackSoundBone="Track_L"
    RightTrackSoundBone="Track_R"
    RumbleSoundBone="body"
    RumbleSoundVolumeModifier=1.0

    // Visible effects
    SparkEffectClass=class'ROEngine.VehicleImpactSparks' // reinstate from ROVehicle (removed for non-armoured DHVehicles)
    SteeringScaleFactor=0.75
    SteerBoneAxis=AXIS_X
    LeftLeverAxis=AXIS_Z
    RightLeverAxis=AXIS_Z

    // Camera
    PlayerCameraBone="Camera_driver"
    TPCamDistance=375.0
    TPCamLookat=(X=0.0,Y=0.0,Z=0.0)
    TPCamWorldOffset=(X=0.0,Y=0.0,Z=100.0)

    // Vew shake
    bEnableProximityViewShake=false // TODO - this is default false anyway, but interesting to test enabling this, as could be a good feature for heavy vehicles
    ViewShakeRadius=50.0   // was 600 in RO
    ViewShakeOffsetMag=(X=0.0,Y=0.0,Z=0.0) // was X=0.5,Z=2 in RO
    ViewShakeOffsetFreq=0.0 // was 7 in RO

    // Force feedback
    StartUpForce="TankStartUp"
    ShutDownForce="TankShutDown"
    CenterSpringForce="SpringONSSRV"

    // Exit positions
    ExitPositions(0)=(X=0.0,Y=-165.0,Z=40.0)
    ExitPositions(1)=(X=0.0,Y=165.0,Z=40.0)
    ExitPositions(2)=(X=0.0,Y=-165.0,Z=-40.0)
    ExitPositions(3)=(X=0.0,Y=165.0,Z=-40.0)

    // Driving & movement
    MaxCriticalSpeed=700.0 // approx 42 kph
    GroundSpeed=325.0
    TorqueCurve=(Points=((InVal=0,OutVal=12.0),(InVal=200,OutVal=3.0),(InVal=1500,OutVal=4.0),(InVal=2200,OutVal=0.0)))
    GearRatios(0)=-0.2
    GearRatios(1)=0.2
    GearRatios(2)=0.35
    GearRatios(3)=0.55
    GearRatios(4)=0.6
    TransRatio=0.12
    ChangeUpPoint=2050.0   // was 2000 in RO
    ChangeDownPoint=1100.0 // was 1000 in RO
    LSDFactor=1.0
    FTScale=0.03
    ChassisTorqueScale=0.9 // was 0.25 in RO
    MinBrakeFriction=4.0
    EngineBrakeFactor=0.0001
    EngineBrakeRPMScale=0.1
    EngineInertia=0.1
    IdleRPM=500.0
    EngineRPMSoundRange=5000
    RevMeterScale=4000.0

    // Steering & braking
    bSpecialTankTurning=true
    MaxSteerAngleCurve=(Points=((OutVal=35.0),(InVal=1500.0,OutVal=20.0),(InVal=1000000000.0,OutVal=15.0)))
    SteerSpeed=160.0
    TurnDamping=50
    bHasHandbrake=true
    HandbrakeThresh=200.0
    StopThreshold=100.0
    MaxBrakeTorque=20.0

    // Physics wheels properties
    WheelSoftness=0.025
    WheelPenScale=2.0
    WheelPenOffset=0.01
    WheelRestitution=0.1
    WheelInertia=0.1
    WheelLongFrictionFunc=(Points=(,(InVal=100.0,OutVal=1.0),(InVal=200.0,OutVal=0.9),(InVal=10000000000.0,OutVal=0.9)))
    WheelLongSlip=0.001
    WheelLatSlipFunc=(Points=((InVal=0.0,OutVal=0.0),(InVal=30.0,OutVal=0.009),(InVal=10000000000.0,OutVal=0.00)))
    WheelLongFrictionScale=1.5
    WheelLatFrictionScale=3.0
    WheelHandbrakeSlip=0.01
    WheelHandbrakeFriction=0.1
    WheelSuspensionTravel=15.0
    WheelSuspensionMaxRenderTravel=15.0

    // Karma properties
    Begin Object Class=KarmaParamsRBFull Name=KParams0
        KInertiaTensor(0)=1.0
        KInertiaTensor(3)=3.0
        KInertiaTensor(5)=3.0
        KCOMOffset=(X=0.0,Y=0.0,Z=-0.5)
        KLinearDamping=0.05
        KAngularDamping=0.05
        KStartEnabled=true
        bKNonSphericalInertia=true
        bHighDetailOnly=false
        bClientOnly=false
        bKDoubleTickRate=true
        bDestroyOnWorldPenetrate=true
        bDoSafetime=true
        KFriction=0.5
        KImpactThreshold=700.0
        KMaxAngularSpeed=1.0 // slow down the angular velocity so the tank feels "heavier"
    End Object
    KParams=KarmaParamsRBFull'DH_Engine.DHArmoredVehicle.KParams0'
}
