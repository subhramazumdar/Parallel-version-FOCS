/*to find the number of clusters a vertex belongs to...computed in parallel for all vertices*/
__global__ void count_cluster(int *c_neigh_list,edge_list *adj_list,cluster *cluster_list,int no_node)
{
			int x=threadIdx.x*no_node;
		
			int i=0,j,l,k,count1=0;
			
			for(i=0;i<no_node && cluster_list[threadIdx.x].tag!=-1;i++)
			{
					
			    int y=cluster_list[threadIdx.x].head;
			
				for(j=y;j<(y+no_node);j++)
				{
				    count1=0;
					if(adj_list[j].vert==i)
					{
						
						
						for(l=i*no_node+1;l<(i*no_node+no_node);l++)
					    {
					
					      for(k=y;k<(y+no_node);k++)
					      {
					         if(adj_list[l].vert!=-1 && adj_list[l].vert==adj_list[k].vert)
					         {
					         		count1++;
					         		break;
					         }
					         
					       }  
					      	
					    }
					    
						
						
					  c_neigh_list[x+i]=count1;										
					  break;
					}
					
			    }		
			    
			
			}
			//c_neigh_list[cluster_list[x].head]=x;
			/*int y=cluster_list[threadIdx.x].head;
			
			
			for(i=y;i<(y+no_node);i++)
			{
				if(adj_list[i]==threadIdx.x)
				{
					//vertex exist in the cluster
					count=0;
					for(j=x+1;j<(x+no_node);j++)
					{
					
					      for(k=y;k<(y+no_node);k++)
					         if(adj_list[j]==adj_list[k])
					         {
					         		count++;
					         }
					      	
					}
					c_neigh_list[x]=count;
					
							
						
				}	
			
			}*/
			
			

}

/*cluster-wise parallel computation of connectedness scores*/
__global__ void score(int*comm_conn_score,int*neigh_conn_score,int *c_neigh_list,edge_list *adj_list,cluster *cluster_list,int no_node,int KCORE){

    int x=threadIdx.x;
    
    int i,j,k;
    
    for(i=0;i<no_node;i++){
        if(c_neigh_list[x*no_node+i]>KCORE)
    		comm_conn_score[x*no_node+i]=(((c_neigh_list[x*no_node+i]-KCORE+1)*100)/(cluster_list[x].size-KCORE));
    	else
    	    comm_conn_score[x*no_node+i]=0; 
    	neigh_conn_score[x*no_node+i]=((c_neigh_list[x*no_node+i])*100)/adj_list[i*no_node].count;
    	
    }
    
    return;
}

/*Vertex-wise parallel computation of distribution of counts of scores...common kernel for community and neighbourhood connectedness scores*/
__global__ void bucket_fill(cluster*cluster_list,int *conn_score,int *bucket,int no_node,int maxi){

    int x=threadIdx.x;
    int i,k;
    
    
    
    for(i=0;i<no_node;i++)
    {
        
		for(k=1;k<20 && cluster_list[i].tag!=-1;k++)
		{
		        
				if(conn_score[threadIdx.x+i*no_node]>(k*5) && conn_score[threadIdx.x+i*no_node]<=(5*(k+1)))	
			{
					bucket[x*(maxi)+19-k]++;
		
			}	
		    
		
		}    
        if(cluster_list[i].tag!=-1)
        {
        
               				if(conn_score[threadIdx.x+i*no_node]>=0 && conn_score[threadIdx.x+no_node*i]<5)	
               				   bucket[x*(maxi)+19]++;
        
        }
    
    
    }    
	
    
    return;
}	

