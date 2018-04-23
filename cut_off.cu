/*common kernel for stay and join cut-off..vertex-wise parallel computation*/
__global__ void compute_stay_cut_off(int*stay,int*bucket,int no_node,int maxi){

	int x=threadIdx.x*maxi;
	int i,f,temp=0;
	
	
	for(i=x+maxi-1;i>=x;i--){
		if(bucket[i]>0)
			break;
	}
	
	f=i;
	
	for(i=f-1;i>=x;i--){
		if(bucket[i]<=bucket[f]){
			temp=i;
			break;
		}
	}
	
	for(i=temp-1;i>=x;i--){
		if(bucket[i]>=bucket[temp]){
			stay[threadIdx.x]=(maxi-1-(temp-x))*5;//bucket[temp*no_node];
			//maxi*(threadIdx.x+1)-(
			break;
		}
		
	}
	
	return;
}
	
	
	
	

