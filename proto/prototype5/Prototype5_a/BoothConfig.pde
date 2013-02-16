// ******************************************************************
// This class contains all the particularities of a booths.
// ******************************************************************
class BoothConfig
{
  HashMap<Integer, MunchkinParams> munchkinConfig = new HashMap<Integer, MunchkinParams>();
  final static String rlExecFullPath = "C:/Qualia/QualiaOSC.exe";
  final static String btExecFullPath = "C:/Qualia/QualiaBTree.exe";
  
  final static String cuddlerBatchRLModelFile = "C:/Qualia/cuddler-attraction-obs5_nhu5_all.dat";
  final static String lonerBatchRLModelFile   = "C:/Qualia/loner-attraction-obs5_nhu5_all.dat";
  final static String prudentBatchRLModelFile = "C:/Qualia/prudent-attraction-obs5_nhu5_all.dat";

  final int totalNumMunchkins = 12;
  int numRLmunchkins = 0; // # of reinforcement learning agents at this booth
  int numBTmunchkins = 0; // # of behaviour tree agents at this booth
    
  public BoothConfig()
  {
    switch (BOOTHID)
    {
      case 1:
        numRLmunchkins = 11;
        numBTmunchkins = 1;
        break;
      case 2:
        numRLmunchkins = 11;
        numBTmunchkins = 1;
        break;
      case 3:
        numRLmunchkins = 11;
        numBTmunchkins = 1;
        break;
      case 4:
      default:
        numRLmunchkins = 4;
        numBTmunchkins = 8;
        break;
    }
    
    // Start by creating the required number of Qualia reinforcement learning agents
    for (int i=(BOOTHID-1)*totalNumMunchkins; i<=(BOOTHID-1)*totalNumMunchkins+numRLmunchkins-1; i++)
    {      
      String actionParams = String.valueOf(N_ACTIONS_PER_DIM);
      for (int j=1; j<ACTION_DIM; j++)
      {
        actionParams += "," + String.valueOf(N_ACTIONS_PER_DIM);
      }

      float softmaxTemp = 1.0f;
      int nation;
      switch (BOOTHID)
      {
        case 1:
          nation = Thing.RED;
          softmaxTemp = 0.5f;
          break;
        case 2:
          nation = Thing.BLUE;
          softmaxTemp = 0.5f;
          break;
        case 3:
          nation = Thing.GREEN;
          softmaxTemp = 0.5f;
          break;
        case 4:
        default:
          nation = Thing.RED;
          softmaxTemp = 0.2f;
          break;
      }

      String batchRLModelFile;      
      switch (nation)
      {
        case Thing.RED:
          batchRLModelFile = cuddlerBatchRLModelFile;
          break;
        case Thing.BLUE:
          batchRLModelFile = lonerBatchRLModelFile;
          break;
        case Thing.GREEN:
        default:
          batchRLModelFile = prudentBatchRLModelFile;
          break;
      }

      String[] execArgs = { String.valueOf(i), String.valueOf(OBSERVATION_DIM), String.valueOf(ACTION_DIM), actionParams, "-softmax", "-temp", String.valueOf(softmaxTemp),
                            "-port", String.valueOf(QUALIA_OSC_BASE_PORT), "-rport", String.valueOf(BOOTH_OSC_IN_PORT), 
                            "-load", batchRLModelFile };
      
      munchkinConfig.put(i, new MunchkinParams(rlExecFullPath, execArgs, nation));
    }
    
    // Then create the required number of Qualia behaviour tree agents
    for (int i=(BOOTHID-1)*totalNumMunchkins+numRLmunchkins; i<=(BOOTHID-1)*totalNumMunchkins+numRLmunchkins + numBTmunchkins-1; i++)
    {
      String actionParams = String.valueOf(N_ACTIONS_PER_DIM);
      for (int j=1; j<ACTION_DIM; j++)
      {
        actionParams += "," + String.valueOf(N_ACTIONS_PER_DIM);
      }      
      String[] execArgs = { String.valueOf(i), String.valueOf(OBSERVATION_DIM), String.valueOf(ACTION_DIM), actionParams, "-port", String.valueOf(QUALIA_OSC_BASE_PORT), "-rport", String.valueOf(BOOTH_OSC_IN_PORT) };
      int nation = Thing.RED;
      munchkinConfig.put(i, new MunchkinParams(btExecFullPath, execArgs, nation));
    }
  }
  
  public void launchMunchkins()
  {
    Iterator it = munchkinConfig.entrySet().iterator();
    while (it.hasNext())
    {
      Map.Entry me = (Map.Entry)it.next();
      MunchkinParams current = (MunchkinParams)me.getValue();
      current.run();
      
      try
      {
        Thread.sleep(10);
      }
      catch (InterruptedException e)
      {
        println(e);
      }
    }
  }
}
