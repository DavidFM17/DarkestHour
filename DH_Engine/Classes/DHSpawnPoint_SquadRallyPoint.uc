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
var sound CreationSound;

var int EncroachmentRadiusInMeters;
var int EncroachmentPenaltyBlockThreshold;
var int EncroachmentPenaltyOverrunThreshold;
var int EncroachmentPenaltyCounter;

var int SecondsToEstablish;

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
        PlaySound(CreationSound, SLOT_None, 2.0,, 60.0,, true);

        SetTimer(1.0, true);
    }
}

auto state Constructing
{
Begin:
    Sleep(default.SecondsToEstablish);
    GotoState('Active');
}

state Active
{
    function Timer()
    {
        local int EncroachingEnemiesCount;

        // TODO: destroy immediately if enemies are within a ~10m radius and are
        // within eyeshot
        // TODO: 3-strike rule for spawn kills on the rally point

        EncroachingEnemiesCount = GetEncroachingEnemyCount();

        if (EncroachingEnemiesCount > 0)
        {
            EncroachmentPenaltyCounter += EncroachingEnemiesCount;
        }
        else
        {
            EncroachmentPenaltyCounter -= 2;    // TODO; get rid of magic number
        }

        EncroachmentPenaltyCounter = Max(0, EncroachmentPenaltyCounter);

        if (EncroachmentPenaltyCounter < default.EncroachmentPenaltyBlockThreshold)
        {
            BlockReason = SPBR_None;
        }
        else if (EncroachmentPenaltyCounter < default.EncroachmentPenaltyOverrunThreshold)
        {
            BlockReason = SPBR_EnemiesNearby;
        }
        else
        {
            // "A squad rally point has been overrun by enemies."
            SRI.BroadcastLocalizedMessage(SRI.SquadMessageClass, 54);

            Destroy();
        }
    }

    event BeginState()
    {
        SetIsActive(true);

        // "The squad has established a new rally point."
        SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 44);

        // TODO: need to
    }
}

simulated function bool CanSpawnWithParameters(DHGameReplicationInfo GRI, int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
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


function int GetEncroachingEnemyCount()
{
    local int i;
    local Pawn P;

    foreach RadiusActors(class'Pawn', P, class'DHUnits'.static.MetersToUnreal(default.EncroachmentRadiusInMeters))
    {
        if (P != none && !P.bDeleteMe && P.Health > 0 && P.PlayerReplicationInfo != none && P.GetTeamNum() != TeamIndex)
        {
            i += 1;
        }
    }

    return i;
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

    SpawnRotation = Rotation;
}

// Returns true if the spawn point is "visible" to a player with the arguments
// provided.
simulated function bool IsVisibleTo(int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (!super.IsVisibleTo(TeamIndex, RoleIndex, SquadIndex, VehiclePoolIndex))
    {
        return false;
    }

    if (self.SquadIndex != SquadIndex)
    {
        return false;
    }

    return true;
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

        if (G.SpawnPawn(PC, SpawnLocation, SpawnRotation, self) == none)
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
    SecondsToEstablish=30
    EncroachmentRadiusInMeters=25
    EncroachmentPenaltyBlockThreshold=10
    EncroachmentPenaltyOverrunThreshold=30
}

