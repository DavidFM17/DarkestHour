//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHSpawnPoint_SquadRallyPoint extends DHSpawnPointBase
    notplaceable;

var DHSquadReplicationInfo SRI;
var int SquadIndex;
var int RallyPointIndex;
var int SpawnsRemaining;
var int SpawnKillCount;
var int ActivationTime;
var sound CreationSound;

// TODO: don't allow placement of the rally point under water, minefield etc.

replication
{
    reliable if (Role == ROLE_Authority)
        SquadIndex, RallyPointIndex, SpawnsRemaining;
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        SRI = DarkestHourGame(Level.Game).SquadReplicationInfo;

        if (SRI == none)
        {
            Destroy();
        }

        // TODO: figure out how far away this can be heard from
        PlaySound(CreationSound, SLOT_None, 1.0,, 60.0,, true);

        SetTimer(1.0, true);
    }
}

auto state Constructing
{
Begin:
    Sleep(default.ActivationTime);  // TODO: replace magic number
    GotoState('Active');
}

state Active
{
    function Timer()
    {
        // TODO: find out if there are enemies nearby; if enemies are nearby for
        // long enough (consistently within ~25m for 15 seconds straight, kill the
        // rally point).
        // TODO: destroy immediately if enemies are within a ~10m radius and are
        // within eyeshot
        // TODO: 3-strike rule for spawn kills on the rally point
        // TODO: broadcast to squad if the rally point is overrun
        if (HasEnemiesNearby())
        {
            Destroy();
        }
    }

    event BeginState()
    {
        if (Role == ROLE_Authority)
        {
            // "The squad has established a new rally point."
            SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 44);
        }
    }
Begin:
    SetIsActive(true);
}

simulated function bool IsBlocked()
{
    return IsInState('Constructing');
}

function bool CanSpawnWithParameters(DHGameReplicationInfo GRI, int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (!super.CanSpawnWithParameters(GRI, TeamIndex, RoleIndex, SquadIndex, VehiclePoolIndex))
    {
        return false;
    }

    if (self.SquadIndex != SquadIndex)
    {
        return false;
    }

    if (SpawnsRemaining == 1)
    {
        // TODO: must be SL to use; where are we gonna get this from? a PRI??
    }

    return true;
}

function bool HasEnemiesNearby()
{
    local Pawn P;

    // TODO: remove magic number
    foreach RadiusActors(class'Pawn', P, class'DHUnits'.static.MetersToUnreal(25))
    {
        if (P == none)
        {
            continue;
        }

        if (P.GetTeamNum() != TeamIndex)
        {
            return true;
        }
    }

    return false;
}

function GetSpawnPosition(out vector SpawnLocation, out rotator SpawnRotation, int VehiclePoolIndex)
{
    local vector HitLocation, HitNormal;

    if (Trace(HitLocation, HitNormal, Location - vect(0, 0, 32), Location + vect(0, 0, 32)) != none)
    {
        SpawnLocation = HitLocation;
        SpawnLocation.Z += class'DHPawn'.default.CollisionHeight / 2;
    }
    else
    {
        SpawnLocation = Location;
        SpawnLocation.Z += class'DHPawn'.default.CollisionHeight / 2;
    }

    SpawnRotation = SpawnRotation;
}

function bool PerformSpawn(DHPlayer PC)
{
    local DarkestHourGame G;
    local vector SpawnLocation;
    local rotator SpawnRotation;

    G = DarkestHourGame(Level.Game);

    if (PC == none || PC.Pawn != none || G == none)
    {
        return false;
    }

    if (CanSpawnWithParameters(GRI, PC.GetTeamNum(), PC.GetRoleIndex(), PC.GetSquadIndex(), PC.VehiclePoolIndex))
    {
        GetSpawnPosition(SpawnLocation, SpawnRotation, PC.VehiclePoolIndex);

        if (G.SpawnPawn(PC, SpawnLocation, SpawnRotation) == none)
        {
            return false;
        }

        SpawnsRemaining -= 1;

        if (SpawnsRemaining <= 0)
        {
            // "A squad rally point has been exhausted."
            SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 46);

            Destroy();
        }

        return true;
    }

    return false;
}

defaultproperties
{
    StaticMesh=StaticMesh'DH_Military_stc.Parachute.Chute_pack'
    DrawType=DT_StaticMesh
    TeamIndex=-1
    SquadIndex=-1
    RallyPointIndex=-1
    SpawnsRemaining=9
    SpawnKillCount=0
    CreationSound=Sound'Inf_Player.Gibimpact.Gibimpact'
    ActivationTime=30
}

