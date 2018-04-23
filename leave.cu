/*community-wise parallel computation for leave phase*/
__global__ void leave_phase(int *stay_listd,cluster *cluster_list,int *cluster_track_vertex,int *comm_conn_scored,int no_node,int *added_device,int KCORE,int *leaved)
{
            __shared__ int leave[1];
			int x=threadIdx.x,i,count=0;
			leave[0]=0;
			if(cluster_list[x].tag!=-1)
			{
			        
					for(i=0;i<no_node ;i++)
					{
					
							int y=added_device[x*no_node+i];
							if(y!=-1 && cluster_track_vertex[x*no_node+y]!=-1 && stay_listd[y]>comm_conn_scored[x*no_node+y])
							{
							          cluster_track_vertex[x*no_node+y]=-1;
							          cluster_list[x].size=cluster_list[x].size-1;
							    //      count++;
							          if(cluster_list[x].size<=KCORE)
							          {
							                cluster_list[x].tag=-1;
							               // leave[0]=0;
							          }
							          else
							          {
							                leave[0]=1;
							                
							            	__syncthreads();
							            	*leave=leave[0];
							            	
							           }
							           
							}
						//	if( y==-1 )
							
							//     count++; 
							    
							
					
					}
					//cluster_list[x].size=(no_node-count);
			  *leaved=leave[0];
			}
			
			
}
