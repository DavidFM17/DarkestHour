//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHCommandMenu_SquadManageNonMember extends DHCommandMenu;

function bool ShouldHideMenu()
{
    return MenuObject == none;
}

function bool OnSelect(DHCommandInteraction Interaction, int Index, vector Location)
{
    local DHPlayer PC;
    local DHPlayerReplicationInfo PRI, OtherPRI;

    if (Interaction == none || Interaction.ViewportOwner == none || Index < 0 || Index >= Options.Length)
    {
        return false;
    }

    OtherPRI = DHPlayerReplicationInfo(MenuObject);
    PC = DHPlayer(Interaction.ViewportOwner.Actor);

    if (PC != none && OtherPRI != none)
    {
        PRI = DHPlayerReplicationInfo(PC.PlayerReplicationInfo);

        if (PRI != none)
        {
            switch (Index)
            {
                case 0: // Invite
                    PC.ServerSquadInvite(OtherPRI);
                    break;
                default:
                    break;
            }
        }
    }

    Interaction.Hide();

    return true;
}

function string OptionTextForIndex(int Index)
{
    local DHPlayerReplicationInfo OtherPRI;
    local string PlayerName;

    OtherPRI = DHPlayerReplicationInfo(MenuObject);

    if (OtherPRI != none)
    {
        PlayerName = OtherPRI.PlayerName;
    }

    return Repl(Options[Index].Text, "{0}", PlayerName);
}

defaultproperties
{
    Options(0)=(Text="Invite {0} to squad",Material=Material'DH_InterfaceArt_tex.HUD.squad_signal_fire')
}

