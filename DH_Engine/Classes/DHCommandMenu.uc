//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHCommandMenu extends Object
    abstract;

struct Option
{
    var localized string Text;
    var Material Material;
};

var array<Option> Options;

var DHCommandMenu NextMenu;
var DHCommandMenu PreviousMenu;

var Object MenuObject;

function string OptionTextForIndex(int Index)
{
    return Options[Index].Text;
}

function bool ShouldHideMenu();

function bool OnSelect(DHCommandInteraction Interaction, int Index, vector Location);
