//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================
// This is a generic spawn point. When squads were added, there was a di
//==============================================================================

class DHSpawnPointBase extends Actor
    abstract;

enum ESpawnPointBlockReason
{
    SPBR_None,
    SPBR_EnemiesNearby,
    SPBR_InObjective,
    SPBR_Full,
    SPBR_Constructing
};

var int SpawnPointIndex;
var int TeamIndex;
var ESpawnPointBlockReason BlockReason;
var private bool bIsActive;

var protected DHGameReplicationInfo GRI;

// The amount of time, in seconds, that a player will be invulnerable after
// spawning on this spawn point.
var float SpawnProtectionTime;

// The amount of time, in seconds, that a player will be considered a spawn kill
// after spawning on this spawn point.
var float SpawnKillProtectionTime;

replication
{
    reliable if (Role == ROLE_Authority)
        SpawnPointIndex, TeamIndex, BlockReason, bIsActive;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        // Add this spawn point to the GRI's list of spawn points.
        GRI = DHGameReplicationInfo(Level.Game.GameReplicationInfo);

        SpawnPointIndex = GRI.AddSpawnPoint(self);

        if (SpawnPointIndex == -1)
        {
            Error("Failed to add" @ self @ "to spawn point list!");
        }
    }
}

// Override to provide the business logic that does the spawning.
function bool PerformSpawn(DHPlayer PC);

// Called when a pawn is spawn killed from this spawn point. Override in child classes.
function OnSpawnKill(Pawn VictimPawn, Controller KillerController);

// Override to specify which vehicles can spawn at this spawn point.
simulated function bool CanSpawnVehicle(DHGameReplicationInfo GRI, int VehiclePoolIndex);

// Override to limit certain roles from using this spawn point.
simulated function bool CanSpawnRole(DHRoleInfo RI)
{
    return RI != none;
}

// Override to specify a different spawn pose, otherwise it just uses the spawn point's pose.
function GetSpawnPosition(out vector SpawnLocation, out rotator SpawnRotation, int VehiclePoolIndex)
{
    SpawnLocation = Location;
    SpawnRotation = Rotation;
}

// Returns true if the spawn point is "visible" to a player with the arguments
// provided.
simulated function bool IsVisibleTo(int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (self.TeamIndex != TeamIndex || !bIsActive)
    {
        return false;
    }

    return true;
}

// A blocked spawn point is an active spawn point that, for whatever reason,
// is not currently available to be spawned on.
simulated function bool IsBlocked()
{
    return BlockReason != SPBR_None;
}

// Returns true if the given arguments are satisfactory for spawning on this
// spawn point.
simulated function bool CanSpawnWithParameters(DHGameReplicationInfo GRI, int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (GRI == none || self.TeamIndex != TeamIndex || !bIsActive || IsBlocked())
    {
        return false;
    }

    if (!CanSpawnRole(GRI.GetRole(TeamIndex, RoleIndex)))
    {
        return false;
    }

    if (VehiclePoolIndex >= 0 && !CanSpawnVehicle(GRI, VehiclePoolIndex))
    {
        return false;
    }

    return true;
}

function bool IsActive()
{
    return bIsActive;
}

event Destroyed()
{
    super.Destroyed();

    // We call this so that players' spawns get invalidated if they are set
    // to spawn on this spawn point.
    SetIsActive(false);
}

function SetIsActive(bool bIsActive)
{
    local Controller C;
    local DHPlayer PC;

    self.bIsActive = bIsActive;

    if (!bIsActive)
    {
        // Invalidate spawns, if necessary.
        for (C = Level.ControllerList; C != none; C = C.NextController)
        {
            PC = DHPlayer(C);

            if (PC != none && PC.SpawnPointIndex == SpawnPointIndex)
            {
                PC.SpawnPointIndex = -1;
                PC.bSpawnPointInvalidated = true;
            }
        }
    }
}

// Override to change the button style for display on the deploy menu.
simulated function string GetStyleName()
{
    if (IsBlocked())
    {
        return "DHSpawnPointBlockedButtonStyle";
    }
    else
    {
        return "DHSpawnButtonStyle";
    }
}

defaultproperties
{
    TeamIndex=-1
    SpawnProtectionTime=2.5
    SpawnKillProtectionTime=5.0
    bAlwaysRelevant=true
    RemoteRole=ROLE_SimulatedProxy
    bIsActive=false
    bHidden=true
}

