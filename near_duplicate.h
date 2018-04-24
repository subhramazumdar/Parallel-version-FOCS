#include<stdio.h>
//structure of each node
typedef struct node{
	
	int vert;
	int count;
	
	struct node *next; 	

}edge_list;

//structure of each cluster
typedef struct c{

	int head;
	int tag;
	int size;

	
}cluster;

int mini(int x,int y)
{
     if(x<y)
        return x;
        
        
     else
       return y;

}	

//detection of near duplicate clusters
void near_duplicate(cluster *cluster_list,int no_node,int OVL,int *cluster_track_vertex)
{
   int i,intersect=0,k=0,l=0,j;
   //printf("%f\n",OVL);
   //OVL=100*OVL;
   for(i=0;i<no_node-1;i++)
   {
       intersect=0;
       int start_i=cluster_list[i].head;
       if(cluster_list[i].tag==-1)
          continue;
   	   for(j=i+1;j<no_node  ;j++)
   	   {
   	      if(cluster_list[j].tag==-1)
              continue;
   	   				int start_j=cluster_list[j].head;
   	   				
   	   				while(k<no_node )
   	   				{
   	   					while(l<no_node)
   	   					{
   	   					
   	   					 if(cluster_track_vertex[i*no_node+k]==1 &&  cluster_track_vertex[j*no_node+l]==1 && k==l)
   	   				
   	   						{
   	   						//    printf("vert common : %d\n",adj_list[start_j+l].vert);
   	   						  // printf("comm:%d,%d",k+1,l+1);
   	   							intersect++;
   	   							break;
   	   							
   	   						
   	   						}
   	   						//printf("c_t=%d\n",cluster_track_vertex[i]);
   	   						
   	   						l++;
   	   				    }
   	   				    l=0;
   	   				    k++;
   	   				    
   	   				
   	   				}
   	   				k=0;
   	   				l=0;
   	   				
   	   				//printf("%f,%d\n",(float)(intersect/mini(adj_list[start_i].count,adj_list[start_j].count)),intersect);
   	   				int f=(intersect*100)/mini(cluster_list[i].size,cluster_list[j].size);
   	   			//	printf("float=%f,%d,%d,%d\n",f,intersect,i+1,j+1);
   	   	          //  printf("c:%d,%d,%d,%d,i:%d,%d ovl=%d\n",i+1,j+1,cluster_list[i].size,cluster_list[j].size,intersect,f,OVL);
   	   				if(f>OVL)
   	   				{
   	   				     
   	   				       if(cluster_list[i].size<=cluster_list[j].size)
   	   				       {
   	   				           cluster_list[i].tag=-1;
   	   				       //    printf("near dup i,%d\n",i);
   	   				           break;	   
   	   				       }    
   	   				       else{
   	   				           cluster_list[j].tag=-1; 
   	   				          // printf("near dup j: %d\n",j);
   	   				       }   
   	   				
   	   				}
   	   				intersect=0; 
   	   
   	   }
   	   
   
   }
   //exit(0);
}

/*void near_duplicate(cluster *cluster_list,int no_node,float OVL,edge_list *adj_list)
{
   int i,intersect=0,k=0,l=0,j;
   printf("%f\n",OVL);
   for(i=0;i<no_node;i++)
   {
       intersect=0;
       int start_i=cluster_list[i].head;
       if(cluster_list[i].tag==-1)
          continue;
   	   for(j=i+1;j<no_node  ;j++)
   	   {
   	      if(cluster_list[j].tag==-1)
              continue;
   	   				int start_j=cluster_list[j].head;
   	   				while(k<no_node )
   	   				{
   	   					while(l<no_node)
   	   					{
   	   						if(adj_list[start_i+k].vert!=-1 && adj_list[start_i+k].vert==adj_list[start_j+l].vert)
   	   						{
   	   						//    printf("vert common : %d\n",adj_list[start_j+l].vert);
   	   							intersect++;
   	   							break;
   	   							
   	   						
   	   						}
   	   						
   	   						l++;
   	   				    }
   	   				    l=0;
   	   				    k++;
   	   				    
   	   				
   	   				}
   	   				k=0;
   	   				l=0;
   	   				
   	   				//printf("%f,%d\n",(float)(intersect/mini(adj_list[start_i].count,adj_list[start_j].count)),intersect);
   	   				float f=(float)(intersect/mini(adj_list[start_i].count,adj_list[start_j].count));
   	   			//	printf("float=%f,%d,%d,%d\n",f,intersect,i+1,j+1);
   	   	            intersect=0;
   	   				if(f>=OVL)
   	   				{
   	   				
   	   				       if(adj_list[start_i].count<=adj_list[start_j].count)
   	   				       {
   	   				           cluster_list[i].tag=-1;
   	   				           printf("near dup %d\n",i);
   	   				           break;	   
   	   				       }    
   	   				       else{
   	   				           cluster_list[j].tag=-1; 
   	   				           printf("near dup %d\n",j);
   	   				       }   
   	   				
   	   				}
   	   				 
   	   
   	   }
   	   
   
   }
   
}*/

/*void count_cluster(int v,int *c_neigh_list,edge_list *adj_list,cluster *cluster_list,int no_node)
{
			int x=v*no_node;
			//int x=threadIdx.x;
			int i=0,j,l,k,count=0;
			
			for(i=0;i<no_node && cluster_list[v].tag!=-1;i++)
			{
					
			    int y=cluster_list[v].head;
			
				for(j=y;j<(y+no_node);j++)
				{
				    count=0;
					if(adj_list[j].vert==i)
					{
						
						
						for(l=i*no_node;l<(i*no_node+no_node);l++)
					    {
					
					      for(k=y;k<(y+no_node);k++)
					      {
					         if(adj_list[l].vert==adj_list[k].vert)
					         {
					         		count++;
					         		break;
					         }
					         
					       }  
					      	
					    }
					    break;
						
						
															
					}
			    }		
			    c_neigh_list[x+i]=count;
			
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
			
			

//}




