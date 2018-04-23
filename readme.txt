1.Input format:
The input file is in form an unweighted edgelist. Each line contains 2 numbers (node labels) separated by a tab space, representing an edge. Please check file example_dolph as an example to input file.
2.KCORE (i.e. minimum degree for consideration as initialization of clusters.
3.OVL parameter should be supplied by user.
Step1.
Compile using
gcc -o main main_new.cu
step2.
run using
./main <input filename> [(optional) <KCORE> <OVL>]
by default KCORE is 3 and OVL 0.6
Output
Each line represents a community with node labels separated by tab spaces.


