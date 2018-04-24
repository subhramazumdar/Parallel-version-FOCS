//
void score(int*comm_conn_score,int*neigh_conn_score,int *c_neigh_list,edge_list *adj_list,cluster *cluster_list,int no_node,int KCORE,int x){

   // int x=1,
    int i;
    for(i=0;i<no_node;i++){
        if(c_neigh_list[x*no_node+i]>KCORE){
            
    		comm_conn_score[x*no_node+i]=(((c_neigh_list[x*no_node+i]-KCORE+1)*100)/(cluster_list[x].size-KCORE));
    		//printf("%d %d\n",c_neigh_list[x*no_node+i],comm_conn_score[x*no_node+i]);
    		
    	}
    	else
    	    comm_conn_score[x*no_node+i]=0;
    	printf("score func\n");
    	
    	if(adj_list[x*no_node+i].count!=0)
    		neigh_conn_score[x*no_node+i]=((c_neigh_list[x*no_node+i])*100)/adj_list[x*no_node+i].count;
    	printf("%d %d\n",c_neigh_list[x*no_node+i],adj_list[x*no_node+i].count);
    	
    }
    
    for(i=x;i<=no_node*x+no_node;i++)
    {
    	//printf("%d %d\n",comm_conn_score[i],neigh_conn_score[i]);
    }
    return;
}
