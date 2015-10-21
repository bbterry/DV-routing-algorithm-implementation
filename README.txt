I wrote a "distributed" set of procedures that implement a distributed asynchronous distance vector routing for the network.

The following functions will "execute" asynchronously within the emulated environment.

For node 0:

rtinit0()  This function will be called once at the beginning of the emulation. rtinit0() has no arguments. It should initialize the distance table in node 0.

All links are bi-directional and the costs in both directions are identical. After initializing the distance table,
and any other data structures needed by my node 0 functions, it should then send its directly-connected neighbors the cost of it minimum cost paths to all other network nodes. This minimum cost information is sent to neighboring nodesin a routing packet by calling the routine tolayer2(), as described below. The format of the routing packet is also described below.

rtupdate0(struct rtpkt *rcvdpkt)  This routine will be called when node 0 receives a routing packet that was sent to it by one if its directly connected neighbors. The parameter *rcvdpkt is a pointer to the packet that was received. 

rtupdate0() is the "heart" of the distance vector algorithm. The values it receives in a routing packet from some other node i contain i's current shortest path costs to all other network nodes. rtupdate0() uses these received values to update its own distance table (as specified by the distance vector algorithm). If its own minimum cost to another node changes as a result of the update, node 0 informs its directly connected neighbors of this change in minimum cost by sending them a routing packet. Recall that in the distance vector algorithm, only directly connected nodes will exchange routing packets. Thus nodes 1 and 2 will communicate with each other, but nodes 1 and 3 will not communicate with each other.

The distance table inside each node is the principal data structure used by thedistance vector algorithm. You will find it convenient to declare the distance table as a 4-by-4array of integers, where entry [i,j] in the distance table in node 0 is node 0's currently computed cost to node i via direct neighbor j. If node0 is not directly connected to j, you can ignore this entry. I will use the convention that the integer value 999 is "infinity".
