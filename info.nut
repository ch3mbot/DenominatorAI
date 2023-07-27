class DenominatorAI extends AIInfo {
    function GetAuthor()      { return "Dagan Hartmann"; }
    function GetName()        { return "DenominatorAI"; }
    function GetDescription() { return "Will attempt to crush you and ruin your game"; }
    function GetVersion()     { return 1; }
    function GetDate()        { return "2023-07-26"; }
    function CreateInstance() { return "DenominatorAI"; }
    function GetShortName()   { return "DMAI"; }
    function GetAPIVersion()  { return "12"; }
  }

  RegisterAI(DenominatorAI());