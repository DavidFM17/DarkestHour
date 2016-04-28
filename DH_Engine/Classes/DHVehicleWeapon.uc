//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHVehicleWeapon extends ROVehicleWeapon
    abstract;

// General
var     ROVehicleWeaponPawn WeaponPawn;         // convenient reference to VehicleWeaponPawn actor // TODO: change type to DHVehicleWeaponPawn when that becomes the parent class
var     vector              WeaponAttachOffset; // optional positional offset when attaching VehicleWeapon to the hull
var     bool                bUsesMags;          // main weapon uses magazines or similar (e.g. ammo belts), not single shot shells

// Clientside flags to do certain things when certain actors are received, to fix problems caused by replication timing issues
var     bool           bInitializedVehicleBase;          // done set up after receiving the (vehicle) Base actor
var     bool           bInitializedVehicleAndWeaponPawn; // done set up after receiving both the (vehicle) Base & VehicleWeaponPawn actors

// Reloading
struct  ReloadStage
{
var     sound   Sound;
var     float   Duration;
};

enum    EReloadState
{
    RL_Empty,
    RL_ReloadedPart1,
    RL_ReloadedPart2,
    RL_ReloadedPart3,
    RL_ReloadedPart4,
    RL_ReadyToFire,
    RL_Waiting, // put waiting at end as ReloadStages array then matches ReloadState numbering, & also "ReloadState < RL_ReadyToFire" conveniently signifies weapon is reloading
};

var     bool                bMultiStageReload;    // this weapon uses a multi-stage reload process, that can be paused & resumed
var     EReloadState        ReloadState;          // the stage of weapon reload or readiness
var     array<ReloadStage>  ReloadStages;         // stages for multi-part reload, with sounds and/ or durations (servers often use stripped sound files without actual sounds, breaking reload)
var     bool                bReloadPaused;        // a reload has started but was paused, as no longer had a player in a valid reloading position

// MG weapon (hull mounted or coaxial)
const   ALT_FIREMODE_INDEX = 3;                    // FireMode index for alt fire
var     byte                NumMGMags;             // number of mags/belts for an MG (using byte for more efficient replication)
var     class<Projectile>   TracerProjectileClass; // replaces DummyTracerClass as tracer is now a real bullet that damages, not just a client-only effect, so old name was misleading
var     byte                TracerFrequency;       // how often a tracer is loaded in, as in 1 in X (deprecates mTracerInterval & mLastTracerTime)
var     sound               NoMGAmmoSound;         // 'dry fire' sound when trying to fire empty MG
var     name                HUDOverlayReloadAnim;  // reload animation to play if the MG uses a HUDOverlay

// Turret/MG collision static mesh
// Matt: new col mesh actor allows us to use a col static mesh with VehicleWeapon - just specify a valid CollisionStaticMesh in default props & col static mesh is automatically used
var     DHCollisionMeshActor    CollisionMeshActor;
var     StaticMesh              CollisionStaticMesh;

// Hatch fire effects - Ch!cKeN
var     VehicleDamagedEffect        HatchFireEffect;
var     class<VehicleDamagedEffect> FireEffectClass;
var     name                        FireAttachBone;
var     vector                      FireEffectOffset;
var     float                       FireEffectScale;

replication
{
    // Variables the server will replicate to the client that owns this actor
    reliable if (bNetOwner && bNetDirty && Role == ROLE_Authority)
        NumMGMags;

    // Functions the server can call on the client that owns this actor
    reliable if (Role == ROLE_Authority)
        ClientSetReloadState;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************* ACTOR INITIALISATION & KEY ENGINE EVENTS ******************* //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to attach new collision static mesh actor, if one has been specified
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (CollisionStaticMesh != none)
    {
        CollisionMeshActor = class'DHCollisionMeshActor'.static.AttachCollisionMesh(self, CollisionStaticMesh, YawBone); // attach to yaw bone, so col mesh turns with weapon

        if (CollisionMeshActor != none)
        {
            // Remove all collision from this VehicleWeapon class (instead let col mesh actor handle collision detection)
            SetCollision(false, false); // bCollideActors & bBlockActors both false
            bBlockZeroExtentTraces = false;
            bBlockNonZeroExtentTraces = false;
            bBlockHitPointTraces = false;
            bProjTarget = false;
        }
    }
}

// No longer use Tick, as hatch fire effects & manual/powered turret are now triggered on net client from Vehicle's PostNetReceive()
// Let's disable Tick altogether to save unnecessary processing
simulated function Tick(float DeltaTime)
{
    Disable('Tick');
}

// Matt: modified to call set up functionality that requires the Vehicle actor (just after vehicle spawns via replication)
// This controls common and sometimes critical problems caused by unpredictability of when & in which order a net client receives replicated actor references
// Functionality is moved to series of InitializeX functions, for clarity & to allow easy subclassing for anything that is vehicle-specific
simulated function PostNetReceive()
{
    // Initialize anything we need to do from the Vehicle actor, or in that actor
    if (!bInitializedVehicleBase)
    {
        if (Base != none)
        {
            bInitializedVehicleBase = true;
            InitializeVehicleBase();
        }
    }
    // Fail-safe so if we somehow lose our Base reference after initializing, we unset our flags & are then ready to re-initialize when we receive Base again
    else if (Base == none)
    {
        bInitializedVehicleBase = false;
        bInitializedVehicleAndWeaponPawn = false;
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *********************************** FIRING ************************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle DH's extended ammo system & re-factored to reduce lots of code repetition & make some functionality improvement
event bool AttemptFire(Controller C, bool bAltFire)
{
    local byte  FireMode;
    local float ProjectileSpread;

    if (Role < ROLE_Authority)
    {
        return false;
    }

    // Exit if trying to fire a mag-fed auto weapon before it's time for the next shot
    if (FireCountdown > 0.0 && (bAltFire || bUsesMags))
    {
        return false;
    }

    // Stop firing if weapon not ready to fire , or if player has moved to ineligible firing position while holding down fire button
//  if (!ReadyToFire(bAltFire) || (WeaponPawn != none && !WeaponPawn.CanFire())) // TODO: revert to this 'if' when DHVehicleWeaponPawn implemented, replacing messy 'if' below
    if (!ReadyToFire(bAltFire)
        || (DHVehicleCannonPawn(WeaponPawn) != none && !DHVehicleCannonPawn(WeaponPawn).CanFire())
        || (DHVehicleMGPawn(WeaponPawn) != none && !DHVehicleMGPawn(WeaponPawn).CanFire()))
    {
         if (WeaponPawn != none)
         {
             WeaponPawn.VehicleCeaseFire(bAltFire);
         }

         return false;
    }

    // Calculate the starting WeaponFireRotation & apply any random spread
    CalcWeaponFire(bAltFire);

    if (bCorrectAim)
    {
        WeaponFireRotation = AdjustAim(bAltFire);
    }

    if (class<DHCannonShellCanister>(ProjectileClass) == none || bAltFire) // no spread for canister shot, as it gets calculated for each separate projectile
    {
        ProjectileSpread = GetSpread(bAltFire);

        if (ProjectileSpread > 0.0)
        {
            WeaponFireRotation = rotator(vector(WeaponFireRotation) + VRand() * FRand() * ProjectileSpread);
        }
    }

    // Decrement our round count (note we've already done a 'have ammo' check in the earlier ReadyToFire() test, so we don't need to check that ConsumeAmmo() returns true)
    FireMode = GetFireMode(bAltFire);
    ConsumeAmmo(FireMode);

    // Coaxial MG fire
    if (bAltFire)
    {
        AltFire(C);
        FireCountdown = AltFireInterval;
    }
    // Main weapon fire
    else
    {
        Fire(C);

        if (bUsesMags)
        {
            FireCountdown = FireInterval;
        }
    }

    if (WeaponPawn != none)
    {
        WeaponPawn.MakeNoise(1.0);
    }

    // Cease fire & try to start a reload, if weapon doesn't use mags or just fired the last round in a mag
    if ((!bAltFire && !bUsesMags) || !HasAmmo(FireMode))
    {
        if (WeaponPawn != none)
        {
            WeaponPawn.VehicleCeaseFire(bAltFire);
        }

        if (bAltFire)
        {
            AttemptAltReload();
        }
        else if (PlayerUsesManualReloading() && bMultiStageReload)
        {
            ReloadState = RL_Waiting; // player reloads manually, so just wait for key press
            ClientSetReloadState(ReloadState);
        }
        else
        {
            AttemptReload();
        }
    }

    return true;
}

// Modified to spawn either normal bullet OR tracer, based on proper shot count, not simply time elapsed since last shot
// Modulo operator (%) divides rounds previously fired by tracer frequency & returns the remainder - if it divides evenly (result = 0) then it's time to fire a tracer
state ProjectileFireMode
{
    function Fire(Controller C)
    {
        if (bUsesTracers && !bAltFireTracersOnly && ((InitialPrimaryAmmo - PrimaryAmmoCount() - 1) % TracerFrequency == 0.0) && TracerProjectileClass != none)
        {
            SpawnProjectile(TracerProjectileClass, false);
        }
        else if (ProjectileClass != none)
        {
            SpawnProjectile(ProjectileClass, false);
        }
    }

    function AltFire(Controller C)
    {
        if (bUsesTracers && ((InitialAltAmmo - AltAmmoCharge - 1) % TracerFrequency == 0.0) && TracerProjectileClass != none)
        {
            SpawnProjectile(TracerProjectileClass, true);
        }
        else if (AltFireProjectileClass != none)
        {
            SpawnProjectile(AltFireProjectileClass, true);
        }
    }
}

// Modified to prevent single shot cannon from firing unless loaded, instead of using generic FireCountdown check (adapted from ROTankCannon)
simulated function ClientStartFire(Controller C, bool bAltFire)
{
    if (bMultiStageReload && ReloadState != RL_ReadyToFire && !bAltFire) // cannon or hull MG can't fire unless loaded
    {
        return;
    }

    if (FireCountdown > 0.0 && (bUsesMags || bAltFire)) // coaxial MG or autocannon can't fire unless fire interval has elapsed between shots
    {
        return;
    }

    bIsAltFire = bAltFire;

    if (bIsRepeatingFF)
    {
        if (bIsAltFire)
        {
            ClientPlayForceFeedback(AltFireForce);
        }
        else
        {
            ClientPlayForceFeedback(FireForce);
        }
    }

    OwnerEffects();
}

// Modified to add generic support for weapons that use magazines or similar, to add generic support for different fire sounds,
// to stop 'phantom' coaxial firing effects (flash & tracers) from continuing if player has moved to ineligible firing position while holding down fire button,
// and to enable MG muzzle flash when hosting a listen server, which the original code misses out
simulated function OwnerEffects()
{
    if (Role < ROLE_Authority)
    {
        // Stop the firing effects if shouldn't be able to fire, or if player moves to ineligible firing position while holding down fire button
//      if (!ReadyToFire(bIsAltFire) || (WeaponPawn != none && !WeaponPawn.CanFire())) // TODO: revert to this 'if' when DHVehicleWeaponPawn implemented, replacing messy 'if' below
        if (!ReadyToFire(bIsAltFire)
            || (DHVehicleCannonPawn(WeaponPawn) != none && !DHVehicleCannonPawn(WeaponPawn).CanFire())
            || (DHVehicleMGPawn(WeaponPawn) != none && !DHVehicleMGPawn(WeaponPawn).CanFire()))
        {
            if (WeaponPawn != none)
            {
                ClientOnlyVehicleCeaseFire(bIsAltFire);
            }

            return;
        }

        // Coaxial MG
        if (bIsAltFire)
        {
            SoundVolume = AltFireSoundVolume; // bAmbientAltFireSound is now assumed
            SoundRadius = AltFireSoundRadius;
            AmbientSoundScaling = AltFireSoundScaling;

            FireCountdown = AltFireInterval;
        }
        // Main weapon
        else
        {
            if (!bAmbientFireSound)
            {
                PlaySound(GetFireSound(), SLOT_None, FireSoundVolume / 255.0,, FireSoundRadius,, false);
            }

            if (bUsesMags)
            {
                FireCountdown = FireInterval;
            }
            // Cease fire after firing a non-automatic weapon, i.e. a normal cannon, not an autocannon or MG
            else
            {
                if (WeaponPawn != none)
                {
                    ClientOnlyVehicleCeaseFire(bIsAltFire);
                }

                // Server will begin a reload & replicate that to net client (providing we have some ammo), but there's a slight replication delay
                // So we'll set client to state waiting, otherwise player can press fire again very quickly & get repeat phantom firing effects
                if (ReloadState == RL_ReadyToFire && bMultiStageReload)
                {
                    ReloadState = RL_Waiting;
                }
            }
        }

        FlashMuzzleFlash(bIsAltFire);
    }

    if (Level.NetMode != NM_DedicatedServer) // added this check as effects have no relevance on server
    {
        ShakeView(bIsAltFire);

        if ((bIsAltFire || !bAmbientEmitterAltFireOnly) && AmbientEffectEmitter != none)
        {
            AmbientEffectEmitter.SetEmitterStatus(true); // consolidated here instead of having it in 3 places for 3 net modes (listen server now included, so fixes bug)
        }

        if (!bIsRepeatingFF)
        {
            if (bIsAltFire)
            {
                ClientPlayForceFeedback(AltFireForce);
            }
            else
            {
                ClientPlayForceFeedback(FireForce);
            }
        }
    }
}

// Modified to remove the Super in ROVehicleWeapon to remove calling UpdateTracer, now we spawn either a normal bullet OR tracer (see ProjectileFireMode)
simulated function FlashMuzzleFlash(bool bWasAltFire)
{
    super(VehicleWeapon).FlashMuzzleFlash(bWasAltFire);
}

// New function to play the main weapon firing sound (allows easy subclassing)
simulated function sound GetFireSound()
{
    return FireSoundClass;
}

// TEMP function to handle ClientOnlyVehicleCeaseFire() being in different classes, until DHVehicleWeaponPawn is implemented
// TODO: change all calls to this function in VehicleWeapon classes to WeaponPawn.ClientOnlyVehicleCeaseFire
simulated function ClientOnlyVehicleCeaseFire(bool bWasAltFire)
{
    if (DHVehicleCannonPawn(WeaponPawn) != none)
    {
        DHVehicleCannonPawn(WeaponPawn).ClientOnlyVehicleCeaseFire(bWasAltFire);
    }
    else if (DHVehicleMGPawn(WeaponPawn) != none)
    {
        DHVehicleMGPawn(WeaponPawn).ClientOnlyVehicleCeaseFire(bWasAltFire);
    }
    else if (WeaponPawn != none)
    {
        WeaponPawn.ClientVehicleCeaseFire(bWasAltFire);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ****************************** AMMO & RELOADING *******************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to include MG mags/belts
function bool GiveInitialAmmo()
{
    if (MainAmmoCharge[0] != InitialPrimaryAmmo || MainAmmoCharge[1] != InitialSecondaryAmmo || AltAmmoCharge != InitialAltAmmo || NumMGMags != default.NumMGMags)
    {
        MainAmmoCharge[0] = InitialPrimaryAmmo;
        MainAmmoCharge[1] = InitialSecondaryAmmo;
        AltAmmoCharge = InitialAltAmmo;
        NumMGMags = default.NumMGMags;

        return true;
    }

    return false;
}

// Modified to prevent main weapon fire if not loaded
simulated function bool ReadyToFire(bool bAltFire)
{
    if (!bAltFire && bMultiStageReload && ReloadState != RL_ReadyToFire) // cannon or hull MG can't fire unless loaded
    {
        return false;
    }

    return HasAmmo(GetFireMode(bAltFire));
}

// New functions to start a reload process - implement functionality in subclasses
simulated function AttemptReload()
{
}

simulated function AttemptAltReload()
{
}

// Modified (from ROTankCannon) so only sets timer if new reload state needs it, & to only act on net client (avoids duplication for standalone or listen server)
simulated function ClientSetReloadState(EReloadState NewState)
{
    if (Role < ROLE_Authority)
    {
        ReloadState = NewState;

        // If reload is in progress, make sure reload it isn't paused & start a reload timer
        if (ReloadState < RL_ReadyToFire)
        {
            bReloadPaused = false;
            SetTimer(0.01, false);
        }
    }
}

// New helper function to check if player uses manual reloading, just saving code repetition elsewhere - implement in subclass
simulated function bool PlayerUsesManualReloading()
{
    return false;
}

// New function to get numeric fire mode from currently selected projectile class
simulated function byte GetFireMode(optional bool bAltFire, optional class<Projectile> ProjClass)
{
    if (bAltFire)
    {
        return ALT_FIREMODE_INDEX;
    }

    if (ProjClass == none)
    {
        ProjClass = ProjectileClass;
    }

    if (ProjClass == PrimaryProjectileClass || !bMultipleRoundTypes)
    {
        return 0;
    }
    else if (ProjClass == SecondaryProjectileClass)
    {
        return 1;
    }

    return 255;
}

// Modified to handle MG magazines
simulated function int GetNumMags()
{
    return NumMGMags;
}

// New helper function to return appropriate projectile spread for ammo type (just makes subclassing easier)
function float GetSpread(bool bAltFire)
{
    if (bAltFire)
    {
        return AltFireSpread;
    }

    return Spread;
}

///////////////////////////////////////////////////////////////////////////////////////
//  **************************  HIT DETECTION & DAMAGE  ***************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Matt: emptied out as suicide stuff is irrelevant & never called here, & because as shell & bullet's ProcessTouch now call TakeDamage directly on 'Driver' if he was hit
// Note that shell's ProcessTouch also now calls TakeDamage on VehicleWeapon instead of Vehicle itself, so this function decides what to do with that damage
// Add here if want to pass damage on to vehicle (& if DamageType is bDelayedDamage, need to call SetDelayedDamageInstigatorController(InstigatedBy.Controller) on relevant pawn)
// Can also add any desired functionality in subclasses, e.g. a shell impact could wreck an exposed MG
function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
}

// Deprecated functions - return false just in case they get called
simulated function bool HitDriverArea(vector HitLocation, vector Momentum)
{
    return false;
}

simulated function bool HitDriver(vector HitLocation, vector Momentum)
{
    return false;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************  SETUP, UPDATE, CLEAN UP, MISCELLANEOUS  *******************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to include Skins array (so no need to add manually in each subclass) & to add extra material properties (note the Supers are empty)
static function StaticPrecache(LevelInfo L)
{
    local int i;

    for (i = 0; i < default.Skins.Length; ++i)
    {
        if (default.Skins[i] != none)
        {
            L.AddPrecacheMaterial(default.Skins[i]);
        }
    }

    if (default.HudAltAmmoIcon != none)
    {
        L.AddPrecacheMaterial(default.HudAltAmmoIcon);
    }

    if (default.HighDetailOverlay != none)
    {
        L.AddPrecacheMaterial(default.HighDetailOverlay);
    }
}

// Modified to add extra material properties (note the Super in Actor already pre-caches the Skins array)
simulated function UpdatePrecacheMaterials()
{
    super.UpdatePrecacheMaterials();

    if (HudAltAmmoIcon != none)
    {
        Level.AddPrecacheMaterial(HudAltAmmoIcon);
    }

    if (HighDetailOverlay != none)
    {
        Level.AddPrecacheMaterial(HighDetailOverlay);
    }
}

// Modified to add projectile classes
simulated function UpdatePrecacheStaticMeshes()
{
    super.UpdatePrecacheStaticMeshes();

    if (PrimaryProjectileClass != none)
    {
        Level.AddPrecacheStaticMesh(PrimaryProjectileClass.default.StaticMesh);
    }

    if (SecondaryProjectileClass != none)
    {
        Level.AddPrecacheStaticMesh(SecondaryProjectileClass.default.StaticMesh);
    }
}

// Matt: New function to do set up that requires the 'Gun' reference to the VehicleWeaponPawn actor (called from VehicleWeaponPawn when it receives a reference to this actor)
// Using it to set a convenient WeaponPawn reference & our Owner & Instigator variables
simulated function InitializeWeaponPawn(ROVehicleWeaponPawn WeaponPwn) // TODO: change type to DHVehicleWeaponPawn when that is implemented (also change in subclasses)
{
    if (WeaponPwn != none)
    {
        WeaponPawn = WeaponPwn;

        if (Role < ROLE_Authority)
        {
            SetOwner(WeaponPawn);
            Instigator = WeaponPawn;
        }

        // If we also have the Vehicle, initialize anything we need to do where we need both actors
        if (Base != none && !bInitializedVehicleAndWeaponPawn)
        {
            InitializeVehicleAndWeaponPawn();
        }
    }
    else
    {
        Warn("ERROR:" @ Tag @ "somehow spawned without an owning DHVehicleWeaponPawn, so lots of things are not going to work!");
    }
}

// New function to do set up that requires the 'Base' reference to the Vehicle actor we are attached to
// Using it to add option to reposition VehicleWeapon attachment, & to start a hatch fire if armoured vehicle is burning when replicated.
simulated function InitializeVehicleBase()
{
    // Set any optional attachment offset, when attaching weapon to hull (set separately on net client as replication is unreliable & loses fractional precision)
    if (WeaponAttachOffset != vect(0.0, 0.0, 0.0))
    {
        SetRelativeLocation(WeaponAttachOffset);
    }

    // If vehicle is burning, start the hatch fire effect
    if (DHArmoredVehicle(Base) != none && DHArmoredVehicle(Base).bOnFire)
    {
        StartHatchFire();
    }

    // If we also have the VehicleWeaponPawn actor, initialize anything we need to do where we need both actors
    if (WeaponPawn != none && !bInitializedVehicleAndWeaponPawn)
    {
        InitializeVehicleAndWeaponPawn();
    }
}

// New function to do any set up that requires both the 'Base' & 'WeaponPawn' references to the Vehicle & VehicleWeaponPawn actors
// Currently unused but putting it in for consistency & for future usage, including option to easily subclass for any vehicle-specific set up
simulated function InitializeVehicleAndWeaponPawn()
{
    bInitializedVehicleAndWeaponPawn = true;
}

// Modified to always use rotation relative to vehicle (bPCRelativeFPRotation), to use yaw limits from DriverPositions in multi position weapon, & not to limit view yaw in behind view
// Also to ignore yaw restrictions for commander's periscope or binoculars positions (where bLimitYaw is true, e.g. casemate-style tank destroyers) - but see note below
simulated function int LimitYaw(int yaw)
{
    local int CurrentPosition;

    // TODO: Matt - this is confusing 2 different things: limit on weapon's yaw & limit on player's view yaw
    // bLimitYaw is used by native code to limit (or not) weapon's turning, which ignores anything that happens in this function
    // This function is best thought of as LimitViewYaw() & would be better placed in the cannon pawn class (but needs to stay as is because it is called by UpdateRotation() in PC class)
    // bLimitYaw should not be used here - the view yaw limits should be based on ViewNegativeYawLimit & ViewPositiveYawLimit in DriverPositions
    if (!bLimitYaw)
    {
        return yaw;
    }

    if (WeaponPawn != none)
    {
        if (WeaponPawn.IsHumanControlled() && PlayerController(WeaponPawn.Controller).bBehindView)
        {
            return yaw;
        }

        if (WeaponPawn.DriverPositions.Length > 0)
        {
            CurrentPosition = WeaponPawn.DriverPositionIndex;

            if (WeaponPawn.IsA('DHVehicleCannonPawn') && CurrentPosition >= DHVehicleCannonPawn(WeaponPawn).PeriscopePositionIndex)
            {
                return yaw;
            }

            return Clamp(yaw, WeaponPawn.DriverPositions[CurrentPosition].ViewNegativeYawLimit, WeaponPawn.DriverPositions[CurrentPosition].ViewPositiveYawLimit);
        }
    }

    return Clamp(yaw, MaxNegativeYaw, MaxPositiveYaw);
}

// New function to start a hatch fire effect - all fires now triggered from vehicle base, so don't need cannon's Tick() constantly checking for a fire
simulated function StartHatchFire()
{
    if (HatchFireEffect == none && Level.NetMode != NM_DedicatedServer)
    {
        HatchFireEffect = Spawn(FireEffectClass);
    }

    if (HatchFireEffect != none)
    {
        AttachToBone(HatchFireEffect, FireAttachBone);
        HatchFireEffect.SetRelativeLocation(FireEffectOffset);
        HatchFireEffect.UpdateDamagedEffect(true, 0.0, false, false);

        if (FireEffectScale != 1.0)
        {
            HatchFireEffect.SetEffectScale(FireEffectScale);
        }
    }
}

// Modified to fix UT2004 bug affecting non-owning net players in any vehicle with bPCRelativeFPRotation (nearly all), often causing firing effects to be skipped
// Vehicle's rotation was not being factored into calcs using the PlayerController's rotation, which effectively randomised the result of this function
// Also re-factored to make it a little more optimised, direct & easy to follow (without repeated use of bResult)
simulated function bool EffectIsRelevant(vector SpawnLocation, bool bForceDedicated)
{
    local PlayerController PC;

    // Only relevant on a dedicated server if the bForceDedicated option has been passed
    if (Level.NetMode == NM_DedicatedServer)
    {
        return bForceDedicated;
    }

    // Net clients
    if (Role < ROLE_Authority)
    {
        // Always relevant for the owning net player
        if (Instigator != none && Instigator.IsHumanControlled())
        {
            return true;
        }

        // Not relevant for other net clients if cannon has not been drawn on their screen recently
        if (SpawnLocation == Location)
        {
            if ((Level.TimeSeconds - LastRenderTime) >= 3.0)
            {
                return false;
            }
        }
        else if (Instigator == none || (Level.TimeSeconds - Instigator.LastRenderTime) >= 3.0)
        {
            return false;
        }
    }

    PC = Level.GetLocalPlayerController();

    if (PC == none || PC.ViewTarget == none)
    {
        return false;
    }

    // Check to see whether effect would spawn off to the side or behind where player is facing, & if so then only spawn if within quite close distance
    // Using PC's CalcViewRotation, which is the last recorded camera rotation, so a simple way of getting player's non-relative view rotation, even in vehicles
    // (doesn't apply to the player in the cannon)
    if (PC.Pawn != Instigator && vector(PC.CalcViewRotation) dot (SpawnLocation - PC.ViewTarget.Location) < 0.0)
    {
        return VSizeSquared(PC.ViewTarget.Location - SpawnLocation) < 2560000.0; // equivalent to 1600 UU or 26.5m (changed to VSizeSquared as more efficient)
    }

    // Effect relevance is based on normal distance check
    return CheckMaxEffectDistance(PC, SpawnLocation);
}

// Modified to add extra stuff
simulated function DestroyEffects()
{
    super.DestroyEffects();

    if (CollisionMeshActor != none)
    {
        CollisionMeshActor.Destroy(); // not actually an effect, but convenient to add here
    }

    if (HatchFireEffect != none)
    {
        HatchFireEffect.Kill();
    }
}

defaultproperties
{
    bNetNotify=true // necessary to do set up requiring the 'Base' actor reference to the vehicle base
    bMultiStageReload=true
    ReloadState=RL_ReadyToFire
    NoMGAmmoSound=sound'Inf_Weapons_Foley.Misc.dryfire_rifle'
    PitchUpLimit=15000
    PitchDownLimit=45000
    FireEffectClass=class'ROEngine.VehicleDamagedEffect'
    FireEffectScale=1.0
    AIInfo(0)=(bLeadTarget=true,WarnTargetPct=0.9)

    // These variables are effectively deprecated & should not be used - they are either ignored or values below are assumed & may be hard coded into functionality:
    FireIntervalAimLock=0.0 // also means AimLockReleaseTime is deprecated
    bShowAimCrosshair=false
}