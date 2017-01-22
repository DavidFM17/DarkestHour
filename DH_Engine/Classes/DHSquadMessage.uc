//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHSquadMessage extends ROGameMessage;

var localized string SquadJoinedMessage;
var localized string SquadLeftMessage;
var localized string SquadKickedMessage;
var localized string SquadNoLongerLeaderMessage;
var localized string SquadYouAreNowLeaderMessage;
var localized string SquadNewLeaderMessage;
var localized string SquadInviteAlreadyInSquadMessage;
var localized string SquadFullMessage;
var localized string SquadInvitePendingMessage;
var localized string SquadInviteSentMessage;
var localized string SquadNoLeaderMessage;
var localized string SquadLockedMessage;
var localized string SquadUnlockedMessage;
var localized string SquadCreatedMessage;
var localized string SquadRallyPointActiveMessage;
var localized string SquadRallyPointTooCloseMessage;
var localized string SquadRallyPointExhaustedMessage;
var localized string SquadRallyPointNeedSquadmateNearby;
var localized string SquadRallyPointCreatedMessage;
var localized string SquadRallyPointOverrunMessage;
var localized string SquadRallyPointGroundTooSteep;

// This is overridden to change the hard link to ROPlayer that caused a bug where
// bUseNativeRoleNames was not being honored.
static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    switch (Switch)
    {
        case 30:
            return Repl(default.SquadJoinedMessage, "{0}", RelatedPRI_1.PlayerName);
        case 31:
            return Repl(default.SquadLeftMessage, "{0}", RelatedPRI_1.PlayerName);
        case 32:
            return default.SquadKickedMessage;
        case 33:
            return default.SquadNoLongerLeaderMessage;
        case 34:
            return default.SquadYouAreNowLeaderMessage;
        case 35:
            return Repl(default.SquadNewLeaderMessage, "{0}", RelatedPRI_1.PlayerName);
        case 36:
            return Repl(default.SquadInviteAlreadyInSquadMessage, "{0}", RelatedPRI_1.PlayerName);
        case 37:
            return default.SquadFullMessage;
        case 38:
            return Repl(default.SquadInvitePendingMessage, "{0}", RelatedPRI_1.PlayerName);
        case 39:
            return Repl(default.SquadInviteSentMessage, "{0}", RelatedPRI_1.PlayerName);
        case 40:
            return default.SquadNoLeaderMessage;
        case 41:
            return default.SquadLockedMessage;
        case 42:
            return default.SquadUnlockedMessage;
        case 43:
            return default.SquadCreatedMessage;
        case 44:
            return default.SquadRallyPointActiveMessage;
        case 45:
            return Repl(default.SquadRallyPointTooCloseMessage, "{0}", UInteger(OptionalObject).Value);
        case 46:
            return default.SquadRallyPointExhaustedMessage;
        case 47:
            return default.SquadRallyPointNeedSquadmateNearby;
        case 48:
            return Repl(default.SquadRallyPointCreatedMessage, "{0}", UInteger(OptionalObject).Value);
        case 49:
            return default.SquadRallyPointGroundTooSteep;
        default:
            break;
    }

    return "";
}

defaultproperties
{
    SquadJoinedMessage="{0} has joined the squad."
    SquadLeftMessage="{0} has left the squad."
    SquadKickedMessage="You have been kicked from the squad."
    SquadNoLongerLeaderMessage="You are no longer the squad leader."
    SquadYouAreNowLeaderMessage="You are now the squad leader."
    SquadNewLeaderMessage="{0} has become the squad leader."
    SquadInviteAlreadyInSquadMessage="{0} is already in a squad."
    SquadFullMessage="You cannot be send invitations because the squad is full."
    SquadInvitePendingMessage="{0} has already been invited to join a squad. Please try again later."
    SquadInviteSentMessage="{0} has been invited to join the squad."
    SquadNoLeaderMessage="The squad leader has left the squad."
    SquadLockedMessage="The squad has been locked."
    SquadUnlockedMessage="The squad has been unlocked."
    SquadCreatedMessage="You have created a squad."
    SquadRallyPointActiveMessage="The squad has established a new rally point."
    SquadRallyPointTooCloseMessage="You cannot establish a rally point within {0} meters of an existing rally point."
    SquadRallyPointExhaustedMessage="A squad rally point has been exhausted."
    SquadRallyPointNeedSquadmateNearby="You must have at least one other squadmate nearby to establish a rally point."
    SquadRallyPointCreatedMessage="A squad rally point will be established in {0} seconds."
    SquadRallyPointOverrunMessage="A squad rally point has been overrun by enemies."
    SquadRallyPointGroundTooSteep="The ground is too steep to establish a rally point here."
}

