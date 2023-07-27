import("pathfinder.rail", "RailPathFinder", 1);
require("manager.nut");
require("banker.nut");
require("builder.nut")

class DenominatorAI extends AIController
{
    //function Start();

    builder = null; // Builder class instance
    banker = null;
    manager = null; // Manager class instance
    constructor()
    {
        manager = dManager(this);
        banker = dBanker(this);
        builder = dBuilder(this);
    }
}

function DenominatorAI::Start()
{
    AILog.Info("Started denominating");

    if (!AICompany.SetName("Denominator Inc")) {
        local i = 2;
        while (!AICompany.SetName("Denominator Inc #" + i)) {
          i = i + 1;
        }
    }

    while(true)
    {
		manager.CheckEvents();
        this.Sleep(10);
        AILog.Info("Denominating...");
        banker.PayLoan();
        builder.ChooseIndustries();
        builder.BuildStation(true);
    }
}

function DenominatorAI::Save()
{
   //This function is outside the class declaration and requires the name of the class so squirrel can assign it to the right place.
   return {};
}

function DenominatorAI::Load(version, data)
{
}