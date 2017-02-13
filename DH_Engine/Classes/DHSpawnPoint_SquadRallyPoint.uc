//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHSpawnPoint_SquadRallyPoint extends DHSpawnPointBase
    notplaceable;

var DHSquadReplicationInfo SRI;                 // Convenience variable to access the SquadReplicationInfo.

var int SquadIndex;                             // The squad index of the squad that owns this rally point.
var int RallyPointIndex;                        // The index into SRI.RallyPoints.
var int SpawnsRemaining;                        // The amount of spawns remaining on the rally point.
var sound CreationSound;                        // Sound that is played when the squad rally point is first placed.

var int ConstructionRadiusInMeters;             // The distance, in meters, that squadmates and enemies must be within to influence the ConstructionCounter.
var int OverrunRadiusInMeters;                  // The distance, in meters, that enemies must be within to immediately overrun a rally point.
var int EncroachmentRadiusInMeters;             // The distance, in meters, that enemies must be within to affect the EncroachmentPenaltyCounter
var int EncroachmentPenaltyBlockThreshold;      // The value that EncroachmentPenaltyCounter must reach for the rally point to be "blocked".
var int EncroachmentPenaltyOverrunThreshold;    // The value that EncroachmentPenaltyCounter must reach for the rally point to be "overrun".
var int EncroachmentPenaltyCounter;             // Running counter of encroachment penalty.

var float ConstructionCounter;                  // Running counter to keep track of construction status.
var float ConstructionCounterThreshold;         // The value that ConstructionCounter must reach for the rally point to be "established".

var float ConstructionStartTimeSeconds;         // The value of Level.TimeSeconds when this rally point began construction.
var float OverrunMinimumTimeSeconds;            // The number of seconds a rally point must be "alive" for in order to be overrun by enemies. (To stop squad rally points being used as "enemy radar".

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

        PlaySound(CreationSound, SLOT_None, 4.0,, 60.0,, true);

        SetTimer(1.0, true);
    }
}

auto state Constructing
{
    function Timer()
    {
        local int SquadmateCount;
        local int EnemyCount;

        global.Timer();

        GetPlayerCountsWithinRadius(default.ConstructionRadiusInMeters, SquadmateCount, EnemyCount);

        ConstructionCounter -= EnemyCount;
        ConstructionCounter += SquadmateCount;

        if (SquadmateCount == 0 && EnemyCount == 0)
        {
            // No one is around to establish the rally point, start depleting the counter.
            ConstructionCounter -= 1;
        }

        if (ConstructionCounter >= default.ConstructionCounterThreshold)
        {
            // Rally point exceeded the construction counter threshold. This
            // rally point is now established!
            GotoState('Active');
        }
        else if (ConstructionCounter <= 0)
        {
            // Delay destruction of the rally point so it can't be used as enemy radar.
            if (Level.TimeSeconds - ConstructionStartTimeSeconds > default.OverrunMinimumTimeSeconds)
            {
                // "A squad rally point failed to be established."
                SRI.BroadcastLocalizedMessage(SRI.SquadMessageClass, 55);

                Destroy();
            }
        }
    }

Begin:
ConstructionStartTimeSeconds = Level.TimeSeconds;
SetTimer(1.0, true);
}

function Timer()
{
    local int OverrunningEnemiesCount;

    GetPlayerCountsWithinRadius(default.OverrunRadiusInMeters,, OverrunningEnemiesCount);

    // Destroy the rally point immediately if there are enemies within a
    // very short distance.
    if (OverrunningEnemiesCount >= 1)
    {
        // "A squad rally point has been overrun by enemies."
        SRI.BroadcastLocalizedMessage(SRI.SquadMessageClass, 54);

        Destroy();
    }
}

state Active
{
    function Timer()
    {
        local int EncroachingEnemiesCount;

        global.Timer();

        // TODO: 3-strike rule for spawn kills on the rally point
        GetPlayerCountsWithinRadius(default.EncroachmentRadiusInMeters,, EncroachingEnemiesCount);

        if (EncroachingEnemiesCount > 0)
        {
            // There are enemies nearby, so increase the encroachment penalty
            // counter by the number of nearby enemies.
            EncroachmentPenaltyCounter += EncroachingEnemiesCount;
        }
        else
        {
            // There are no enemies nearby, decrease the penalty timer by the
            // amount of nearby friendlies.
            EncroachmentPenaltyCounter -= 2;    // TODO; get rid of magic number
        }

        EncroachmentPenaltyCounter = Max(0, EncroachmentPenaltyCounter);

        if (EncroachmentPenaltyCounter < default.EncroachmentPenaltyBlockThreshold)
        {
            BlockReason = SPBR_None;
        }
        else if (EncroachmentPenaltyCounter < default.EncroachmentPenaltyOverrunThreshold)
        {
            // The encoroachment penalty counter has reached a point where we
            // are now blocking the spawn from being used until enemies are
            // cleared out.
            BlockReason = SPBR_EnemiesNearby;
        }
        else
        {
            // "A squad rally point has been overrun by enemies."
            SRI.BroadcastLocalizedMessage(SRI.SquadMessageClass, 54);

            Destroy();
        }

        // TODO: we need a way to 'reactivate' the previous squad rally point if
        // this one is blocked.
        if (IsBlocked())
        {
        }
    }

    event BeginState()
    {
        SetIsActive(true);

        // "The squad has established a new rally point."
        SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 44);
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


function GetPlayerCountsWithinRadius(float RadiusInMeters, optional out int SquadmateCount, optional out int EnemyCount)
{
    local Pawn P;
    local DHPlayerReplicationInfo OtherPRI;

    foreach RadiusActors(class'Pawn', P, class'DHUnits'.static.MetersToUnreal(RadiusInMeters))
    {
        if (P != none && !P.bDeleteMe && P.Health > 0 && P.PlayerReplicationInfo != none)
        {
            if (P.GetTeamNum() == TeamIndex)
            {
                OtherPRI = DHPlayerReplicationInfo(P.PlayerReplicationInfo);

                if (OtherPRI != none && OtherPRI.SquadIndex == SquadIndex)
                {
                    SquadmateCount += 1;
                }
            }
            else
            {
                EnemyCount += 1;
            }
        }
    }
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

function OnSpawnKill(Pawn VictimPawn, Controller KillerController)
{
    if (KillerController != none && KillerController.GetTeamNum() != TeamIndex)
    {
        // "A squad rally point has been overrun by enemies."
        SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 54);

        Destroy();
    }
}

function string GetStyleName()
{
    if (IsBlocked())
    {
        return "DHRallyPointBlockedButtonStyle";
    }
    else
    {
        return "DHRallyPointButtonStyle";
    }
}

defaultproperties
{
    StaticMesh=StaticMesh'DH_Military_stc.Parachute.Chute_pack' // TODO: replace with custom made one
    DrawType=DT_StaticMesh
    TeamIndex=-1
    SquadIndex=-1
    RallyPointIndex=-1
    SpawnsRemaining=9
    CreationSound=Sound'Inf_Player.Gibimpact.Gibimpact'
    EncroachmentRadiusInMeters=25
    EncroachmentPenaltyBlockThreshold=10
    EncroachmentPenaltyOverrunThreshold=30
    OverrunRadiusInMeters=10
    ConstructionRadiusInMeters=25
    ConstructionCounterThreshold=60
    OverrunMinimumTimeSeconds=15
    bHidden=false
}

