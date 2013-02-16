// ******************************************************************
// This class gives all the information needed to launch various types of munchkins.
// ******************************************************************
class MunchkinParams
{
  String execPath;
  String[] execArgs;
  int nation;
  
  public MunchkinParams(String execPath, String[] execArgs, int nation)
  {
    this.execPath = execPath;
    this.execArgs = execArgs;
    this.nation = nation;
  }
  
  public void run()
  {
    String[] processArgs = { execPath };
    for (int i=0; i<execArgs.length; i++)
      processArgs = append( processArgs, execArgs[i] );
    Process p = open(processArgs);
  }
}
