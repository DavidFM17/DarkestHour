//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHVehicleCannonPawn extends DHVehicleWeaponPawn
    abstract;

// Player view positions
var     int         GunsightPositions;           // the number of gunsight positions - 1 for normal optics or 2 for dual-magnification optics
var     int         PeriscopePositionIndex;      // index position of commander's periscope
var     int         IntermediatePositionIndex;   // optional 'intermediate' animation position, i.e. between closed & open/raised positions (used to play special firing anim)
var     int         RaisedPositionIndex;         // lowest position where commander is raised up (unbuttoned in enclosed turret, or standing in open turret or on AT gun)

// Camera & display
var     name        PlayerCameraBone;            // just to avoid using literal references to 'Camera_com' bone & allow extra flexibility
var     bool        bCamOffsetRelToGunPitch;     // camera position offset (ViewLocation) is always relative to cannon's pitch, e.g. for open sights in some AT guns
var     bool        bLockCameraDuringTransition; // lock the camera's rotation to the camera bone during transitions
var     texture     PeriscopeOverlay;            // overlay for commander's periscope
var     texture     AltAmmoReloadTexture;        // used to show coaxial MG reload progress on the HUD, like the cannon reload

// Gunsight overlay
var     texture     CannonScopeCenter;           // gunsight reticle overlay (really only for sights with moving range indicator, but some DH sights use as pretty pointless 2nd sight overlay)
var     bool        bShowRangeText;              // show current range setting text
var localized string    RangeText;               // metres or yards (can be localised for other languages)
var     float       RangePositionX;              // adjusts positioning of range text
var     float       RangePositionY;
var     bool        bShowRangeRing;              // show range ring (used in German tank sights)
var     TexRotator  RangeRingRotator;            // overlay for range ring (renamed from RO's ScopeCenterRotator)
var     int         RangeRingRotationFactor;     // scales the rotation of the range ring, so it correctly aligns the range markings (renamed from RO's CenterRotationFactor)
var     float       RangeRingScale;              // scale of the range ring (renamed from RO's ScopeCenterScale)

// Manual & powered turret movement
var     bool        bManualTraverseOnly;
var     sound       ManualRotateSound;
var     sound       ManualPitchSound;
var     sound       ManualRotateAndPitchSound;
var     sound       PoweredRotateSound;
var     sound       PoweredPitchSound;
var     sound       PoweredRotateAndPitchSound;
var     float       ManualMinRotateThreshold;
var     float       ManualMaxRotateThreshold;
var     float       PoweredMinRotateThreshold;
var     float       PoweredMaxRotateThreshold;

// Damage
var     bool        bTurretRingDamaged;
var     bool        bGunPivotDamaged;
var     bool        bOpticsDamaged;
var     texture     DestroyedGunsightOverlay;

// Debug
var     bool        bDebugSights; // shows centering cross in gunsight for testing purposes

replication
{
    // Variables the server will replicate to all clients
    reliable if (bNetDirty && Role == ROLE_Authority)
        bTurretRingDamaged, bGunPivotDamaged;

    // Functions the server can call on the client that owns this actor
    reliable if (Role == ROLE_Authority)
        ClientDamageCannonOverlay;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ********************** ACTOR INITIALISATION & DESTRUCTION  ********************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to match RaisedPositionIndex to UnbuttonedPositionIndex by default
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (RaisedPositionIndex == -1) // default value -1 signifies match to UPI, just to save having to set it in most vehicles (set RPI in vehicle subclass def props if different)
    {
        RaisedPositionIndex = UnbuttonedPositionIndex;
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  VIEW/DISPLAY  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified so player's view turns with a turret, to properly handle vehicle roll, to handle dual-magnification optics,
// to handle FPCamPos camera offset for any position (not just overlays), & to optimise & simplify generally
simulated function SpecialCalcFirstPersonView(PlayerController PC, out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local quat    RelativeQuat, VehicleQuat, NonRelativeQuat;
    local rotator BaseRotation;
    local bool    bOnGunsight;

    ViewActor = self;

    if (PC == none || VehWep == none)
    {
        return;
    }

    // If player is on gunsight, use CameraBone for camera location & use cannon's aim for camera rotation
    if (DriverPositionIndex < GunsightPositions && !IsInState('ViewTransition') && CameraBone !='') // GunsightPositions may be 2 for dual-magnification optics
    {
        bOnGunsight = true;
        CameraLocation = VehWep.GetBoneCoords(CameraBone).Origin;
        CameraRotation = VehWep.GetBoneRotation(CameraBone);
    }
    // Otherwise use PlayerCameraBone for camera location & use PC's rotation for camera rotation (unless camera is locked during a transition)
    else
    {
        CameraLocation = VehWep.GetBoneCoords(PlayerCameraBone).Origin;

        // If camera is locked during a current transition, lock rotation to PlayerCameraBone
        if (bLockCameraDuringTransition && IsInState('ViewTransition'))
        {
            CameraRotation = VehWep.GetBoneRotation(PlayerCameraBone);
        }
        // Otherwise, player can look around, e.g. cupola, periscope, unbuttoned or binoculars
        else
        {
            CameraRotation = PC.Rotation;

            // If vehicle has a turret, add turret's yaw to player's relative rotation, so player's view turns with the turret
            if (VehWep != none && VehWep.bHasTurret)
            {
                CameraRotation.Yaw += VehWep.CurrentAim.Yaw;
            }

            // Now factor in the vehicle's rotation
            RelativeQuat = QuatFromRotator(Normalize(CameraRotation));
            VehicleQuat = QuatFromRotator(VehWep.Rotation); // note VehWep.Rotation is same as vehicle base
            NonRelativeQuat = QuatProduct(RelativeQuat, VehicleQuat);
            CameraRotation = Normalize(QuatToRotator(NonRelativeQuat));
        }
    }

    // Custom aim update
    if (bOnGunsight)
    {
        PC.WeaponBufferRotation.Yaw = CameraRotation.Yaw;
        PC.WeaponBufferRotation.Pitch = CameraRotation.Pitch;
    }

    // Adjust camera location for any offset positioning (FPCamPos is set from any ViewLocation in DriverPositions)
    if (FPCamPos != vect(0.0, 0.0, 0.0))
    {
        if (bOnGunsight || (bLockCameraDuringTransition && IsInState('ViewTransition')))
        {
            CameraLocation = CameraLocation + (FPCamPos >> CameraRotation);
        }
        // In a 'look around' position, we need to make camera offset relative to the vehicle, not the way the player is facing
        else
        {
            BaseRotation = VehWep.Rotation; // note VehWep.Rotation is same as vehicle base

            if (VehWep != none && VehWep.bHasTurret)
            {
                BaseRotation.Yaw += VehWep.CurrentAim.Yaw;

                if (bCamOffsetRelToGunPitch)
                {
                    BaseRotation.Pitch += VehWep.CurrentAim.Pitch;
                }
            }

            CameraLocation = CameraLocation + (FPCamPos >> BaseRotation);
        }
    }

    // Finalise the camera with any shake
    CameraLocation = CameraLocation + (PC.ShakeOffset >> PC.Rotation);
    CameraRotation = Normalize(CameraRotation + PC.ShakeRot);
}

// Modified to fix bug where any HUDOverlay would be destroyed if function called before net client received Controller reference through replication
// Also to remove irrelevant stuff about crosshair & to optimise
simulated function DrawHUD(Canvas C)
{
    local PlayerController PC;
    local float            SavedOpacity, PosX, PosY, ScreenRatio, XL, YL, MapX, MapY;
    local int              RotationFactor;
    local color            SavedColor, WhiteColor;

    PC = PlayerController(Controller);

    if (PC != none && !PC.bBehindView)
    {
        // Player is in a position where an overlay should be drawn
        if (DriverPositions[DriverPositionIndex].bDrawOverlays && (!IsInState('ViewTransition') || DriverPositions[LastPositionIndex].bDrawOverlays))
        {
            if (HUDOverlay == none)
            {
                // Save current HUD opacity & then set up for drawing overlays
                SavedOpacity = C.ColorModulate.W;
                C.ColorModulate.W = 1.0;
                C.DrawColor.A = 255;
                C.Style = ERenderStyle.STY_Alpha;

                // Draw gunsights
                if (DriverPositionIndex < GunsightPositions)
                {
                    // Debug - draw cross on the center of the screen
                    if (bDebugSights)
                    {
                        PosX = C.SizeX / 2.0;
                        PosY = C.SizeY / 2.0;
                        C.SetPos(0.0, 0.0);
                        C.DrawVertical(PosX - 1.0, PosY - 3.0);
                        C.DrawVertical(PosX, PosY - 3.0);
                        C.SetPos(0.0, PosY + 3.0);
                        C.DrawVertical(PosX - 1.0, PosY - 3.0);
                        C.DrawVertical(PosX, PosY - 3.0);
                        C.SetPos(0.0, 0.0);
                        C.DrawHorizontal(PosY - 1.0, PosX - 3.0);
                        C.DrawHorizontal(PosY, PosX - 3.0);
                        C.SetPos(PosX + 3.0, 0.0);
                        C.DrawHorizontal(PosY - 1.0, PosX - 3.0);
                        C.DrawHorizontal(PosY, PosX - 3.0);
                    }

                    // Draw the gunsight overlay
                    if (GunsightOverlay != none)
                    {
                        ScreenRatio = float(C.SizeY) / float(C.SizeX);
                        C.SetPos(0.0, 0.0);

                        C.DrawTile(GunsightOverlay, C.SizeX, C.SizeY, OverlayCenterTexStart - OverlayCorrectionX,
                            OverlayCenterTexStart - OverlayCorrectionY + (1.0 - ScreenRatio) * OverlayCenterTexSize / 2.0, OverlayCenterTexSize, OverlayCenterTexSize * ScreenRatio);
                    }

                    if (Gun != none)
                    {
                        // Draw the gunsight aiming reticle
                        if (CannonScopeCenter != none && Gun.ProjectileClass != none)
                        {
                            // Vertical adjustment of reticle position for cannons with optical (not mechanically linked) range setting, e.g. some Soviet cannons
                            C.SetPos(0.0, Gun.ProjectileClass.static.GetYAdjustForRange(Gun.GetRange()) * C.ClipY);

                            C.DrawTile(CannonScopeCenter, C.SizeX, C.SizeY, OverlayCenterTexStart - OverlayCorrectionX,
                                OverlayCenterTexStart - OverlayCorrectionY + (1.0 - ScreenRatio) * OverlayCenterTexSize / 2.0, OverlayCenterTexSize, OverlayCenterTexSize * ScreenRatio);
                        }

                        // Draw any range ring
                        if (bShowRangeRing)
                        {
                            PosX = (float(C.SizeX) - float(C.SizeY) * 4.0 / OverlayCenterScale / 3.0) / 2.0;
                            PosY = (float(C.SizeY) - float(C.SizeY) * 4.0 / OverlayCenterScale / 3.0) / 2.0;

                            C.SetPos(OverlayCorrectionX + PosX + (C.SizeY * (1.0 - RangeRingScale) * 4.0 / OverlayCenterScale / 3.0 / 2.0),
                                OverlayCorrectionY + C.SizeY * (1.0 - RangeRingScale * 4.0 / OverlayCenterScale / 3.0) / 2.0);

                            if (Gun.CurrentRangeIndex < 20)
                            {
                               RotationFactor = Gun.CurrentRangeIndex * RangeRingRotationFactor;
                            }
                            else
                            {
                               RotationFactor = (RangeRingRotationFactor * 20) + (((Gun.CurrentRangeIndex - 20) * 2) * RangeRingRotationFactor);
                            }

                            RangeRingRotator.Rotation.Yaw = RotationFactor;

                            C.DrawTileScaled(RangeRingRotator, C.SizeY / 512.0 * RangeRingScale * 4.0 / OverlayCenterScale / 3.0, C.SizeY / 512.0 * RangeRingScale * 4.0 / OverlayCenterScale / 3.0);
                        }

                        // Draw any range setting
                        if (bShowRangeText)
                        {
                            C.Style = ERenderStyle.STY_Normal;
                            SavedColor = C.DrawColor;
                            WhiteColor = class'Canvas'.static.MakeColor(255, 255, 255, 175);
                            C.DrawColor = WhiteColor;
                            MapX = RangePositionX * C.ClipX;
                            MapY = RangePositionY * C.ClipY;
                            C.SetPos(MapX, MapY);
                            C.Font = class'ROHUD'.static.GetSmallMenuFont(C);
                            C.StrLen(Gun.GetRange() @ RangeText, XL, YL);
                            C.DrawTextJustified(Gun.GetRange() @ RangeText, 2, MapX, MapY, MapX + XL, MapY + YL);
                            C.DrawColor = SavedColor;
                        }
                    }
                }
                // Draw periscope overlay
                else if (DriverPositionIndex == PeriscopePositionIndex)
                {
                    DrawPeriscopeOverlay(C);
                }
                // Draw binoculars overlay
                else if (DriverPositionIndex == BinocPositionIndex)
                {
                    DrawBinocsOverlay(C);
                }

                C.ColorModulate.W = SavedOpacity; // reset HUD opacity to original value
            }
            // Draw any HUD overlay
            else if (!Level.IsSoftwareRendering())
            {
                HUDOverlay.SetLocation(PC.CalcViewLocation + (HUDOverlayOffset >> PC.CalcViewRotation));
                HUDOverlay.SetRotation(PC.CalcViewRotation);
                C.DrawActor(HUDOverlay, false, false, FClamp(HUDOverlayFOV * (PC.DesiredFOV / PC.DefaultFOV), 1.0, 170.0));
            }
        }

        // Draw vehicle, turret, ammo count, passenger list
        if (ROHud(PC.myHUD) != none && VehicleBase != none)
        {
            ROHud(PC.myHUD).DrawVehicleIcon(C, VehicleBase, self);
        }
    }
}

// New function to draw any textured commander's periscope overlay
simulated function DrawPeriscopeOverlay(Canvas C)
{
    local float ScreenRatio;

    ScreenRatio = float(C.SizeY) / float(C.SizeX);
    C.SetPos(0.0, 0.0);

    C.DrawTile(PeriscopeOverlay, C.SizeX, C.SizeY, 0.0, (1.0 - ScreenRatio) * float(PeriscopeOverlay.VSize) / 2.0,
        PeriscopeOverlay.USize, float(PeriscopeOverlay.VSize) * ScreenRatio);
}

// Modified so player faces forwards if he's on the gunsight when switching to behind view
simulated function POVChanged(PlayerController PC, bool bBehindViewChanged)
{
    if (PC.bBehindView && bBehindViewChanged && DriverPositionIndex < GunsightPositions)
    {
        PlayerFaceForwards();
    }

    super.POVChanged(PC, bBehindViewChanged);
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************* FIRING & AMMO  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified so net client passes any changed pending ammo type to server (optimises network as avoids server update each time player toggles ammo, doing it only when needed)
// Also so fire button triggers a manual cannon reload if players uses the manual reloading option & the cannon is waiting to start reloading
function Fire(optional float F)
{
    if (!CanFire() || ArePlayersWeaponsLocked() || VehWep == none)
    {
        return;
    }

    if (VehWep.ReadyToFire(false))
    {
        if (Role < ROLE_Authority && !VehWep.PlayerUsesManualReloading() && DHVehicleCannon(VehWep) != none) // no update if manual reloading (update on manual reload instead)
        {
            DHVehicleCannon(VehWep).CheckUpdatePendingAmmo();
        }

        super(Vehicle).Fire(F);

        if (IsHumanControlled())
        {
            VehWep.ClientStartFire(Controller, false);
        }
    }
    else
    {
        ROManualReload(); // only actually tries a manual reload if player uses that option (ROML function contains exactly the same checks we'd otherwise duplicate here)
    }
}

// Implemented to handle coaxial MG fire, including dry-fire sound if trying to fire it when empty (but not if actively reloading)
// Checks that player is in a valid firing position & his weapons aren't locked due to spawn killing
function AltFire(optional float F)
{
    if (!bHasAltFire || !CanFire() || ArePlayersWeaponsLocked() || VehWep == none)
    {
        return;
    }

    if (VehWep.ReadyToFire(true))
    {
        VehicleFire(true);
        bWeaponIsAltFiring = true;

        if (!bWeaponIsFiring && IsHumanControlled())
        {
            VehWep.ClientStartFire(Controller, true);
        }
    }
    // Dry fire effect for empty coax, unless it is reloading
    else if (DHVehicleCannon(VehWep) != none && (DHVehicleCannon(VehWep).AltReloadState == RL_Waiting || DHVehicleCannon(VehWep).bAltReloadPaused))
    {
        VehWep.DryFireEffects(true);
    }
}

// Modified to prevent firing while player is on, or transitioning away from, periscope or binoculars
function bool CanFire()
{
    return (DriverPositionIndex != PeriscopePositionIndex && DriverPositionIndex != BinocPositionIndex
        && !(IsInState('ViewTransition') && (LastPositionIndex == PeriscopePositionIndex || LastPositionIndex == BinocPositionIndex)))
        || !IsHumanControlled();
}

// Modified (from deprecated ROTankCannonPawn) to keep ammo changes clientside as a network optimisation (only pass to server when it needs the change, not every key press)
exec function SwitchFireMode()
{
    if (DHVehicleCannon(Gun) != none && Gun.bMultipleRoundTypes)
    {
        DHVehicleCannon(Gun).ToggleRoundType();
    }
}

// Modified to prevent attempting reload if don't have ammo (saves replicated function call to server) & to use reference to DHVehicleCannon instead of deprecated ROTankCannon
// Also for net client to pass any changed pending ammo type to server (optimises network as avoids update to server each time player toggles ammo, doing it only when needed)
simulated exec function ROManualReload()
{
    local DHVehicleCannon Cannon;

    Cannon = DHVehicleCannon(Gun);

    if (Cannon != none && Cannon.ReloadState == RL_Waiting && Cannon.PlayerUsesManualReloading() && Cannon.HasAmmoToReload(Cannon.LocalPendingAmmoIndex))
    {
        if (Role < ROLE_Authority)
        {
            Cannon.CheckUpdatePendingAmmo();
        }

        Cannon.ServerManualReload();
    }
}

// New function, used by HUD to show coaxial MG reload progress, like a cannon reload
function float GetAltAmmoReloadState()
{
    local DHVehicleCannon Cannon;

    Cannon = DHVehicleCannon(Gun);

    if (Cannon != none)
    {
        if (Cannon.AltReloadState == RL_ReadyToFire)
        {
            return 0.0;
        }
        else if (Cannon.AltReloadState == RL_Waiting || Cannon.AltReloadState == RL_Empty)
        {
            return 1.0;
        }

        return Cannon.AltReloadStages[Cannon.AltReloadState - 1].HUDProportion;
    }

    return 0.0;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ************************* ENTRY, CHANGING VIEW & EXIT  ************************* //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to try to start a coaxial MG reload or resume any previously paused reload if MG is not loaded
// And to replicate combined cannon & coax reload states to net client, & also to show any damaged gunsight
function KDriverEnter(Pawn P)
{
    local DHVehicleCannon Cannon;
    local byte            OldReloadState, OldAltReloadState;

    if (bMultiPosition)
    {
        DriverPositionIndex = InitialPositionIndex;
        LastPositionIndex = InitialPositionIndex;
    }

    super(VehicleWeaponPawn).KDriverEnter(P); // skip over the Super in DHVehicleWeaponPawn, as it's re-stated here

    if (VehicleBase != none)
    {
        VehicleBase.ResetTime = Level.TimeSeconds - 1.0; // cancel any CheckReset timer as vehicle now occupied
    }

    Cannon = DHVehicleCannon(Gun);

    if (Cannon != none && Cannon.bMultiStageReload)
    {
        // Save current reload states so we can tell if they are changed by attempted reloading
        OldReloadState = Cannon.ReloadState;
        OldAltReloadState = Cannon.AltReloadState;

        // Try to resume any paused cannon reload, or start a new reload if in waiting state & the player does not use manual reloading
        if (Cannon.ReloadState < RL_ReadyToFire || (Cannon.ReloadState == RL_Waiting && !Cannon.PlayerUsesManualReloading()))
        {
            Cannon.AttemptReload();
        }

        // If coaxial MG isn't loaded then try to start/resume a reload
        if (bHasAltFire && Cannon.AltReloadState != RL_ReadyToFire)
        {
            Cannon.AttemptAltReload();
        }

        // Replicate the weapon's current reload state, unless attempted reloading changed the state, in which case it will have already done this
        if (Cannon.ReloadState == OldReloadState && Cannon.AltReloadState == OldAltReloadState)
        {
            Cannon.PassReloadStateToClient();
        }
    }

    if (BinocPositionIndex >= 0 && BinocPositionIndex < DriverPositions.Length)
    {
        bPlayerHasBinocs = P.FindInventoryType(class<Inventory>(DynamicLoadObject("DH_Equipment.DHBinocularsItem", class'class'))) != none;
    }

    if (bOpticsDamaged)
    {
        ClientDamageCannonOverlay();
    }
}

// Modified so player starts facing forwards, so listen server re-sets pending ammo if another player has changed loaded ammo type since host player was last in this cannon,
// and so autocannon always goes to state 'EnteringVehicle' even for a single position cannon, which makes certain pending ammo settings are correct
simulated function ClientKDriverEnter(PlayerController PC)
{
    local DHVehicleCannon Cannon;

    super.ClientKDriverEnter(PC);

    PlayerFaceForwards(PC);

    // Listen server host player re-sets pending ammo settings if another player has changed the loaded ammo type since he was last in this cannon
    // If current ammo has changed, any previous choice of pending ammo to load probably no longer makes sense & needs to be discarded (similar to net client in PostNetReceive)
    if (Level.NetMode == NM_ListenServer)
    {
        Cannon = DHVehicleCannon(VehWep);

        if (Cannon != none && Cannon.ProjectileClass != Cannon.SavedProjectileClass)
        {
            Cannon.LocalPendingAmmoIndex = Cannon.GetAmmoIndex();
            Cannon.ServerPendingAmmoIndex = Cannon.LocalPendingAmmoIndex;
        }
    }

    // A single position autocannon goes to state 'EnteringVehicle' - very obscure but avoids potential problem if another player has changed pending ammo - see notes in 'EnteringVehicle'
    if (!bMultiPosition && Role < ROLE_Authority && VehWep != none && VehWep.bUsesMags)
    {
        Gotostate('EnteringVehicle');
    }
}

// Modified so an autocannon net client always replicates its LocalPendingAmmoIndex to server when player enters
// Necessary as it's possible another player changed pending ammo & updated that to server, as autocannon updates any change in pending after each shot, not just when starting a reload
// We do it here to take advantage of brief Sleep in state code, meaning server has had time to replicate ProjectileClass to new owning client (a little hacky, but necessary & works)
// ClientKDriverEnter would be the obvious choice, but client is only just becoming owner of this cannon, triggering replication of proj class, & that doesn't happen in time for CKDE
simulated state EnteringVehicle
{
ignores SwitchFireMode; // added so no possibility of switching while entering

Begin:
    if (bMultiPosition) // added 'if' because it's now possible a single position autocannon has been sent to this state (very obscure, but being thorough!)
    {
        HandleEnter();
    }

    Sleep(0.2);

    if (Role < ROLE_Authority && DHVehicleCannon(VehWep) != none && VehWep.bUsesMags) // added for autocannon to always replicate its LocalPendingAmmoIndex to server
    {
        DHVehicleCannon(VehWep).CheckUpdatePendingAmmo(true);
    }

    GotoState('');
}

// Modified so player faces forwards when coming up off the gunsight (feels more natural), & to add better handling of locked camera,
simulated state ViewTransition
{
    simulated function HandleTransition()
    {
        super.HandleTransition();

        if (Level.NetMode != NM_DedicatedServer && LastPositionIndex < GunsightPositions && DriverPositionIndex >= GunsightPositions
            && IsHumanControlled() && !PlayerController(Controller).bBehindView)
        {
            PlayerFaceForwards();
        }
    }

    simulated function EndState()
    {
        super.EndState();

        // If camera was locked to PlayerCameraBone during button/unbutton transition, match rotation to that now, so the view can't snap to another rotation
        if (bLockCameraDuringTransition && Level.NetMode != NM_DedicatedServer &&
            ((DriverPositionIndex == UnbuttonedPositionIndex && LastPositionIndex < UnbuttonedPositionIndex)
            || (LastPositionIndex == UnbuttonedPositionIndex && DriverPositionIndex < UnbuttonedPositionIndex))
            && ViewTransitionDuration > 0.0 && IsHumanControlled() && !PlayerController(Controller).bBehindView)
        {
            SetRotation(rot(0, 0, 0));
            Controller.SetRotation(Rotation);
        }
    }
}

// Modified so listen server host player records currently loaded ammo type on exiting, so if he re-enters this cannon he will know if another player has since loaded different ammo
// If loaded ammo changes, any previous choice of pending ammo to load will probably no longer make sense & have to be discarded
simulated function ClientKDriverLeave(PlayerController PC)
{
    super.ClientKDriverLeave(PC);

    if (Level.NetMode == NM_ListenServer && DHVehicleCannon(VehWep) != none)
    {
        DHVehicleCannon(VehWep).SavedProjectileClass = VehWep.ProjectileClass;
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *************************  SETUP, UPDATE, CLEAN UP  ***************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add extra material properties
static function StaticPrecache(LevelInfo L)
{
    super.StaticPrecache(L);

    if (default.CannonScopeCenter != none)
    {
        L.AddPrecacheMaterial(default.CannonScopeCenter);
    }

    if (default.RangeRingRotator != none)
    {
        L.AddPrecacheMaterial(default.RangeRingRotator);
    }

    if (default.DestroyedGunsightOverlay != none)
    {
        L.AddPrecacheMaterial(default.DestroyedGunsightOverlay);
    }

    if (default.PeriscopeOverlay != none)
    {
        L.AddPrecacheMaterial(default.PeriscopeOverlay);
    }

    if (default.AmmoShellTexture != none)
    {
        L.AddPrecacheMaterial(default.AmmoShellTexture);
    }

    if (default.AmmoShellReloadTexture != none)
    {
        L.AddPrecacheMaterial(default.AmmoShellReloadTexture);
    }

    if (default.AltAmmoReloadTexture != none)
    {
        L.AddPrecacheMaterial(default.AltAmmoReloadTexture);
    }
}

// Modified to add extra material properties
simulated function UpdatePrecacheMaterials()
{
    super.UpdatePrecacheMaterials();

    Level.AddPrecacheMaterial(CannonScopeCenter);
    Level.AddPrecacheMaterial(RangeRingRotator);
    Level.AddPrecacheMaterial(DestroyedGunsightOverlay);
    Level.AddPrecacheMaterial(PeriscopeOverlay);
    Level.AddPrecacheMaterial(AmmoShellTexture);
    Level.AddPrecacheMaterial(AmmoShellReloadTexture);
    Level.AddPrecacheMaterial(AltAmmoReloadTexture);
}

// Modified as per deprecated ROTankCannonPawn
function AttachToVehicle(ROVehicle VehiclePawn, name WeaponBone)
{
    super.AttachToVehicle(VehiclePawn, WeaponBone);

    if (VehiclePawn != none && VehiclePawn.bDefensive)
    {
        bDefensive = true;
    }
}

// Modified to reliably initialize the manual/powered turret settings when vehicle spawns
simulated function InitializeVehicleAndWeapon()
{
    super.InitializeVehicleAndWeapon();

    if (DHArmoredVehicle(VehicleBase) != none)
    {
        SetManualTurret(DHArmoredVehicle(VehicleBase).bEngineOff);
    }
    else
    {
        SetManualTurret(true);
    }
}

// New function to toggle between manual/powered turret settings - called from PostNetReceive on vehicle clients, instead of constantly checking in Tick()
simulated function SetManualTurret(bool bManual)
{
    if (bManual || bManualTraverseOnly)
    {
        RotateSound = ManualRotateSound;
        PitchSound = ManualPitchSound;
        RotateAndPitchSound = ManualRotateAndPitchSound;
        MinRotateThreshold = ManualMinRotateThreshold;
        MaxRotateThreshold = ManualMaxRotateThreshold;

        if (DHVehicleCannon(Gun) != none)
        {
            Gun.RotationsPerSecond = DHVehicleCannon(Gun).ManualRotationsPerSecond;
        }
    }
    else
    {
        RotateSound = PoweredRotateSound;
        PitchSound = PoweredPitchSound;
        RotateAndPitchSound = PoweredRotateAndPitchSound;
        MinRotateThreshold = PoweredMinRotateThreshold;
        MaxRotateThreshold = PoweredMaxRotateThreshold;

        if (DHVehicleCannon(Gun) != none)
        {
            Gun.RotationsPerSecond = DHVehicleCannon(Gun).PoweredRotationsPerSecond;
        }
    }
}

// Modified (from deprecated ROTankCannonPawn) to allow turret traverse or elevation seizure if turret ring or pivot are damaged
function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange)
{
    if (Gun != none && Gun.bUseTankTurretRotation)
    {
        if (bTurretRingDamaged)
        {
            YawChange = 0.0;
        }

        if (bGunPivotDamaged)
        {
            PitchChange = 0.0;
        }

        UpdateTurretRotation(DeltaTime, YawChange, PitchChange);

        if (IsHumanControlled())
        {
            PlayerController(Controller).WeaponBufferRotation.Yaw = CustomAim.Yaw;
            PlayerController(Controller).WeaponBufferRotation.Pitch = CustomAim.Pitch;
        }
    }
}

// Modified to add in the scope turn speed factor if the player is using periscope or binoculars
function UpdateRocketAcceleration(float DeltaTime, float YawChange, float PitchChange)
{
    local float TurnSpeedFactor;

    if ((DriverPositionIndex == PeriscopePositionIndex || DriverPositionIndex == BinocPositionIndex) && DHPlayer(Controller) != none)
    {
        TurnSpeedFactor = DHPlayer(Controller).DHScopeTurnSpeedFactor;
        YawChange *= TurnSpeedFactor;
        PitchChange *= TurnSpeedFactor;
    }

    super.UpdateRocketAcceleration(DeltaTime, YawChange, PitchChange);
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  MISCELLANEOUS ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New function to damage gunsight optics
function DamageCannonOverlay()
{
    ClientDamageCannonOverlay();
    bOpticsDamaged = true;
}

// New replicated server-to-client function to damage gunsight optics
simulated function ClientDamageCannonOverlay()
{
    GunsightOverlay = DestroyedGunsightOverlay;
}

// New function to make player face forwards, relative to any turret rotation - we simply zero rotation, as any turret rotation gets added in SpecialCalcFirstPersonView()
simulated function PlayerFaceForwards(optional Controller C)
{
    if (C == none)
    {
        C = Controller;
    }

    SetRotation(rot(0, 0, 0));

    if (C != none)
    {
        C.SetRotation(Rotation); // owning net client will update rotation back to server
    }
}

// Modified to use DHArmoredVehicle instead of deprecated ROTreadCraft
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

// Debug exec from deprecated ROTankCannonPawn
exec function SetRange(byte NewRange)
{
    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && Gun != none)
    {
        Log("Switching range from" @ Gun.CurrentRangeIndex @ "to" @ NewRange);
        Gun.CurrentRangeIndex = NewRange;
    }
}

// New debug exec to set the coaxial MG's positional offset vector
exec function SetAltFireOffset(int NewX, int NewY, int NewZ, optional bool bScaleOneTenth)
{
    local vector OldAltFireOffset;

    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && Gun != none)
    {
        OldAltFireOffset = Gun.AltFireOffset;
        Gun.AltFireOffset.X = NewX;
        Gun.AltFireOffset.Y = NewY;
        Gun.AltFireOffset.Z = NewZ;

        if (bScaleOneTenth) // option allowing accuracy to 0.1 Unreal units, by passing floats as ints scaled by 10 (e.g. pass 55 for 5.5)
        {
            Gun.AltFireOffset /= 10.0;
        }

        if (Gun.AmbientEffectEmitter != none)
        {
            Gun.AmbientEffectEmitter.SetRelativeLocation(Gun.AltFireOffset);
        }

        Log(Gun.Tag @ "AltFireOffset =" @ Gun.AltFireOffset @ "(was" @ OldAltFireOffset $ ")");
    }
}

// New debug exec to set the coaxial MG's launch position optional X offset
exec function SetAltFireSpawnOffset(float NewValue)
{
    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && DHVehicleCannon(Gun) != none)
    {
        Log(Gun.Tag @ "AltFireSpawnOffsetX =" @ NewValue @ "(was" @ DHVehicleCannon(Gun).AltFireSpawnOffsetX $ ")");
        DHVehicleCannon(Gun).AltFireSpawnOffsetX = NewValue;
    }
}

// New debug exec to toggle bGunsightSettingMode, allowing calibration of range settings
exec function SetGunsight()
{
    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && DHVehicleCannon(Gun) != none)
    {
        DHVehicleCannon(Gun).bGunsightSettingMode = !DHVehicleCannon(Gun).bGunsightSettingMode;
        Log(Gun.Tag @ "bGunsightSettingMode =" @ DHVehicleCannon(Gun).bGunsightSettingMode);
    }
}

exec function LogCannon() // DEBUG (Matt: please use & report if you ever find you can't fire cannon or coax, or do a reload, when you should be able to)
{
    Log("LOGCANNON: Gun =" @ Gun.Tag @ " VehWep =" @ VehWep.Tag @ " VehWep.WeaponPawn =" @ VehWep.WeaponPawn.Tag @ " Gun.Owner =" @ Gun.Owner.Tag);
    Log("Controller =" @ Controller.Tag @ " ViewTransition =" @ IsInState('ViewTransition') @ " DriverPositionIndex =" @ DriverPositionIndex);
    Log("ReloadState =" @ GetEnum(enum'EReloadState', VehWep.ReloadState) @ " bReloadPaused =" @ VehWep.bReloadPaused
        @ " ProjectileClass =" @ VehWep.ProjectileClass @ " HasAmmoToReload() =" @ VehWep.HasAmmoToReload(VehWep.GetAmmoIndex()));
    Log("AmmoIndex =" @ VehWep.GetAmmoIndex() @ " LocalPendingAmmoIndex =" @ DHVehicleCannon(VehWep).LocalPendingAmmoIndex
        @ " ServerPendingAmmoIndex =" @ DHVehicleCannon(VehWep).ServerPendingAmmoIndex @ " PrimaryAmmoCount() =" @ VehWep.PrimaryAmmoCount());

    if (bHasAltFire)
    {
        Log("AltReloadState =" @ GetEnum(enum'EReloadState', DHVehicleCannon(VehWep).AltReloadState)
            @ " bAltReloadPaused =" @ DHVehicleCannon(VehWep).bAltReloadPaused @ " AltAmmoCharge =" @ VehWep.AltAmmoCharge @ " NumMGMags =" @ VehWep.NumMGMags);
    }
}

defaultproperties
{
    // Positions & entry
    PositionInArray=0
    bMustBeTankCrew=true
    bMultiPosition=true
    GunsightPositions=1
    UnbuttonedPositionIndex=2
    PeriscopePositionIndex=-1    // -1 signifies no periscope by default
    BinocPositionIndex=3
    IntermediatePositionIndex=-1 // -1 signifies no intermediate position by default
    RaisedPositionIndex=-1       // -1 signifies to match the RPI to the UnbuttonedPositionIndex by default

    // Camera & HUD
    CameraBone="Gun"
    PlayerCameraBone="Camera_com"
    AltAmmoReloadTexture=texture'DH_InterfaceArt_tex.Tank_Hud.MG42_ammo_reload'
    HudName="Cmdr"

    // Gunsight overlay
    OverlayCenterSize=0.9
    RangeText="Meters"
    RangePositionX=0.16
    RangePositionY=0.2

    // Turret/cannon movement
    MaxRotateThreshold=1.5
    ManualMinRotateThreshold=0.25
    ManualMaxRotateThreshold=2.5
    PoweredMinRotateThreshold=0.15
    PoweredMaxRotateThreshold=1.75

    // Movement sounds
    bSpecialRotateSounds=true
    ManualRotateSound=sound'Vehicle_Weapons.Turret.manual_turret_traverse2'
    ManualPitchSound=sound'Vehicle_Weapons.Turret.manual_turret_elevate'
    ManualRotateAndPitchSound=sound'Vehicle_Weapons.Turret.manual_turret_traverse'
    SoundVolume=130

    // Weapon fire
    bHasAltFire=true
    bHasFireImpulse=true
    FireImpulse=(X=-90000.0,Y=0.0,Z=0.0)
}
