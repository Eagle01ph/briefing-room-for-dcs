-- Time (in seconds) until next smoke is available
briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateNextSmoke = -999999
briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateDistance = nil
briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateHeading = nil

-- Spawn smoke marker
briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateDoSmoke = function(args)
  local smokePosition = args.position

  smokePosition.x = smokePosition.x - math.cos(briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateHeading * DEGREES_TO_RADIANS) * briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateDistance;
  smokePosition.z = smokePosition.z - math.sin(briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateHeading * DEGREES_TO_RADIANS) * briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateDistance;
  
  trigger.action.smoke(smokePosition, args.color)
  return nil
end

-- "Mark target with smoke" F10 radio command
briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurate = function()
  local objective = briefingRoom.mission.objectives[$OBJECTIVEINDEX$]
  briefingRoom.radioManager.play("$LANG_PILOT$: $LANG_SMOKENEARREQUEST$", "RadioPilotMarkTargetWithSmoke")

  if #briefingRoom.mission.objectives[$OBJECTIVEINDEX$].unitNames == 0 then -- no target units left
    briefingRoom.radioManager.play(objective.name.." $LANG_JTAC$:$LANG_NOTARGET$", "RadioSupportNoTarget", briefingRoom.radioManager.getAnswerDelay())
    return
  end
  
  local unit = dcsExtensions.getUnitOrStatic(briefingRoom.mission.objectives[$OBJECTIVEINDEX$].unitNames[1])
  if unit == nil then -- no unit nor static found with the ID
    briefingRoom.radioManager.play(objective.name.." $LANG_JTAC$:$LANG_NOTARGET$", "RadioSupportNoTarget", briefingRoom.radioManager.getAnswerDelay())
    return
  end
  
  local timeNow = timer.getAbsTime()
  
  if timeNow < briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateNextSmoke then -- Smoke not ready
    briefingRoom.radioManager.play(objective.name.." $LANG_JTAC$: $LANG_SMOKENEARBY$", "RadioSupportTargetAlreadyMarkedWithSmoke", briefingRoom.radioManager.getAnswerDelay())
    return
  end
  
  -- Set cooldown for next smoke
  briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateNextSmoke = timeNow + SMOKE_DURATION
  
  -- Play radio message and setup smoke creating function
  briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateDistance = math.floor(math.random(5, 20)) * 100
  briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateHeading = math.random(0, 359)

  local args = { position = unit:getPoint(), color = trigger.smokeColor.Red }
  if unit:getCoalition() == briefingRoom.playerCoalition then args.color = trigger.smokeColor.Green end
  briefingRoom.radioManager.play(objective.name.." $LANG_JTAC$: $LANG_SMOKENEARAFFIRM$"..dcsExtensions.degreesToCardinalDirection(briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateHeading).." of the smoke.", "RadioSupportTargetMarkedWithSmoke", briefingRoom.radioManager.getAnswerDelay(), briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurateDoSmoke, args)
end
      
-- Add the command to the F10 menu
missionCommands.addCommandForCoalition(briefingRoom.playerCoalition, "$LANG_SMOKENEARMENU$", briefingRoom.f10Menu.objectives[$OBJECTIVEINDEX$], briefingRoom.mission.objectiveFeatures[$OBJECTIVEINDEX$].targetDesignationSmokeMarkerInaccurate)
