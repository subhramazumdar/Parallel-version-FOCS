/*cluster-wise parallel computation for expand phase*/
__global__ void expand_phase(int* join_list,cluster*cluster_list,int*cluster_track_vertex,int*neigh_conn_list,int no_node,int* added,int*now_added,edge_list*adj_list,int KCORE,int*expand,int maxi){

	__shared__ int expand1[1];
	
	int x=threadIdx.x,i,count=0,k,j;
	
	if(cluster_list[x].tag!=-1){
	    
		for(j=0;j<no_node;j++){//for each member of added_i
		    if(added[x*no_node+j]!=-1){
				for(k=0;k<no_node;k++){//for each member u_k of neigh of v_j
					if(neigh_conn_list[x*no_node + adj_list[j*no_node+k].vert]>join_list[k] && cluster_track_vertex[x*no_node+adj_list[j*no_node+k].vert]==-1)
							{
						cluster_track_vertex[x*no_node+adj_list[j*no_node+k].vert]=1;
						now_added[x*no_node+adj_list[j*no_node+k].vert]=1;
						count++;
			 		}
				}
			}
			
		
		}
		if(count>=1){
				expand1[0]=1;
				__syncthreads();
				*expand=expand1[0];
			}
	
  	}	
  
}
	
	
		
			
