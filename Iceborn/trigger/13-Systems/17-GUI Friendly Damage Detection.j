// GUI-Friendly Damage Detection -- v1.2.1 -- by Weep
//    http:// www.thehelper.net/forums/showthread.php?t=137957
//
//    Requires: only this trigger and its variables.
//
// -- What? --
//    This snippet provides a leak-free, GUI-friendly implementation of an "any unit takes
//    damage" event.  It requires no JASS knowledge to use.
//
//    It uses the Game - Value Of Real Variable event as its method of activating other
//    triggers, and passes the event responses through a few globals.
//
// -- Why? --
//    The traditional GUI method of setting up a trigger than runs when any unit is damaged
//    leaks trigger events.  This snippet is easy to implement and removes the need to do
//    you own GUI damage detection setup.
//
// -- How To Implement --
//    0. Before you copy triggers that use GDD into a new map, you need to copy over GDD
//       with its GDD Variable Creator trigger, or there will be a problem: the variables
//       won't be automatically created correctly.
//
//    1. Be sure "Automatically create unknown variables while pasting trigger data" is
//       enabled in the World Editor general preferences.
//    2. Copy this trigger category ("GDD") and paste it into your map.
//       (Alternately: create the variables listed in the globals block below, create a
//       trigger named "GUI Friendly Damage Detection", and paste in this entire text.)
//    3. Create your damage triggers using Game - Value Of Real Variable as the event,
//       select GDD_Event as the variable, and leave the rest of the settings to the default
//       "becomes Equal to 0.00".
//       The event responses are the following variables:
//          GDD_Damage is the amount of damage, replacing Event Response - Damage Taken.
//          GDD_DamagedUnit is the damaged unit, replacing Event Response - Triggering Unit.
//              Triggering Unit can still be used, if you need to use waits.
//              Read the -- Notes -- section below for more info.
//          GDD_DamageSource is the damaging unit, replacing Event Response - Damage Source.
//
// -- Notes --
//    GDD's event response variables are not wait-safe; you can't use them after a wait in
//    a trigger.  If you need to use waits, Triggering Unit (a.k.a. GetTriggerUnit()) can
//    be used in place of GDD_DamageSource.  There is no usable wait-safe equivalent to
//    Event Damage or Damage Source; you'll need to save the values yourself.
//
//    Don't write any values to the variables used as the event responses, or it will mess
//    up any other triggers using this snippet for their triggering.  Only use their values.
//
//    This uses arrays, so can detect damage for a maximum of 8190 units at a time, and
//    cleans up data at a rate of 33.33 per second, by default.  This should be enough for
//    most maps, but if you want to change the rate, change the value returned in the
//    GDD_RecycleRate function at the top of the code, below.
//
//    By default, GDD will not register units that have Locust at the moment of their
//    entering the game, and will not recognize when they take damage (which can only
//    happen if the Locust ability is later removed from the unit.)  To allow a unit to have
//    Locust yet still cause GDD damage events if Locust is removed, you can either design
//    the unit to not have Locust by default and add it via triggers after creation, or
//    edit the GDD_Filter function at the top of the code, below.
//
// -- Credits --
//    Captain Griffin on wc3c.net for the research and concept of GroupRefresh.
//
//    Credit in your map not needed, but please include this README.
//
// -- Version History --
//    1.2.1: Minor code cleaning.  Added configuration functions.  Updated documentation.
//    1.2.0: Made this snippet work properly with recursive damage.
//    1.1.1: Added a check in order to not index units with the Locust ability (dummy units).
//           If you wish to check for damage taken by a unit that is unselectable, do not
//           give the unit-type Locust in the object editor; instead, add the Locust ability
//           'Aloc' via a trigger after its creation, then remove it.
//    1.1.0: Added a check in case a unit gets moved out of the map and back.
//    1.0.0: First release.


//===================================================================
// Configurables.
function GDD_RecycleRate takes nothing returns real //The rate at which the system checks units to see if they've been removed from the game
    return 0.03
endfunction

function GDD_Filter takes unit u returns boolean //The condition a unit has to pass to have it registered for damage detection
    return GetUnitAbilityLevel(u, 'Aloc') == 0 //By default, the system ignores Locust units, because they normally can't take damage anyway
endfunction

//===================================================================
// This is just for reference.
// If you use JassHelper, you could uncomment this section instead of creating the variables in the trigger editor.

// globals
//  real udg_GDD_Event = 0.
//  real udg_GDD_Damage = 0.
//  unit udg_GDD_DamagedUnit
//  unit udg_GDD_DamageSource
//  trigger array udg_GDD__TriggerArray
//  integer array udg_GDD__Integers
//  unit array udg_GDD__UnitArray
//  group udg_GDD__LeftMapGroup = CreateGroup()
// endglobals

//===================================================================
// System code follows.  Don't touch!
function GDD_Event takes nothing returns boolean
    local unit damagedcache = udg_GDD_DamagedUnit
    local unit damagingcache = udg_GDD_DamageSource
    local real damagecache = udg_GDD_Damage
    set udg_GDD_DamagedUnit = GetTriggerUnit()
    set udg_GDD_DamageSource = GetEventDamageSource()
    set udg_GDD_Damage = GetEventDamage()
    set udg_GDD_Event = 1.
    set udg_GDD_Event = 0.
    set udg_GDD_DamagedUnit = damagedcache
    set udg_GDD_DamageSource = damagingcache
    set udg_GDD_Damage = damagecache
    set damagedcache = null
    set damagingcache = null
    return false
endfunction

function GDD_AddDetection takes nothing returns boolean
//  if(udg_GDD__Integers[0] > 8190) then
//      call BJDebugMsg("GDD: Too many damage events!  Decrease number of units present in the map or increase recycle rate.")
//      ***Recycle rate is specified in the GDD_RecycleRate function at the top of the code.  Smaller is faster.***
//      return
//  endif
    if(IsUnitInGroup(GetFilterUnit(), udg_GDD__LeftMapGroup)) then
        call GroupRemoveUnit(udg_GDD__LeftMapGroup, GetFilterUnit())
    elseif(GDD_Filter(GetFilterUnit())) then
        set udg_GDD__Integers[0] = udg_GDD__Integers[0]+1
        set udg_GDD__UnitArray[udg_GDD__Integers[0]] = GetFilterUnit()
        set udg_GDD__TriggerArray[udg_GDD__Integers[0]] = CreateTrigger()
        call TriggerRegisterUnitEvent(udg_GDD__TriggerArray[udg_GDD__Integers[0]], udg_GDD__UnitArray[udg_GDD__Integers[0]], EVENT_UNIT_DAMAGED)
        call TriggerAddCondition(udg_GDD__TriggerArray[udg_GDD__Integers[0]], Condition(function GDD_Event))
    endif
    return false
endfunction

function GDD_PreplacedDetection takes nothing returns nothing
    local group g = CreateGroup()
    local integer i = 0
    loop
        call GroupEnumUnitsOfPlayer(g, Player(i), Condition(function GDD_AddDetection))
        set i = i+1
        exitwhen i == bj_MAX_PLAYER_SLOTS
    endloop
    call DestroyGroup(g)
    set g = null
endfunction

function GDD_GroupRefresh takes nothing returns nothing
// Based on GroupRefresh by Captain Griffen on wc3c.net
    if (bj_slotControlUsed[5063] == true) then
        call GroupClear(udg_GDD__LeftMapGroup)
        set bj_slotControlUsed[5063] = false
    endif
    call GroupAddUnit(udg_GDD__LeftMapGroup, GetEnumUnit())
endfunction

function GDD_Recycle takes nothing returns nothing
    if(udg_GDD__Integers[0] <= 0) then
        return
    elseif(udg_GDD__Integers[1] <= 0) then
        set udg_GDD__Integers[1] = udg_GDD__Integers[0]
    endif
    if(GetUnitTypeId(udg_GDD__UnitArray[udg_GDD__Integers[1]]) == 0) then
        call DestroyTrigger(udg_GDD__TriggerArray[udg_GDD__Integers[1]])
        set udg_GDD__TriggerArray[udg_GDD__Integers[1]] = null
        set udg_GDD__TriggerArray[udg_GDD__Integers[1]] = udg_GDD__TriggerArray[udg_GDD__Integers[0]]
        set udg_GDD__UnitArray[udg_GDD__Integers[1]] = udg_GDD__UnitArray[udg_GDD__Integers[0]]
        set udg_GDD__UnitArray[udg_GDD__Integers[0]] = null
        set udg_GDD__Integers[0] = udg_GDD__Integers[0]-1
    endif
    set udg_GDD__Integers[1] = udg_GDD__Integers[1]-1
endfunction

function GDD_LeaveMap takes nothing returns boolean
    local boolean cached = bj_slotControlUsed[5063]
    if(udg_GDD__Integers[2] < 64) then
        set udg_GDD__Integers[2] = udg_GDD__Integers[2]+1
    else
        set bj_slotControlUsed[5063] = true
        call ForGroup(udg_GDD__LeftMapGroup, function GDD_GroupRefresh)
        set udg_GDD__Integers[2] = 0
    endif
    call GroupAddUnit(udg_GDD__LeftMapGroup, GetFilterUnit())
    set bj_slotControlUsed[5063] = cached
    return false
endfunction

// ===========================================================================
function InitTrig_GUI_Friendly_Damage_Detection takes nothing returns nothing
    local region r = CreateRegion()
    call RegionAddRect(r, GetWorldBounds())
    call TriggerRegisterEnterRegion(CreateTrigger(), r, Condition(function GDD_AddDetection))
    call TriggerRegisterLeaveRegion(CreateTrigger(), r, Condition(function GDD_LeaveMap))
    call GDD_PreplacedDetection()
    call TimerStart(CreateTimer(), GDD_RecycleRate(), true, function GDD_Recycle)
    set r = null
endfunction