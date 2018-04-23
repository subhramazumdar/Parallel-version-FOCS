#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <malloc.h>
#include <time.h>
#include <cuda.h>

#define byte 32
int KCORE = 2;
int OVL =50;
int buck;


#include "near_duplicate.h"
//#include "count.h"
#include "cluster_count.cu"
#include "counting.h"
#include "cut_off.cu"
#include "leave.cu"
#include "expand.cu"
/******************** CHANGE PARAMETER VALUES HERE ****************************/

//#define KCORE 3 //a node will have atleast KCORE connections (computation time is decreased with increase in value of KCORE beacuse of rapid filtering of nodes)
//#define OVL 0.6 //allow the amount(fraction) of overlap before the smaller of the communities is removed

/******************** CHANGE PARAMETER VALUES HERE ****************************/


/*Cuda kernel to find neighbours of nodes with degree>=KCORE...Also initializes the Added_i list..cluster_track_vertex is a list which stores the members of each cluster*/
__global__ void find_neighbour(cluster*cluster_list,int *cluster_track_vertex,edge_list*a_d,int *added,long int no_nodes,int*k)
{
//edge_list **a_d,
	int i;
	//cluster_list[threadIdx.x].tag=0;
	//if(cluster_list[threadIdx.x].tag==-1){
		//a_d[threadIdx.x]->count=0;
	if(a_d[(threadIdx.x)*no_nodes].count >=*k)
	  { 
	  
	     cluster_list[threadIdx.x].tag=1;
	    
		//
		
		cluster_list[threadIdx.x].head=threadIdx.x*no_nodes;
		for(i=0;i<no_nodes;i++)
		{
		    if(((threadIdx.x)*no_nodes+i)%no_nodes == 0)
		      cluster_track_vertex[(threadIdx.x)*no_nodes+a_d[(threadIdx.x)*no_nodes+i].vert]=1;
		      
		      
		      
		     if(((threadIdx.x)*no_nodes+i)%no_nodes!=0 && a_d[(threadIdx.x)*no_nodes+i].vert!=-1){
		      added[(threadIdx.x)*no_nodes+i]=a_d[(threadIdx.x)*no_nodes+i].vert;
		      (cluster_list[threadIdx.x].size)++;
		      cluster_track_vertex[(threadIdx.x)*no_nodes+a_d[(threadIdx.x)*no_nodes+i].vert]=1;
		}
		  
	}
  }
	
}
		

int main(int argc, char *argv[])
{

     cudaEvent_t start, stop;
float time,time1=0;

	
	time_t start_time, end_time;

	int no_node,vert,vert1,maxi,*c_neigh_list,*c_neigh_listd,*comm_conn_scored,*neigh_conn_scored,*neigh_conn_score,*comm_conn_score,*stay_list,*stay_listd,*join_list,*join_listd,*now_added,*now_added_d;
    edge_list *adj_list,*temp,*adj_listd;	
    cluster*cluster_list,*cluster_listd;
	int i, j, vtx, adj, *temp2, mid, ll, ul, directed,flag=0,*flagd,*added,*added_device,*exapnd,*expand_d,count=0;
	
    
	char *syscmd, string[32];

	FILE *fp, *p;
    int *comm_vert_bucket,*comm_vert_bucketd,bucket_count=0;
    int *neigh_vert_bucket,*neigh_vert_bucketd,*leavd,*leave;
	int *cluster_track_vertex,*cluster_track_vertexd;
	leave=(int*)malloc(1*sizeof(int));
	exapnd=(int*)malloc(1*sizeof(int));
*leave=0,*exapnd=0;

	cudaMalloc(&leavd,sizeof(int));
	cudaMalloc(&expand_d,sizeof(int));

	
	if(argc < 2){
		printf("less input arguments.enter file name\n");
		exit(1);
	}
	else if(argc == 4){
		sscanf(argv[2], "%d", &KCORE);
		sscanf(argv[3], "%d", &OVL);
	}
	syscmd = (char *)malloc(200*sizeof(char));

	fp = fopen(argv[1],"r");
	fscanf(fp, "%d\t%d\n", &vtx, &adj);
	
	sprintf(string, "^%d\t%d$", adj, vtx);
	fclose(fp);
    OVL-=10;
	sprintf(syscmd, "grep -e '%s' %s| wc -l ", string, argv[1]);
	p = popen(syscmd, "r");
	fscanf(p,"%d", &directed);
	pclose(p);
	fprintf(stderr, "\ndirected %d", directed);

	
	if(directed == 0){
		sprintf(syscmd,"awk 'BEGIN{OFS=\"\t\";} {print $2,$1}' %s > temp", argv[1]);
		system(syscmd);
		sprintf(syscmd,"cat %s temp|sort -k 1,1n -k 2,2n > temp1", argv[1]);
		system(syscmd);
	}
	else{
		sprintf(syscmd,"sort -k 1,1n -k 2,2n %s > temp1", argv[1]);
		system(syscmd);
	}

	system("cut -f 1 temp1 > temp");
	sprintf(syscmd,"sort -n temp| uniq -c > %s.uniq", argv[1]);
	system(syscmd);
	system("rm temp");

	sprintf(syscmd, "wc -l %s.uniq", argv[1]);
	p = popen(syscmd, "r");
	fscanf(p,"%d", &no_node);
	pclose(p);
	fprintf(stderr, "\nNumber of nodes:\t%d\n", no_node);
    added=(int*)malloc(no_node*no_node*sizeof(int));//initial list of peripheral nodes added to in a cluster and then this modified using now_added list in expand phase	
    cluster_track_vertex=(int*)malloc(no_node*no_node*sizeof(int));//list of clusters to which each node belongs
    
    
  	adj_list=(edge_list*)malloc(no_node*no_node*sizeof(edge_list));//adjacency list representation of input graph
  	added=(int*)malloc(no_node*no_node*sizeof(int));
  	c_neigh_list=(int*)malloc(no_node*no_node*sizeof(int));//list no of neighbours of each vertex in each cluster 
  	for(i=0;i<no_node*no_node;i++)
  		c_neigh_list[i]=-1;
  	//cudaMalloc(&adj_listd,no_node*sizeof(edge_list*));
  	cluster_list=(cluster*)malloc(no_node*sizeof(cluster));//stores all the clusters along with its members
  	stay_list=(int*)malloc(sizeof(int)*no_node);//list of stay cut-offs
  	join_list=(int*)malloc(sizeof(int)*no_node);//list of join cut-offs
  	now_added=(int*)malloc(no_node*no_node*sizeof(int));//to store list of peripheral nodes to be added in expand phase
  	printf("%d\n",no_node);
       // Allocate array on device
    cudaMalloc( &cluster_listd, no_node*sizeof(cluster));
    cudaMalloc(&cluster_track_vertexd,no_node*no_node*sizeof(int));
    
	cudaMalloc( &flagd, sizeof(int));
	cudaMalloc( &added_device,no_node*no_node*sizeof(int));
	cudaMalloc( &stay_listd,no_node*sizeof(int));
	cudaMalloc( &join_listd,no_node*sizeof(int));
	cudaMalloc( &now_added_d,no_node*no_node*sizeof(int));
	
  	fp = fopen(argv[1],"r");
    //initializations
  	for(i=0;i<no_node*no_node;i++)
  	{

  			//cudaMalloc( &(adj_listd[i]), sizeof(edge_list)); 
  			
  			adj_list[i].vert=-1;
  			adj_list[i].count=0;
  			added[i]=-1;
  			cluster_track_vertex[i]=-1;
  			now_added[i]=-1;

  			
  	
  	}
  	
  	for(i=0;i<no_node;i++){//{
        cluster_list[i].tag=-1;
        cluster_list[i].size=1;
    }
      
	maxi=0;
	for(i=0;i<no_node;i++)
  		  adj_list[i*no_node].vert=i;
  	while(fscanf(fp,"%d %d\n",&vert,&vert1) )
  	{
  		 
  		  //temp=(edge_list*)malloc(1*sizeof(edge_list));
  		/*  temp->vert=vert1;
  		  temp->next=NULL;
  		  adj_list[vert-1]->next=temp;*/
  		  adj_list[(vert-1)*no_node].count++;
  		//  printf("vert:%d,%d\t",vert,vert1);
  		
  		
  		
  		  
  		  
  		  for(i=0;i<no_node;i++)
  		  {
				if(adj_list[(vert-1)*no_node+i].vert==-1)
				{
  		  			adj_list[(vert-1)*no_node+i].vert=vert1-1;
  		  			printf("vert:%d,%d\t",vert,vert1);
  		  			break;	
  		  	    }
  		  		
  		  
  		  }
  		  if(feof(fp))
  		     break;
  		  
  		  if( adj_list[vert-1].count>maxi)
  		  		maxi= adj_list[vert-1].count;
  	}
  	if(maxi>=20)
  	{
  		comm_vert_bucket=(int*)malloc(maxi*no_node*sizeof(int));
  		neigh_vert_bucket=(int*)malloc(maxi*no_node*sizeof(int));
  		bucket_count=maxi;
  	}	
    else
    {		
  	    comm_vert_bucket=(int*)malloc(20*no_node*sizeof(int));
  	    neigh_vert_bucket=(int*)malloc(20*no_node*sizeof(int));
  	    bucket_count=20;
  	    
  	}    
  	
  	for(i=0;i<bucket_count*no_node;i++)
  	{
  	   comm_vert_bucket[i]=0;
  	   neigh_vert_bucket[i]=0;
  	}
  	cudaMalloc(&comm_vert_bucketd,sizeof(int)*no_node*bucket_count);
  	cudaMemcpy(comm_vert_bucketd,comm_vert_bucket,sizeof(int)*no_node*bucket_count,cudaMemcpyHostToDevice);
  	cudaMalloc(&neigh_vert_bucketd,sizeof(int)*no_node*bucket_count);
  	cudaMemcpy(neigh_vert_bucketd,neigh_vert_bucket,sizeof(int)*no_node*bucket_count,cudaMemcpyHostToDevice);
  	
  	printf("\nAdj list\n");
  	  for(i=0;i<no_node;i++){
    	for(j=0;j<no_node;j++){
    	
    		printf("%d:%d\t",i,adj_list[no_node*i+j].vert);	
    	
    	
    	}
    	printf("\n");
    
    }
  	size_t size = no_node * sizeof(edge_list);
    
    
    //for(i=0;i<no_node;i++)
     cudaMalloc( &adj_listd, no_node*no_node*sizeof(edge_list));
    
  	
 // 	for(i=0;i<no_node;i++)
  	//	printf("%d\n",adj_list[i].count);
  	
  	fclose(fp);
  	
   	cudaMemcpy(adj_listd, adj_list, no_node*no_node*sizeof(edge_list), cudaMemcpyHostToDevice);
   /*	for(i=0;i<no_node;i++)
  	{
  	        	cudaMemcpy(adj_listd[i], adj_list[i], sizeof(edge_list), cudaMemcpyHostToDevice);
  	}*/
   	
   	
   	   	cudaMemcpy(added_device, added, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);
   	cudaMemcpy(cluster_listd, cluster_list, no_node*sizeof(cluster), cudaMemcpyHostToDevice);
   	cudaMemcpy(flagd,&KCORE, sizeof(int), cudaMemcpyHostToDevice);
    //start_time = time(NULL);
   	//adj_listd,
   	printf("syncing\n");
   	cudaMemcpy(cluster_track_vertexd,cluster_track_vertex,no_node*no_node*sizeof(int),cudaMemcpyHostToDevice);
   	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

   	find_neighbour <<< 1,no_node >>> (cluster_listd,cluster_track_vertexd,adj_listd,added_device,no_node,flagd);//call to cuda kernel for detecting neighbours of vertices which have degree >=KCORE
    cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
     time+=time1;
   	cudaMemcpy(cluster_track_vertex,cluster_track_vertexd,no_node*no_node*sizeof(int),cudaMemcpyDeviceToHost);
      	   	
   	
   	//cudaMemcpy(&KCORE, flagd, sizeof(int), cudaMemcpyDeviceToHost);
   	for(i=0;i<no_node;i++)
  		cluster_list[i].tag=0;
    
    cudaMemcpy(added, added_device, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(cluster_list,cluster_listd, no_node*sizeof(cluster), cudaMemcpyDeviceToHost);
    /*	printf("Cluster track vertex\n");
   	for(i=0;i<no_node;i++)
   	{
   	
   	     for(j=0;j<no_node && cluster_list[i].tag!=-1 ;j++)
   	        printf("%d\t",cluster_track_vertex[i*no_node+j]);
   	      
   	     printf("\n");   
  		//cluster_list[i].tag=0;
    
   	}
    printf("Cluster\n");
    for(i=0;i<no_node;i++)
    {
    		printf("cluster:%d\n",i+1);
    		if(cluster_list[i].tag!=-1)
    		{
    				int k=cluster_list[i].head;
    				for(int l=k;l<(k+no_node);l++)
    				{
    						printf("%d\t",adj_list[l].vert);
    				
    				}
    				printf("\n");
    			
    		}
    
    }
    printf("\n\n");*/
  /* 	for(i=0;i<no_node;i++)
  		adj_list[i*no_node].count=0;*/
  		
 
   	 cudaMemcpy(adj_list, adj_listd, sizeof(edge_list)*no_node*no_node, cudaMemcpyDeviceToHost);
   	 /*for(i=0;i<no_node;i++){
    	for(j=0;j<no_node;j++){
    	
    		  added[no_node*i+j]=0;	
    	
    	
    	}
    
    
    }*/
	 *exapnd=1;
	 	 	cudaMemcpy(expand_d, exapnd, 1*sizeof(int), cudaMemcpyHostToDevice);
	 while (*exapnd==1){

	 	*leave=1;
	 	for(i=0;i<no_node;i++)
	 	{
	 	
	 		stay_list[i]=0;
	 		join_list[i]=0;
	 	}

	 		 	cudaMemcpy(leavd, leave, 1*sizeof(int), cudaMemcpyHostToDevice);
	 	while (*leave==1){
	 	
	 		*leave=0;
	 		
	 	cudaMemcpy(leavd, leave, 1*sizeof(int), cudaMemcpyHostToDevice);
	 	cudaMemcpy(added,added_device,sizeof(int)*no_node*no_node,cudaMemcpyDeviceToHost);
	 
    //cudaMemcpy(adj_list,adj_listd, size, cudaMemcpyDeviceToHost);
    /*for(i=0;i<no_node;i++){
    	printf("tag=%d\n",cluster_list[i].tag);
    	printf("count=%d\n",adj_list[i].count);
    	
    	   
   // printf("flag=%d\n",*flagd);
    	//printf("tag=%d\n",adj_list[i]->count);
    }*/	
    
    /*printf("Added\n");
    for(i=0;i<no_node;i++){
    	for(j=0;j<no_node;j++){
    	
    		printf("%d\t",added[no_node*i+j]);	
    	
    	
    	}
    	printf("\n");
    
    }*/
	/*graph = (CGRAPH *)malloc(no_node *sizeof(CGRAPH));
	temp2 = (int *)malloc(no_node * sizeof(int));

	sprintf(syscmd, "%s.uniq", argv[1]);
	fp = fopen(syscmd,"r");*/
    printf("detecting duplicate community\n");
    cudaMemcpy(cluster_track_vertexd,cluster_track_vertex,no_node*no_node*sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(cluster_listd, cluster_list, no_node*sizeof(cluster), cudaMemcpyHostToDevice);
    near_duplicate(cluster_list,no_node,OVL,cluster_track_vertex);//host function call to detect and delete near duplicate clusters
    cudaMemcpy(cluster_track_vertex, cluster_track_vertexd, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost); 
    
    cudaMemcpy(adj_listd, adj_list, no_node*no_node*sizeof(edge_list), cudaMemcpyHostToDevice);
   
    for(i=0;i<no_node;i++){
    	for(j=0;j<no_node;j++){
    	
    		c_neigh_list[no_node*i+j]=0;	
    	
    	
    	}
  
    
    }
    cudaMalloc(&c_neigh_listd,no_node*no_node*sizeof(int));
    cudaMemcpy(c_neigh_listd, c_neigh_list, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);
    //compute_c_score<<<1,no_node>>>(cluster_listd,c_score_listd,no_node);
   // cudaMemcpy(c_score_listd, c_score_list, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost);
    cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

    count_cluster <<< 1,no_node >>> (c_neigh_listd,adj_listd,cluster_listd,no_node);//call to cuda kernel to find the list of clusters to 		which a node belongs..c_neigh_list is a list which stores the list of clusters a node belongs to.
    cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
     time+=time1;

   // count_cluster(1,c_neigh_list,adj_list,cluster_list,no_node);
    cudaMemcpy(c_neigh_list, c_neigh_listd, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost);
    
    comm_conn_score=(int*)malloc(no_node*no_node*sizeof(int));
    neigh_conn_score=(int*)malloc(no_node*no_node*sizeof(int));
    
    cudaMalloc(&comm_conn_scored,no_node*no_node*sizeof(int));
    cudaMalloc(&neigh_conn_scored,no_node*no_node*sizeof(int));
    cudaMemcpy(comm_conn_scored, comm_conn_score, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(neigh_conn_scored, neigh_conn_score, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);
    cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

    score<<<1,no_node>>>(comm_conn_scored,neigh_conn_scored,c_neigh_listd,adj_listd,cluster_listd,no_node,KCORE);//call to cuda kernel to 		compute connectedness scores
    cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
    time+=time1;
 	printf ("Time for the kernel, parallel shared: %f ms\n", time);
    cudaMemcpy(comm_conn_score, comm_conn_scored, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(neigh_conn_score, neigh_conn_scored, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost);
    for(i=0;i<no_node;i++){
      comm_conn_score[i]=0;
      neigh_conn_score[i]=0;
    }
    //for(i=0;i<no_node;i++)
    	//score(comm_conn_score,neigh_conn_score,c_neigh_list,adj_list,cluster_list,no_node,KCORE,i);
    /*for(i=0;i<no_node;i++){
    	for(j=0;j<no_node;j++){
    	
    		printf("%d\t",c_neigh_list[i*no_node+j]);	
    	
    	
    	}
    	printf("\n");
    
    }*/
  /*  printf("scores\n");
   
    for(i=0;i<no_node;i++){
    	for(j=0;j<no_node && cluster_list[i].tag!=-1;j++){
    	
    		printf("cluster : %d, Vertex : %d :: %d %d,%d,clu_size:%d\n",i+1,j+1,comm_conn_score[i*no_node+j],neigh_conn_score[i*no_node+j],adj_list[j*no_node].count,cluster_list[i].size);	
    	
    	
    	}
    	printf("\n");
    
    }*/
  /*  printf("tag\n");
 	for(i=0;i<no_node;i++){
 		printf("%d ",cluster_list[i].tag);
 	}
 	printf("\n");*/
     cudaMemcpy(cluster_listd, cluster_list, no_node*sizeof(cluster), cudaMemcpyHostToDevice);
     cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

	bucket_fill<<<1,no_node>>>(cluster_listd,comm_conn_scored,comm_vert_bucketd,no_node,bucket_count);//to compute score distribution 		using community connectedness scores
	bucket_fill<<<1,no_node>>>(cluster_listd,neigh_conn_scored,neigh_vert_bucketd,no_node,bucket_count);//to compute score distribution 	using neighbourhood connectedness scores
   
     cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
     time+=time1;
      printf ("Time for the kernel, parallel shared: %f ms\n", time);
	 cudaMemcpy(comm_vert_bucket, comm_vert_bucketd, bucket_count*no_node*sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(neigh_vert_bucket, neigh_vert_bucketd, bucket_count*no_node*sizeof(int), cudaMemcpyDeviceToHost);
/*	for(i=0;i<bucket_count*no_node;i++)
	{
	       if(comm_vert_bucket[i]!=0)   
			printf("i:%d,bucket count : %d,%d\t",i,comm_vert_bucket[i],neigh_vert_bucket[i]);
			
		    if(i!=0 && i%bucket_count==0)
			   printf("\n");
	}*/
	//cudaMemcpy(comm_vert_bucketd,comm_vert_bucket,sizeof(int)*no_node*bucket_count,cudaMemcpyHostToDevice);
	cudaMemcpy(stay_listd,stay_list,no_node*sizeof(int), cudaMemcpyHostToDevice);
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

	compute_stay_cut_off<<<1,no_node>>>(stay_listd,comm_vert_bucketd,no_node,bucket_count);//cuda kernel to compute  stay cut-off
    cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
     time+=time1;

	cudaMemcpy(stay_list, stay_listd, no_node*sizeof(int), cudaMemcpyDeviceToHost);
	
	cudaMemcpy(join_listd,join_list,no_node*sizeof(int), cudaMemcpyHostToDevice);
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

	compute_stay_cut_off<<<1,no_node>>>(join_listd,neigh_vert_bucketd,no_node,bucket_count);//cuda kernel to compute  join cut-off
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
     time+=time1;

	cudaMemcpy(join_list, join_listd, no_node*sizeof(int), cudaMemcpyDeviceToHost); 
	/*printf("\nstay\n");
	for(i=0;i<no_node;i++)
		printf("%d ",join_list[i]);
     	    printf("l=%d \n",*leave);	*/
     	    
    cudaMemcpy(leavd, leave, 1*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(cluster_listd, cluster_list, no_node*sizeof(int), cudaMemcpyHostToDevice); 
	cudaMemcpy(cluster_track_vertexd, cluster_track_vertex, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);  	    
	cudaMemcpy(comm_conn_scored, comm_conn_score, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(neigh_conn_scored, neigh_conn_score, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice);
    cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

	leave_phase<<<1,no_node>>>(stay_listd,cluster_listd,cluster_track_vertexd,comm_conn_scored,no_node,added_device,KCORE,leavd);//call to cuda kernel to delete communities
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
    time+=time1;
	cudaMemcpy(leave, leavd, 1*sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(cluster_list, cluster_listd, no_node*sizeof(int), cudaMemcpyDeviceToHost); 
	cudaMemcpy(cluster_track_vertex, cluster_track_vertexd, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost); 
	 printf("Cluster\n");
    for(i=0;i<no_node;i++)
    {
    		//printf("cluster:%d,%d\n",i+1,cluster_list[i].size);
    		if(cluster_list[i].tag!=-1)
    		{
    		        count=0;
    				
    				for(j=0;j<no_node;j++)
    				{
    				  //printf("%d\t",cluster_track_vertex[i*no_node+j]);
    				  if(cluster_track_vertex[i*no_node+j]>0)
    				    count++; 
    				}  
    				if(count<=KCORE)
    				{
    				   cluster_list[i].tag=-1;
    				   cluster_list[i].size=count;
    				   
    				   continue;  
    				}   
    				/*printf("Added\n");
    				for(j=0;j<no_node;j++)
    				{
    				
    				if(added[i*no_node+j]!=-1)
    				  printf("%d\t",added[i*no_node+j]);
    				  
    				}  
    				printf("\n");  */
    			
    		}
    
    }
    //printf("l=%d \n",*leave);
    //exit(0);
    }
    
    *exapnd=0;
    
    cudaMemcpy(now_added_d, now_added, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice); 	
    cudaMemcpy(expand_d,exapnd,sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(added_device, added, no_node*no_node*sizeof(int), cudaMemcpyHostToDevice); 
    cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	//call to cuda kernel to expand communities
    expand_phase<<<1,no_node>>>(join_listd,cluster_listd,cluster_track_vertexd,neigh_conn_scored,no_node,added_device,now_added_d,adj_list,KCORE,expand_d,bucket_count-1);
   	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time1, start, stop);
     time+=time1;
      printf ("Time for the kernel, parallel shared: %f ms\n", time);
	cudaMemcpy(added, now_added_d, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost); 
	/*for(i=0;i<no_node;i++){
		for(j=0;j<no_node;j++){
		    if(added[j]!=-1)
				printf("i:%d j:%d ",i,added[j]);
		}
		printf("\n");
	}*/
	cudaMemcpy(cluster_track_vertex, cluster_track_vertexd, no_node*no_node*sizeof(int), cudaMemcpyDeviceToHost); 
//	cudaMemcpy(leave,leavd,sizeof(int),cudaMemcpyDeviceToHost);
	cudaMemcpy(exapnd,expand_d,sizeof(int),cudaMemcpyDeviceToHost);
	printf("%d %d\n",*leave,*exapnd);
	
	}
	
	 printf("\n\nCluster\n");
    for(i=0;i<no_node;i++)
    {
         if(cluster_list[i].tag!=-1)
         {
           
    		printf("cluster:%d,%d\n",i+1,cluster_list[i].tag);
    		for(j=0;j<no_node;j++)
    				{
    				  //printf("%d\t",cluster_track_vertex[i*no_node+j]);
    				  if(cluster_track_vertex[i*no_node+j]>0)
    				       printf("%d\t",j+1); 
    				}  
    				
    				printf("\n");		
          }
          
    }
 printf ("Time for the kernel, parallel shared: %f ms\n", time);
	cudaFree(cluster_track_vertexd);
	cudaFree(cluster_listd);
	cudaFree(join_listd);
    cudaFree(stay_listd);
    cudaFree(comm_vert_bucketd);
    cudaFree(neigh_vert_bucketd);
    cudaFree(adj_listd);
	return 0;

}
