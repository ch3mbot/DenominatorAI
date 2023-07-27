class dManager
{

}

/**
 * Checks and handles events waiting in the event queue.
 */
function dManager::CheckEvents()
{
  while(AIEventController.IsEventWaiting())
  {
      local event = AIEventController.GetNextEvent();
      switch (event.GetEventType()) {
          case AIEvent.ET_VEHICLE_CRASHED:
              local ec = AIEventVehicleCrashed.Convert(event);
              local v  = ec.GetVehicleID();
              AILog.Info("We have a crashed vehicle (" + v + ")");
              /* Handle the crashed vehicle */
              break;
      }
  }

}