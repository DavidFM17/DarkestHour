//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHCommandMenu_SquadManageMember extends DHCommandMenu;

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

    PC = DHPlayer(Interaction.ViewportOwner.Actor);
    OtherPRI = DHPlayerReplicationInfo(MenuObject);

    if (PC != none && OtherPRI != none)
    {
        PRI = DHPlayerReplicationInfo(PC.PlayerReplicationInfo);

        if (PRI != none)
        {
            switch (Index)
            {
                case 0: // Kick
                    PC.ServerSquadKick(OtherPRI);
                    break;
                case 1: // Promote to leader
                    PC.ServerSquadPromote(OtherPRI);
                    break;
                case 2: // Ban
                    // TODO: we don't have banning yet!
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
    Options(0)=(Text="Kick {0} from squad",Material=Material'DH_InterfaceArt_tex.HUD.squad_signal_fire')
    Options(1)=(Text="Promote {0} to squad leader",Material=Material'DH_InterfaceArt_tex.HUD.squad_signal_fire')
    Options(2)=(Text="Ban {0} from squad",Material=Material'DH_InterfaceArt_tex.HUD.squad_signal_fire')
}

