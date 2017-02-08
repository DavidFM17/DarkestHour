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
        GRI = DHGameReplicationInfo(Level.Game.GameReplicationInfo);
        GRI.AddSpawnPoint(self);
    }
}

function bool PerformSpawn(DHPlayer PC);

// Called when a pawn is spawn killed from this spawn point. Override in child classes.
function OnSpawnKill(Pawn VictimPawn, Controller KillerController);

simulated function bool CanSpawnVehicle(DHGameReplicationInfo GRI, int VehiclePoolIndex);

simulated function bool CanSpawnRole(DHRoleInfo RI)
{
    return RI != none;
}

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

function SetIsActive(bool bIsActive)
{
    local Controller C;
    local DHPlayer PC;


    self.bIsActive = bIsActive;

    if (!bIsActive)
    {
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

function OnSpawn();

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

