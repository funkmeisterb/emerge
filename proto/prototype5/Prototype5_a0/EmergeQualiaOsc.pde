class EmergeQualiaOsc extends QualiaOsc
{
  // ============================================
  // Constructor
  // ============================================  
  public EmergeQualiaOsc(int maxAgents, int port, int remotePort, String ip, QualiaEnvironmentManager manager)
  {
    super(maxAgents, port, remotePort, ip, manager); // dummy
    println("Construct");
  }
    
  // ============================================
  // Member functions
  // ============================================ 
  void emergeSendMunchkinInfo(int id, Munchkin m)
  {
    OscMessage msg = new OscMessage("/munchkin");
    msg.add(id);
    msg.add(m.x()/width);
    msg.add(m.y()/height);
    msg.add(m.size());
    msg.add(m.getHeat());
    sendOsc(msg);
  }
}
